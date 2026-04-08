// ============================================================
// KLOO Badminton AI Backend — RAG (Retrieval-Augmented Generation)
// Architecture:
//   User Query → Embed Query → Vector Search (Supabase pgvector)
//               → Augmented Prompt → Gemini → Answer
// ============================================================

require('dotenv').config();
const express    = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const cors       = require('cors');
const multer     = require('multer');
const fs         = require('fs-extra');
const { MailerSend, EmailParams, Sender, Recipient } = require('mailersend');
const { createClient } = require('@supabase/supabase-js');
const crypto     = require('crypto');

// ─── MailerSend ───────────────────────────────────────────────────────────────
const mailerSend = new MailerSend({ apiKey: process.env.MAILERSEND_API_KEY });

// ─── Supabase Admin Client ────────────────────────────────────────────────────
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

// ─── OTP Store (in-memory) ────────────────────────────────────────────────────
const otpStore = new Map();

// ─── Multer File Upload ───────────────────────────────────────────────────────
const upload = multer({
  dest: 'uploads/',
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});
fs.ensureDirSync('uploads');

// ─── Gemini AI Models ─────────────────────────────────────────────────────────
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
if (!GEMINI_API_KEY) {
  console.error('❌ GEMINI_API_KEY chưa được cấu hình!');
}

let genAI, chatModel, visionModel, embeddingModel;
try {
  genAI          = new GoogleGenerativeAI(GEMINI_API_KEY);
  chatModel      = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  visionModel    = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
  // text-embedding-004: Model embedding của Google, 768 chiều
  embeddingModel = genAI.getGenerativeModel({ model: 'text-embedding-004' });
  console.log('✅ Gemini models initialized (chat + vision + embedding)');
} catch (err) {
  console.error('❌ Lỗi khởi tạo Gemini:', err.message);
}

// ─── Utility Helpers ──────────────────────────────────────────────────────────
const cleanupFile = (filePath) => {
  if (filePath && fs.existsSync(filePath)) {
    fs.unlink(filePath).catch(err => console.error('Lỗi xóa file:', err));
  }
};

