// Import các thư viện cần thiết
require('dotenv').config();
const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs-extra');
const path = require('path');
const { MailerSend, EmailParams, Sender, Recipient } = require('mailersend');
const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');

// ─── MailerSend Setup ─────────────────────────────────────────────────────────
const mailerSend = new MailerSend({
  apiKey: process.env.MAILERSEND_API_KEY,
});

// ─── Supabase Admin Client ────────────────────────────────────────────────────
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

// ─── OTP Store (in-memory) ────────────────────────────────────────────────────
// Map: email -> { otp, expiresAt, verified, resetToken }
const otpStore = new Map();

// Cấu hình multer để lưu file tạm
const upload = multer({
  dest: 'uploads/',
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
});

// Đảm bảo thư mục uploads tồn tại
fs.ensureDirSync('uploads');

// Kiểm tra API Key
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
if (!GEMINI_API_KEY || GEMINI_API_KEY === 'YOUR_API_KEY_PLACEHOLDER') {
  console.error('Gemini API Key không được tìm thấy hoặc chưa được cấu hình trong biến môi trường!');
}

let genAI;
let model;
let visionModel;
let embedModel;
try {
  genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  visionModel = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  // Embedding model for RAG retrieval (default dimension expected 768)
  const embeddingModelName = process.env.GEMINI_EMBEDDING_MODEL || 'gemini-embedding-2-preview'; // 3072 dim – khớp với migration 0005
  embedModel = genAI.getGenerativeModel({ model: embeddingModelName });
} catch (error) {
  console.error('Lỗi khởi tạo Gemini (kiểm tra API Key?):', error);
}

// Định nghĩa System Prompt - Tối ưu Token với RAG & JSON format
const systemPrompt =
  `Bạn là trợ lý AI chuyên nghiệp của Hệ thống quản lý đặt sân cầu lông 'KLOO'.
Nhiệm vụ của bạn là giải đáp các thắc mắc về hệ thống đặt sân, nội quy, chính sách hoàn tiền, giá cả sân bãi và các câu hỏi thường gặp.
ĐẶC BIỆT LƯU Ý: 
1. CHÍNH SÁCH HỦY SÂN MỚI (ƯU TIÊN TUYỆT ĐỐI GHI ĐÈ KẾT QUẢ TỪ NGUỒN): 
   - Hủy trước 2 tiếng so với giờ chơi: Hoàn tiền 100% vào Số Dư Ví.
   - Hủy trong vòng 2 tiếng trước giờ chơi: Hoàn tiền 50% vào Số Dư Ví.
   - Đã tới hoặc quá giờ chơi: Cấm hủy, KHÔNG hoàn tiền.
2. Chỉ dựa vào kiến thức cung cấp trong phần SOURCES để trả lời các nội quy, giá cả khác. Tuyệt đối KHÔNG tự bịa ra thông tin.
3. Ứng dụng chuyên môn về môn CẦU LÔNG. Từ chối trả lời lịch sự nếu câu hỏi hoàn toàn nằm ngoài nghiệp vụ thể thao hoặc đặt sân.
4. KHÔNG sử dụng Markdown (như *, **, #) trong nội dung answer. Nội dung phải là dạng text thuần (plain text).
4. Tự động nhận diện Action mà người dùng có ý định muốn thực hiện:
 - "search_courts": Khi user muốn tìm sân, xem danh sách sân, đặt lịch.
 - "view_schedule": Khi user muốn xem lịch hẹn trình, quản lý lịch đã đặt của tôi.
 - "cancel_booking": Khi user muốn hủy lịch đã đặt.
 - "view_expense": Khi user muốn xem số dư, nạp ví, chi tiêu.
 - "none": Hỏi đáp thông thường.`;

// Khởi tạo Express app
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Hàm helper để xóa file tạm
const cleanupFile = (filePath) => {
  if (filePath && fs.existsSync(filePath)) {
    fs.unlink(filePath).catch(err => console.error('Lỗi xóa file:', err));
  }
};

// Hàm helper để loại bỏ markdown formatting (dấu *)
const removeMarkdown = (text) => {
  if (!text || typeof text !== 'string') return text;

  // Loại bỏ các dấu markdown phổ biến
  return text
    .replace(/\*\*/g, '') // Loại bỏ ** (bold)
    .replace(/\*/g, '')   // Loại bỏ * (italic hoặc list)
    .replace(/#{1,6}\s/g, '') // Loại bỏ # (headings)
    .replace(/`/g, '')    // Loại bỏ ` (code)
    .replace(/~~/g, '')   // Loại bỏ ~~ (strikethrough)
    .replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1') // Chuyển [text](url) thành text
    .trim();
};

// Hàm RAG: Lấy ngữ cảnh người dùng từ Supabase để tiết kiệm token
async function getUserContext(userId) {
  if (!userId || !supabaseAdmin) return '';
  
  try {
    const now = new Date().toISOString();
    
    // Lấy 2 lịch đặt sắp tới
    const { data: bookings } = await supabaseAdmin
      .from('bookings')
      .select('booking_date, time_slot, court_name, status')
      .eq('user_id', userId)
      .gte('booking_date', now.split('T')[0])
      .order('booking_date', { ascending: true })
      .limit(2);
    
    let context = 'USER_CONTEXT:\n';
    if (!bookings || bookings.length === 0) {
      context += '- Lịch đặt sắp tới: Không có\n';
    } else {
      context += '- Lịch đặt sắp tới: ';
      bookings.forEach(b => {
        context += `${b.booking_date} lúc ${b.time_slot}h tại ${b.court_name} (${b.status}). `;
      });
      context += '\n';
    }
    
    return context;
  } catch (e) {
    console.error('RAG Error:', e);
    return '';
  }
}

async function embedText(text) {
  if (!embedModel) throw new Error('Embedding model chưa sẵn sàng.');
  // outputDimensionality: 1536 – khớp với vector(1536) trong Supabase
  const res = await embedModel.embedContent({
    content: { parts: [{ text }], role: 'user' },
    outputDimensionality: 1536,
  });
  const v =
    res?.embedding?.values ||
    res?.embedding?.value ||
    res?.embedding ||
    res?.data?.[0]?.embedding;
  if (!Array.isArray(v)) {
    throw new Error('Embedding API trả về dữ liệu không hợp lệ.');
  }
  return v;
}

async function retrieveKnowledge({ userPrompt, tags }) {
  if (!supabaseAdmin) return [];
  try {
    const queryEmbedding = await embedText(userPrompt);
    const { data, error } = await supabaseAdmin.rpc('match_kb_chunks', {
      query_embedding: queryEmbedding,
      match_count: 6,
      filter_tags: tags && tags.length ? tags : null,
    });
    if (error) {
      console.error('RAG retrieve error:', error);
      return [];
    }
    return Array.isArray(data) ? data : [];
  } catch (e) {
    console.error('RAG retrieve exception:', e);
    return [];
  }
}

function buildSourcesBlock(rows) {
  if (!rows || rows.length === 0) return '';
  const lines = rows.map((r, idx) => {
    const source = r.source || r.title || 'KB';
    const id = `S${idx + 1}`;
    return `${id} | ${source} | ${String(r.content || '').replace(/\s+/g, ' ').trim()}`;
  });
  return `SOURCES:\n${lines.join('\n')}\n`;
}

function safeJsonParse(text) {
  if (!text || typeof text !== 'string') return null;
  try {
    return JSON.parse(text);
  } catch (_) {
    // try to extract JSON from a larger text blob
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        return JSON.parse(text.slice(start, end + 1));
      } catch (_) {}
    }
    return null;
  }
}

function normalizeAction(action) {
  const a = action && typeof action === 'object' ? action : {};
  const type = typeof a.type === 'string' ? a.type : 'none';
  const allowed = new Set([
    'search_courts',
    'view_schedule',
    'view_expense',
    'cancel_booking',
    'none',
  ]);
  if (!allowed.has(type)) return { type: 'none' };
  const out = { type };
  if (type === 'search_courts' && typeof a.sport === 'string') out.sport = a.sport;
  return out;
}