const removeMarkdown = (text) => {
  if (!text || typeof text !== 'string') return text;
  return text
    .replace(/\*\*/g, '')
    .replace(/\*/g, '')
    .replace(/#{1,6}\s/g, '')
    .replace(/`{1,3}/g, '')
    .replace(/_/g, '')
    .replace(/~~/g, '')
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
};

// ─── RAG: Step 1 — Generate Embedding ────────────────────────────────────────
// Chuyển đoạn text bất kỳ thành vector 768 chiều
async function generateEmbedding(text) {
  if (!embeddingModel) throw new Error('Embedding model chưa sẵn sàng');
  const result = await embeddingModel.embedContent(text);
  return result.embedding.values; // Array<number> length=768
}

// ─── RAG: Step 2 — Retrieve Relevant Knowledge Chunks ────────────────────────
// Tìm kiếm các đoạn kiến thức liên quan nhất bằng cosine similarity
async function retrieveRelevantChunks(queryEmbedding, matchCount = 5, matchThreshold = 0.50) {
  try {
    const { data, error } = await supabaseAdmin.rpc('match_documents', {
      query_embedding: queryEmbedding,
      match_threshold: matchThreshold,
      match_count:     matchCount,
    });
    if (error) {
      console.error('❌ Supabase RPC match_documents error:', error.message);
      return [];
    }
    return data || [];
  } catch (e) {
    console.error('❌ Lỗi retrieveRelevantChunks:', e.message);
    return [];
  }
}

// ─── RAG: Step 3 — Personalized User Context ─────────────────────────────────
// Lấy lịch đặt sân sắp tới của user để cá nhân hóa trả lời
async function getUserContext(userId) {
  if (!userId) return 'Người dùng chưa đăng nhập.';
  try {
    const today = new Date().toISOString().split('T')[0];
    const { data: bookings, error } = await supabaseAdmin
      .from('bookings')
      .select('booking_date, time_slot, court_name, status')
      .eq('user_id', userId)
      .gte('booking_date', today)
      .order('booking_date', { ascending: true })
      .limit(3);

    if (error || !bookings || bookings.length === 0) {
      return 'Lịch đặt sân sắp tới của người dùng: Chưa có lịch nào.';
    }
    const lines = bookings.map(b =>
      `- Ngày ${b.booking_date} lúc ${b.time_slot}h tại sân "${b.court_name}" (${b.status})`
    );
    return 'Lịch đặt sân sắp tới của người dùng:\n' + lines.join('\n');
  } catch (e) {
    console.error('❌ Lỗi getUserContext:', e.message);
    return 'Không thể lấy lịch cá nhân.';
  }
}

// ─── RAG: Step 4 — Build Augmented Prompt ────────────────────────────────────
// Kết hợp: [Role] + [Retrieved Chunks] + [User Context] + [Rules] + [Question]
function buildAugmentedPrompt(retrievedChunks, userContext, userQuestion) {
  // Xây dựng phần kiến thức từ các chunks được truy xuất
  let knowledgeSection = '';
  if (retrievedChunks.length > 0) {
    knowledgeSection = retrievedChunks
      .map((chunk, i) =>
        `[${i + 1}] [${chunk.category}] (Độ liên quan: ${(chunk.similarity * 100).toFixed(0)}%)\n${chunk.content}`
      )
      .join('\n\n');
  } else {
    knowledgeSection = 'Không tìm thấy thông tin liên quan trong cơ sở dữ liệu nội bộ.';
  }

  return `Bạn là trợ lý ảo KLOO - ứng dụng đặt sân thể thao (cầu lông, bóng đá, tennis, pickleball).

[THÔNG TIN ĐƯỢC TRUY XUẤT TỪ CƠ SỞ DỮ LIỆU]
${knowledgeSection}

[LỊCH CÁ NHÂN CỦA NGƯỜI DÙNG]
${userContext}

[NGUYÊN TẮC TRẢ LỜI BẮT BUỘC]
1. Ưu tiên dùng thông tin trong phần THÔNG TIN ĐƯỢC TRUY XUẤT để trả lời chính xác.
2. Nếu câu hỏi KHÔNG liên quan đến sân thể thao, ứng dụng KLOO, đặt sân, sự kiện, hoặc thanh toán, hãy từ chối lịch sự: "Xin lỗi, tôi chỉ hỗ trợ về sân thể thao và dịch vụ của KLOO."
3. Nếu người dùng muốn TÌM SÂN hoặc GỢI Ý SÂN, thêm đúng 1 đoạn mã [ACTION_SEARCH:sport_type] ở cuối câu trả lời. Giá trị sport_type CHỈ được chọn trong: football, badminton, tennis, pickleball.
4. Không được bịa thông tin không có trong ngữ cảnh.
5. Trả lời ngắn gọn, thân thiện, tiếng Việt. KHÔNG dùng markdown, dấu *, **, #, hoặc ký hiệu đặc biệt.

[CÂU HỎI NGƯỜI DÙNG]
${userQuestion}`;
}

// ─── Express App ──────────────────────────────────────────────────────────────
const app  = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Health Check
app.get('/', (req, res) => {
  res.json({
    status: 'running',
    version: '2.0.0-rag',
    mode: 'Retrieval-Augmented Generation (RAG)',
    models: {
      chat:      'gemini-2.5-flash-lite',
      vision:    'gemini-1.5-flash',
      embedding: 'text-embedding-004 (768 dims)',
    },
  });
});

// ─── SEED KNOWLEDGE BASE ──────────────────────────────────────────────────────
// POST /admin/seed-knowledge
// Gọi endpoint này sau khi chạy SQL migration để nạp dữ liệu vào vector DB
app.post('/admin/seed-knowledge', async (req, res) => {
  console.log('\n🌱 ===== BẮT ĐẦU SEED KNOWLEDGE BASE =====');
  const allChunks = [];

  // ── 1. Seed dữ liệu sân từ Supabase ──────────────────────────────────────
  try {
    const { data: courts, error } = await supabaseAdmin.from('courts').select('*').limit(200);
    if (error) throw error;
    if (courts && courts.length > 0) {
      for (const court of courts) {
        const content =
          `Sân thể thao "${court.name}": ` +
          `Loại sân: ${court.sport_type || 'Đa năng'}. ` +
          `Địa chỉ: ${court.address || 'Chưa cập nhật'}. ` +
          `Giá thuê: ${court.price_per_hour ? Number(court.price_per_hour).toLocaleString('vi-VN') + 'đ/giờ' : 'Liên hệ'}. ` +
          `Số sân con: ${court.sub_courts || 1} sân. ` +
          `${court.description ? 'Mô tả: ' + court.description + '. ' : ''}` +
          `Trạng thái: ${court.status === 'active' ? 'Đang hoạt động' : 'Tạm ngưng'}.`;
        allChunks.push({
          content,
          category: 'court_info',
          metadata: { court_id: court.id, name: court.name, sport_type: court.sport_type },
        });
      }
      console.log(`  ✅ Sân: ${courts.length} chunks`);
    }
  } catch (e) {
    console.error('  ❌ Lỗi fetch courts:', e.message);
  }

  // ── 2. Seed dữ liệu sự kiện ───────────────────────────────────────────────
  try {
    const today = new Date().toISOString().split('T')[0];
    const { data: events, error } = await supabaseAdmin
      .from('events')
      .select('*')
      .gte('event_date', today)
      .limit(100);
    if (error) throw error;
    if (events && events.length > 0) {
      for (const ev of events) {
        const slotsLeft = (ev.max_participants || 0) - (ev.current_participants || 0);
        const content =
          `Sự kiện "${ev.name}": ` +
          `Ngày tổ chức: ${ev.event_date}. ` +
          `Phí tham gia: ${ev.registration_fee ? Number(ev.registration_fee).toLocaleString('vi-VN') + 'đ' : 'Miễn phí'}. ` +
          `Chỗ còn lại: ${slotsLeft > 0 ? slotsLeft + ' chỗ' : 'Hết chỗ'}. ` +
          `${ev.description ? 'Mô tả: ' + ev.description + '. ' : ''}` +
          `Trạng thái: ${ev.status || 'Mở đăng ký'}.`;
        allChunks.push({
          content,
          category: 'event_info',
          metadata: { event_id: ev.id, name: ev.name, event_date: ev.event_date },
        });
      }
      console.log(`  ✅ Sự kiện: ${events.length} chunks`);
    }
  } catch (e) {
    console.error('  ❌ Lỗi fetch events:', e.message);
  }

  // ── 3. Static Knowledge (Policies & Guides) ───────────────────────────────
  const staticChunks = [
    {
      content: 'Hướng dẫn đặt sân trên app KLOO: ' +
        'Bước 1: Mở tab "Đặt sân" ở thanh menu dưới. ' +
        'Bước 2: Chọn ngày muốn đặt trên lịch. ' +
        'Bước 3: Chọn sân thể thao phù hợp. ' +
        'Bước 4: Chọn giờ trống và sân con trên biểu đồ thời gian. ' +
        'Bước 5: Thanh toán bằng ví KLOO hoặc chuyển khoản SePay. ' +
        'Bước 6: Nhận xác nhận đặt sân qua thông báo.',
      category: 'app_guide',
      metadata: { topic: 'booking_guide' },
    },
    {
      content: 'Chính sách hủy sân và hoàn tiền KLOO: ' +
        'Hủy trước 24 giờ: Hoàn tiền 100% vào ví KLOO. ' +
        'Hủy từ 12 đến 24 giờ: Hoàn tiền 50%. ' +
        'Hủy dưới 12 giờ: Không hoàn tiền. ' +
        'Cách hủy: Vào Tab "Tài khoản" > "Lịch sử đặt sân" > Chọn booking > Nhấn "Hủy".',
      category: 'app_policy',
      metadata: { topic: 'cancellation_policy' },
    },
    {
      content: 'Hướng dẫn thanh toán và nạp tiền ví KLOO: ' +
        'Ví KLOO là ví điện tử tích hợp để đặt sân nhanh. ' +
        'Cách nạp tiền: Vào Tab "Tài khoản" > "Ví của tôi" > Nhập số tiền > Chuyển khoản qua SePay bằng quét QR. ' +
        'Thanh toán đặt sân: Chọn "Thanh toán ví KLOO" khi xác nhận booking. ' +
        'Lưu ý: Số dư trong ví phải đủ bằng giá sân mới đặt được.',
      category: 'app_guide',
      metadata: { topic: 'payment_guide' },
    },
    {
      content: 'Hướng dẫn đăng ký sự kiện thể thao KLOO: ' +
        'Bước 1: Mở tab "Sự kiện" hoặc hỏi chatbot về sự kiện đang diễn ra. ' +
        'Bước 2: Chọn sự kiện > Xem chi tiết > Nhấn "Đăng ký tham gia". ' +
        'Bước 3: Xác nhận thanh toán phí đăng ký (nếu có) từ ví KLOO. ' +
        'Bước 4: Thông tin sự kiện xuất hiện trong lịch cá nhân.',
      category: 'app_guide',
      metadata: { topic: 'event_guide' },
    },
    {
      content: 'Hướng dẫn sử dụng bản đồ tìm sân gần đây KLOO: ' +
        'Tab "Bản đồ" hiển thị tất cả sân thể thao xung quanh vị trí hiện tại. ' +
        'Nhấn vào biểu tượng sân trên bản đồ để xem thông tin nhanh. ' +
        'Nhấn "Đặt sân" để tiến hành đặt. ' +
        'Có thể lọc theo loại sân: cầu lông, bóng đá, tennis, pickleball. ' +
        'Danh sách sân gần đây sắp xếp theo khoảng cách từ vị trí người dùng.',
      category: 'app_guide',
      metadata: { topic: 'map_guide' },
    },
    {
      content: 'KLOO hỗ trợ 4 loại sân thể thao: Cầu lông (badminton), Bóng đá (football), Tennis, Pickleball. ' +
        'Mỗi loại sân có giá và số sân con khác nhau tùy địa điểm. ' +
        'Người dùng có thể tìm sân theo loại, vị trí, hoặc tên sân.',
      category: 'app_guide',
      metadata: { topic: 'sport_types' },
    },
    {
      content: 'Câu hỏi thường gặp (FAQ) về KLOO: ' +
        'Q: Quên mật khẩu? A: Nhấn "Quên mật khẩu" ở màn hình đăng nhập, nhập email, nhận mã OTP, đặt lại mật khẩu. ' +
        'Q: Đặt được bao nhiêu sân cùng lúc? A: Có thể chọn nhiều sân con liền kề, gom vào 1 giao dịch. ' +
        'Q: Sân hỏng thì sao? A: Hủy booking theo chính sách hoàn tiền và liên hệ chủ sân. ' +
        'Q: Có thể kết bạn trên KLOO không? A: Có, vào Tab "Chat" > "Kết bạn" để tìm và thêm bạn. ' +
        'Q: Xem lịch sử đặt sân ở đâu? A: Vào Tab "Tài khoản" > "Lịch sử đặt sân".',
      category: 'faq',
      metadata: { topic: 'general_faq' },
    },
    {
      content: 'Thông tin tài khoản và hồ sơ người dùng KLOO: ' +
        'Xem và chỉnh sửa hồ sơ: Tab "Tài khoản" > "Chỉnh sửa hồ sơ". ' +
        'Đăng nhập bằng: Email/mật khẩu hoặc Google. ' +
        'Thông báo đặt sân: Được gửi qua push notification và xem trong Tab "Thông báo". ' +
        'Admin có thêm quyền: Quản lý sân, quản lý đơn đặt, quản lý người dùng, tạo sự kiện.',
      category: 'app_guide',
      metadata: { topic: 'account_guide' },
    },
  ];

  allChunks.push(...staticChunks);
  console.log(`\n📦 Tổng cộng: ${allChunks.length} chunks cần embed và lưu vào knowledge_base`);

  // ── 4. Xóa dữ liệu cũ trước khi seed lại ────────────────────────────────
  try {
    await supabaseAdmin.from('knowledge_base').delete().neq('id', 0);
    console.log('  🗑️  Đã xóa dữ liệu cũ trong knowledge_base');
  } catch (e) {
    console.warn('  ⚠️ Không thể xóa dữ liệu cũ:', e.message);
  }

  // ── 5. Embed từng chunk và lưu vào Supabase ──────────────────────────────
  let successCount = 0;
  let errorCount   = 0;

  for (let i = 0; i < allChunks.length; i++) {
    const chunk = allChunks[i];
    try {
      // Tạo embedding vector 768 chiều
      const embedding = await generateEmbedding(chunk.content);

      // Lưu vào Supabase
      const { error } = await supabaseAdmin.from('knowledge_base').insert({
        content:   chunk.content,
        category:  chunk.category,
        metadata:  chunk.metadata,
        embedding, // pgvector nhận Array<number> trực tiếp
      });

      if (error) {
        console.error(`  ❌ [${i + 1}/${allChunks.length}] Lỗi insert: ${error.message}`);
        errorCount++;
      } else {
        successCount++;
        console.log(`  ✅ [${i + 1}/${allChunks.length}] ${chunk.category}: "${chunk.content.substring(0, 50)}..."`);
      }

      // Delay 150ms giữa các request để tránh rate limit Gemini
      if (i < allChunks.length - 1) {
        await new Promise(r => setTimeout(r, 150));
      }
    } catch (e) {
      console.error(`  ❌ [${i + 1}/${allChunks.length}] Lỗi embed: ${e.message}`);
      errorCount++;
    }
  }

  const summary = {
    message:  `🌱 Seed hoàn tất!`,
    total:    allChunks.length,
    success:  successCount,
    errors:   errorCount,
    breakdown: {
      courts: allChunks.filter(c => c.category === 'court_info').length,
      events: allChunks.filter(c => c.category === 'event_info').length,
      guides: allChunks.filter(c => ['app_guide', 'app_policy', 'faq'].includes(c.category)).length,
    },
  };
  console.log('\n🏁 ===== SEED HOÀN TẤT =====', summary);
  res.json(summary);
});

// ─── MAIN CHATBOT ENDPOINT — RAG Pipeline ─────────────────────────────────────
// POST /ask
// Body (JSON):      { "prompt": "...", "user_id": "uuid..." }
// Body (multipart): form-data với fields: prompt, user_id + file: image
app.post('/ask', upload.single('image'), async (req, res) => {
  const imageFile  = req.file;
  const userPrompt = (req.body.prompt || '').trim();
  const userId     = req.body.user_id || null;

  // ── VISION PATH: Xử lý ảnh ──────────────────────────────────────────────
  if (imageFile) {
    if (!visionModel) {
      cleanupFile(imageFile.path);
      return res.status(500).json({ error: 'Lỗi khởi tạo AI vision model.' });
    }
    try {
      const imageData   = await fs.readFile(imageFile.path);
      const base64Image = imageData.toString('base64');
      const mimeType    = imageFile.mimetype || 'image/jpeg';
      const userCaption = userPrompt || '';

      // Prompt kiểm duyệt ảnh chi tiết, rõ ràng — với rejection message cố định
      const visionSystemPrompt = `Bạn là trợ lý kiểm duyệt ảnh cho ứng dụng KLOO - đặt sân thể thao.

NHIỆM VỤ DUY NHẤT: Xác định xem ảnh có thuộc các loại SAU ĐÂY không:
  ✔ Loại SÂN: Sân thể thao (cầu lông, bóng đá, tennis, pickleball, bida...)
  ✔ Loại DC: Dụng cụ thể thao (vợt, giày thể thao, quần áo thể thao, bóng...)
  ✔ Loại HD: Hóa đơn, biên lai thanh toán đặt sân, QR code thanh toán
  ✔ Loại APP: Ảnh chụp màn hình ứng dụng KLOO, lịch đặt sân
  ✔ Loại KQ: Kết quả thi đấu, bảng điểm môn thể thao

NẾU ảnh KHÔNG thuộc bất kỳ loại nào trên (ví dụ: ảnh selfie, ảnh đồ ăn, ảnh phong cảnh, ảnh động vật, mèo/chó, meme, tài liệu học tập, code, phim/truyện, ảnh cá nhân không liên quan...):
  → Hãy trả lời ĐÚNG CHÍNH XÁC câu sau (không thêm bớt gì):
  "Xin lỗi, tôi chỉ có thể phân tích ảnh liên quan đến sân thể thao, dụng cụ thể thao, hoặc hóa đơn đặt sân. Bạn hãy gửi ảnh phù hợp để tôi hỗ trợ bạn nhé!"

NẾU ảnh thuộc loại SÂN/DC/HD/APP/KQ:
  → Phân tích ảnh, trả lời cởi mở và hữu ích.
  → Nếu người dùng có nhận xét/câu hỏi kèm theo ("${userCaption}"), hãy trả lời câu hỏi đó.

KHÔNG dùng markdown, dấu *, **, #. Chỉ viết tiếng Việt. Ngắn gọn, thân thiện.`;

      const result = await visionModel.generateContent([
        { text: visionSystemPrompt },
        { inlineData: { data: base64Image, mimeType } },
      ]);

      cleanupFile(imageFile.path);
      let answer = result.response.text();
      answer = removeMarkdown(answer);
      console.log(`🖼️ [Vision] Answer: "${answer.substring(0, 80)}..."`);
      return res.json({ answer });
    } catch (error) {
      cleanupFile(imageFile.path);
      console.error('❌ Vision error:', error.message);
      return res.status(500).json({ error: 'Lỗi khi xử lý ảnh.' });
    }
  }

  // ── TEXT RAG PATH ────────────────────────────────────────────────────────
  if (!userPrompt || userPrompt.length === 0) {
    return res.status(400).json({ error: 'Câu hỏi không hợp lệ.' });
  }
  if (!chatModel || !embeddingModel) {
    return res.status(500).json({ error: 'AI model chưa sẵn sàng.' });
  }

  console.log(`\n📩 [RAG] Query: "${userPrompt.substring(0, 80)}${userPrompt.length > 80 ? '...' : ''}"`);
  console.log(`   User ID: ${userId || 'anonymous'}`);

  try {
    // ── RAG Step 1: Embed câu hỏi của user ──────────────────────────────
    const queryEmbedding = await generateEmbedding(userPrompt);
    console.log('  ✅ Step 1/4: Query embedded (768 dims)');

    // ── RAG Step 2: Tìm kiếm ngữ nghĩa trong knowledge base ─────────────
    const retrievedChunks = await retrieveRelevantChunks(queryEmbedding, 5, 0.50);
    console.log(
      `  ✅ Step 2/4: Retrieved ${retrievedChunks.length} chunks: ` +
      retrievedChunks.map(c => `[${c.category} ${(c.similarity * 100).toFixed(0)}%]`).join(', ')
    );

    // ── Guardrail tự động: Câu hỏi ngoài phạm vi ─────────────────────────
    // Nếu RAG không tìm được chunk nào liên quan (similarity < 0.50),
    // câu hỏi chắc chắn không thuộc phạm vi sân thể thao → từ chối ngay,
    // không tốn token gọi Gemini.
    if (retrievedChunks.length === 0) {
      console.log('  ⚠️  0 chunks retrieved → Câu hỏi ngoài phạm vi, từ chối ngay.');
      return res.json({
        answer:
          'Xin lỗi, tôi chỉ hỗ trợ các câu hỏi về sân thể thao và dịch vụ của KLOO. ' +
          'Bạn có thể hỏi tôi về cách đặt sân, giá sân, lịch sự kiện, hoặc chính sách hoàn tiền nhé!',
      });
    }

    // ── RAG Step 3: Lấy context cá nhân của user ─────────────────────────
    const userContext = await getUserContext(userId);
    console.log(`  ✅ Step 3/4: User context fetched`);

    // ── RAG Step 4: Xây dựng augmented prompt ────────────────────────────
    const augmentedPrompt = buildAugmentedPrompt(retrievedChunks, userContext, userPrompt);
    console.log(`  ✅ Step 4/4: Augmented prompt built (${augmentedPrompt.length} chars)`);

    // ── Step 5: Gemini sinh câu trả lời ──────────────────────────────────
    const chat = chatModel.startChat({
      generationConfig: { maxOutputTokens: 350 },
    });
    const result = await chat.sendMessage(augmentedPrompt);
    let answer   = result.response.text();
    answer       = removeMarkdown(answer);

    console.log(`  ✅ Answer: "${answer.substring(0, 80)}..." (${answer.length} chars)\n`);
    res.json({ answer });

  } catch (error) {
    console.error('❌ RAG pipeline error:', error.message);
    res.status(500).json({ error: 'Đã xảy ra lỗi khi xử lý yêu cầu.' });
  }
});