// Định nghĩa Endpoint '/ask' - xử lý cả text và ảnh với RAG
app.post('/ask', upload.single('image'), async (req, res) => {
  const imageFile = req.file;
  const userId = req.body.user_id || '';
  const userPrompt = req.body.prompt || (imageFile ? 'Phân tích ảnh này và trả lời câu hỏi liên quan đến ứng dụng đặt sân cầu lông.' : '');

  // Lấy ngữ cảnh người dùng qua RAG
  const userContext = await getUserContext(userId);
  const kbRows = await retrieveKnowledge({ userPrompt, tags: null });
  const sourcesBlock = buildSourcesBlock(kbRows);

  const fullPrompt =
    `${systemPrompt}\n\n` +
    `Bạn PHẢI trả về JSON hợp lệ theo schema sau (KHÔNG thêm text ngoài JSON):\n` +
    `{\n` +
    `  "answer": "string (plain text, không markdown)",\n` +
    `  "action": { "type": "search_courts|view_schedule|view_expense|cancel_booking|none", "sport": "badminton|football|tennis|pickleball (optional)" },\n` +
    `  "used_sources": ["S1","S2"]\n` +
    `}\n\n` +
    `${sourcesBlock}\n` +
    `${userContext}\n\n` +
    `USER_ASK: ${userPrompt}`;

  // Nếu có ảnh, xử lý với Vision API
  if (imageFile) {
    const userPromptImg = req.body.prompt || 'Phân tích ảnh này và trả lời câu hỏi liên quan đến ứng dụng đặt sân cầu lông.';

    if (!visionModel) {
      cleanupFile(imageFile.path);
      return res.status(500).json({ error: 'Lỗi khởi tạo AI vision model.' });
    }

    try {
      // Đọc file ảnh
      const imageData = await fs.readFile(imageFile.path);
      const base64Image = imageData.toString('base64');
      const mimeType = imageFile.mimetype || 'image/jpeg';

      // Gửi ảnh và prompt lên Gemini Vision với RAG
      const result = await visionModel.generateContent([
        {
          text: `${systemPrompt}\n\n${userContext}\n\nUSER_ASK: ${userPromptImg}`,
        },
        {
          inlineData: {
            data: base64Image,
            mimeType: mimeType,
          },
        },
      ]);

      const response = result.response;
      if (!response) {
        cleanupFile(imageFile.path);
        return res.json({
          answer: 'Xin lỗi bạn, mình chưa thể phân tích được ảnh này ạ. Bạn có thể gửi lại hoặc hỏi mình bằng tin nhắn nhé!',
          action: { type: 'none' },
          citations: []
        });
      }

      let text = response.text();
      cleanupFile(imageFile.path);

      if (!text || text.trim().length === 0) {
        return res.json({
          answer: 'Xin lỗi bạn, mình không thể tạo câu trả lời từ ảnh này ạ. Bạn hãy thử gửi ảnh khác hoặc hỏi mình bằng văn bản nhé!',
          action: { type: 'none' },
          citations: []
        });
      }

      // Loại bỏ markdown formatting
      text = removeMarkdown(text);

      // Vision path: best-effort JSON parse, but allow legacy plain text.
      const parsed = safeJsonParse(text);
      if (parsed && typeof parsed.answer === 'string') {
        return res.json({
          answer: removeMarkdown(parsed.answer),
          action: normalizeAction(parsed.action),
          citations: (kbRows || []).map((r, idx) => ({
            id: `S${idx + 1}`,
            document_id: r.document_id,
            chunk_id: r.chunk_id,
            title: r.title,
            source: r.source,
            url: r.url,
            excerpt: r.content?.slice(0, 240) || '',
            similarity: r.similarity,
          })),
        });
      }

      res.json({ answer: text, action: { type: 'none' }, citations: [] });
      return;
    } catch (error) {
      cleanupFile(imageFile.path);
      // Trả lời lịch sự thay vì báo lỗi — ảnh có thể không liên quan hoặc bị Gemini reject
      res.json({
        answer: 'Xin lỗi bạn, mình không thể xử lý hình ảnh này ạ. Hình ảnh có vẻ không liên quan đến thể thao hoặc đặt sân cầu lông. Bạn có thể gửi ảnh sân bãi, dụng cụ thể thao hoặc hỏi mình bằng tin nhắn nhé!',
        action: { type: 'none' },
        citations: []
      });
      return;
    }
  }

  // Nếu không có ảnh, xử lý text thông thường
  if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim().length === 0) {
    return res.status(400).json({ error: 'Câu hỏi (prompt) không hợp lệ.' });
  }

  if (!model) {
    console.error('Gemini model chưa sẵn sàng (lỗi khởi tạo?).');
    return res.status(500).json({ error: 'Lỗi khởi tạo AI model.' });
  }

  try {
    const chat = model.startChat({
      generationConfig: {
        maxOutputTokens: 300,
      },
    });

    const result = await chat.sendMessage(fullPrompt);
    const response = result.response;

    if (!response) {
      console.error('Gemini API không trả về response hợp lệ.', { userPrompt });
      return res.status(500).json({ error: 'AI không thể tạo câu trả lời (response null).' });
    }

    let text = response.text();
    if (!text || text.trim().length === 0) {
      console.warn('Gemini không trả về nội dung text.', { response });
      return res.status(500).json({ error: 'AI không thể tạo câu trả lời (text rỗng).' });
    }

    // Loại bỏ markdown formatting
    text = removeMarkdown(text);

    const parsed = safeJsonParse(text);
    if (parsed && typeof parsed.answer === 'string') {
      const used = Array.isArray(parsed.used_sources) ? parsed.used_sources : [];
      const citations = (kbRows || []).map((r, idx) => ({
        id: `S${idx + 1}`,
        document_id: r.document_id,
        chunk_id: r.chunk_id,
        title: r.title,
        source: r.source,
        url: r.url,
        excerpt: r.content?.slice(0, 240) || '',
        similarity: r.similarity,
      }));

      return res.json({
        answer: removeMarkdown(parsed.answer),
        action: normalizeAction(parsed.action),
        used_sources: used,
        citations,
      });
    }

    // Backward compatible response
    res.json({ answer: text, action: { type: 'none' }, citations: [] });
  } catch (error) {
    console.error('Lỗi khi gọi Gemini API:', error);
    res.status(500).json({ error: 'Đã xảy ra lỗi khi kết nối với AI.' });
  }
});

// ─── FORGOT PASSWORD ENDPOINTS ────────────────────────────────────────────────

/**
 * POST /forgot-password
 * Body: { email: string }
 */
app.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email || typeof email !== 'string' || !email.includes('@')) {
    return res.status(400).json({ error: 'Email không hợp lệ.' });
  }

  const normalizedEmail = email.toLowerCase().trim();

  // Kiểm tra email có tồn tại trong Supabase không
  const { data: users, error: fetchError } = await supabaseAdmin.auth.admin.listUsers();
  if (fetchError) {
    return res.status(500).json({ error: 'Lỗi kết nối server.' });
  }
  const userExists = users.users.some(u => u.email?.toLowerCase() === normalizedEmail);
  if (!userExists) {
    // Trả về success giả để tránh email enumeration attack
    return res.json({ message: 'Nếu email tồn tại, bạn sẽ nhận được mã OTP.' });
  }

  // Tạo OTP 6 số ngẫu nhiên
  const otp = crypto.randomInt(100000, 999999).toString();
  const expiresAt = Date.now() + 10 * 60 * 1000; // 10 phút

  otpStore.set(normalizedEmail, { otp, expiresAt, verified: false, resetToken: null });

  // Template email HTML
  const htmlContent = `
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#f4f4f4;font-family:'Helvetica Neue',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 0;">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:linear-gradient(135deg,#FF6B00,#FFB347);padding:36px;text-align:center;">
            <div style="font-size:32px;font-weight:800;color:#ffffff;letter-spacing:-1px;">🏸 KLOO</div>
            <div style="color:rgba(255,255,255,0.85);font-size:14px;margin-top:6px;">Đặt sân thể thao dễ dàng</div>
          </td>
        </tr>
        <tr>
          <td style="padding:40px 36px;">
            <h2 style="margin:0 0 12px;font-size:22px;color:#1A1A1A;">Quên mật khẩu?</h2>
            <p style="margin:0 0 28px;font-size:15px;color:#555;line-height:1.6;">
              Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn.
              Sử dụng mã OTP dưới đây để tiếp tục:
            </p>
            <div style="background:#FFF5F0;border:2px dashed #FF6B00;border-radius:12px;padding:24px;text-align:center;margin-bottom:28px;">
              <div style="font-size:11px;font-weight:600;color:#FF6B00;letter-spacing:2px;text-transform:uppercase;margin-bottom:8px;">Mã xác thực của bạn</div>
              <div style="font-size:42px;font-weight:800;color:#FF6B00;letter-spacing:12px;">${otp}</div>
              <div style="font-size:12px;color:#999;margin-top:8px;">Mã có hiệu lực trong <strong>10 phút</strong></div>
            </div>
            <p style="margin:0;font-size:13px;color:#999;line-height:1.6;">
              Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.
            </p>
          </td>
        </tr>
        <tr>
          <td style="background:#FAFAFA;padding:20px 36px;text-align:center;border-top:1px solid #EEEEEE;">
            <p style="margin:0;font-size:12px;color:#BBBBBB;">© 2025 KLOO App. All rights reserved.</p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;

  try {
    const sentFrom = new Sender(process.env.MAILERSEND_FROM_EMAIL, 'KLOO App');
    const recipients = [new Recipient(normalizedEmail)];
    const emailParams = new EmailParams()
      .setFrom(sentFrom)
      .setTo(recipients)
      .setSubject(`[KLOO] Mã OTP đặt lại mật khẩu: ${otp}`)
      .setHtml(htmlContent);

    await mailerSend.email.send(emailParams);
    res.json({ message: 'Mã OTP đã được gửi đến email của bạn.' });
  } catch (err) {
    console.error('MailerSend error:', JSON.stringify(err?.body || err));
    res.status(500).json({ error: 'Không thể gửi email. Vui lòng thử lại.' });
  }
});

/**
 * POST /verify-otp
 * Body: { email: string, otp: string }
 */
app.post('/verify-otp', (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    return res.status(400).json({ error: 'Thiếu email hoặc mã OTP.' });
  }

  const normalizedEmail = email.toLowerCase().trim();
  const record = otpStore.get(normalizedEmail);

  if (!record) {
    return res.status(400).json({ error: 'Không tìm thấy yêu cầu OTP. Vui lòng gửi lại.' });
  }
  if (Date.now() > record.expiresAt) {
    otpStore.delete(normalizedEmail);
    return res.status(400).json({ error: 'Mã OTP đã hết hạn. Vui lòng gửi lại.' });
  }
  if (record.otp !== otp.trim()) {
    return res.status(400).json({ error: 'Mã OTP không đúng. Vui lòng thử lại.' });
  }

  // Tạo resetToken ngắn hạn 15 phút
  const resetToken = crypto.randomBytes(32).toString('hex');
  record.verified = true;
  record.resetToken = resetToken;
  record.resetTokenExpiresAt = Date.now() + 15 * 60 * 1000;
  otpStore.set(normalizedEmail, record);

  res.json({ message: 'Xác thực OTP thành công.', resetToken });
});

/**
 * POST /reset-password
 * Body: { email: string, resetToken: string, newPassword: string }
 */
app.post('/reset-password', async (req, res) => {
  const { email, resetToken, newPassword } = req.body;
  if (!email || !resetToken || !newPassword) {
    return res.status(400).json({ error: 'Dữ liệu không đầy đủ.' });
  }
  if (newPassword.length < 6) {
    return res.status(400).json({ error: 'Mật khẩu phải có ít nhất 6 ký tự.' });
  }

  const normalizedEmail = email.toLowerCase().trim();
  const record = otpStore.get(normalizedEmail);

  if (!record || !record.verified) {
    return res.status(400).json({ error: 'Phiên đặt lại mật khẩu không hợp lệ.' });
  }
  if (record.resetToken !== resetToken) {
    return res.status(400).json({ error: 'Token không hợp lệ.' });
  }
  if (Date.now() > record.resetTokenExpiresAt) {
    otpStore.delete(normalizedEmail);
    return res.status(400).json({ error: 'Phiên đã hết hạn. Vui lòng bắt đầu lại.' });
  }

  // Tìm user trong Supabase
  const { data: users, error: listError } = await supabaseAdmin.auth.admin.listUsers();
  if (listError) {
    return res.status(500).json({ error: 'Lỗi kết nối server.' });
  }
  const user = users.users.find(u => u.email?.toLowerCase() === normalizedEmail);
  if (!user) {
    return res.status(404).json({ error: 'Không tìm thấy tài khoản.' });
  }

  // Cập nhật password qua Supabase Admin API
  const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
    user.id,
    { password: newPassword }
  );

  if (updateError) {
    console.error('Supabase update error:', updateError);
    return res.status(500).json({ error: 'Không thể cập nhật mật khẩu. Vui lòng thử lại.' });
  }

  otpStore.delete(normalizedEmail);
  res.json({ message: 'Mật khẩu đã được cập nhật thành công.' });
});

// ─────────────────────────────────────────────────────────────────────────────

// Endpoint '/ask/audio' để xử lý audio
app.post('/ask/audio', upload.single('audio'), async (req, res) => {
  const userPrompt = req.body.prompt || '';
  const audioFile = req.file;

  if (!audioFile) {
    return res.status(400).json({ error: 'Không có audio được gửi lên.' });
  }

  cleanupFile(audioFile.path);

  // Tạm thời trả về thông báo
  res.json({
    answer: 'Tính năng xử lý audio đang được phát triển. Vui lòng sử dụng tính năng nhận diện giọng nói để chuyển giọng nói thành text trước.'
  });
});

// Endpoint kiểm tra server hoạt động
app.get('/', (req, res) => {
  res.send('Badminton AI Backend is running!');
});

// Chạy server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server đang chạy tại http://0.0.0.0:${port}`);
});