// ─── AUDIO ENDPOINT ───────────────────────────────────────────────────────────
app.post('/ask/audio', upload.single('audio'), async (req, res) => {
  const audioFile = req.file;
  if (!audioFile) return res.status(400).json({ error: 'Không có audio được gửi lên.' });
  cleanupFile(audioFile.path);
  res.json({
    answer: 'Tính năng xử lý audio đang được phát triển. Vui lòng sử dụng nút nhận diện giọng nói để chuyển thành text rồi gửi.'
  });
});

// ─── FORGOT PASSWORD ──────────────────────────────────────────────────────────
app.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email || typeof email !== 'string' || !email.includes('@')) {
    return res.status(400).json({ error: 'Email không hợp lệ.' });
  }

  const normalizedEmail = email.toLowerCase().trim();

  const { data: users, error: fetchError } = await supabaseAdmin.auth.admin.listUsers();
  if (fetchError) return res.status(500).json({ error: 'Lỗi kết nối server.' });

  const userExists = users.users.some(u => u.email?.toLowerCase() === normalizedEmail);
  if (!userExists) {
    return res.json({ message: 'Nếu email tồn tại, bạn sẽ nhận được mã OTP.' });
  }

  const otp       = crypto.randomInt(100000, 999999).toString();
  const expiresAt = Date.now() + 10 * 60 * 1000;
  otpStore.set(normalizedEmail, { otp, expiresAt, verified: false, resetToken: null });

  const htmlContent = `
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#f4f4f4;font-family:'Helvetica Neue',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 0;">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0"
        style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
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
              Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn. Sử dụng mã OTP dưới đây:
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
    const sentFrom   = new Sender(process.env.MAILERSEND_FROM_EMAIL, 'KLOO App');
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

// ─── VERIFY OTP ───────────────────────────────────────────────────────────────
app.post('/verify-otp', (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) return res.status(400).json({ error: 'Thiếu email hoặc mã OTP.' });

  const normalizedEmail = email.toLowerCase().trim();
  const record = otpStore.get(normalizedEmail);
  if (!record) return res.status(400).json({ error: 'Không tìm thấy yêu cầu OTP. Vui lòng gửi lại.' });
  if (Date.now() > record.expiresAt) {
    otpStore.delete(normalizedEmail);
    return res.status(400).json({ error: 'Mã OTP đã hết hạn. Vui lòng gửi lại.' });
  }
  if (record.otp !== otp.trim()) {
    return res.status(400).json({ error: 'Mã OTP không đúng. Vui lòng thử lại.' });
  }

  const resetToken = crypto.randomBytes(32).toString('hex');
  record.verified            = true;
  record.resetToken          = resetToken;
  record.resetTokenExpiresAt = Date.now() + 15 * 60 * 1000;
  otpStore.set(normalizedEmail, record);

  res.json({ message: 'Xác thực OTP thành công.', resetToken });
});

// ─── RESET PASSWORD ───────────────────────────────────────────────────────────
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

  const { data: users, error: listError } = await supabaseAdmin.auth.admin.listUsers();
  if (listError) return res.status(500).json({ error: 'Lỗi kết nối server.' });

  const user = users.users.find(u => u.email?.toLowerCase() === normalizedEmail);
  if (!user) return res.status(404).json({ error: 'Không tìm thấy tài khoản.' });

  const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
    user.id, { password: newPassword }
  );
  if (updateError) {
    console.error('Supabase update error:', updateError);
    return res.status(500).json({ error: 'Không thể cập nhật mật khẩu. Vui lòng thử lại.' });
  }

  otpStore.delete(normalizedEmail);
  res.json({ message: 'Mật khẩu đã được cập nhật thành công.' });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
app.listen(port, () => {
  console.log(`\n🚀 KLOO Backend (RAG v2.0) đang chạy tại http://localhost:${port}`);
  console.log(`   Embedding model: text-embedding-004 (768 dims)`);
  console.log(`   Vector DB: Supabase pgvector`);
  console.log(`   Seed: POST /admin/seed-knowledge\n`);
});
