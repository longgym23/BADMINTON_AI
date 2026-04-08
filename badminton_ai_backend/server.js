// ============================================================
// KLOO Badminton AI Backend — RAG (Retrieval-Augmented Generation)
// Architecture:
//   User Query → Embed Query → Vector Search (Supabase pgvector)
//               → Augmented Prompt → Gemini → Answer
// Version: 3.1.0 — Updated to gemini-2.5-flash-lite
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
// Giảm limit xuống 5MB và chỉ chấp nhận ảnh để tránh Connection reset trên Render
const upload = multer({
  dest: 'uploads/',
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Chỉ chấp nhận ảnh JPEG, PNG, WebP hoặc GIF.'));
    }
  },
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
  visionModel    = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  embeddingModel = genAI.getGenerativeModel({ model: 'text-embedding-004' });
  console.log('✅ Gemini models initialized (chat + vision + embedding) — gemini-2.5-flash-lite');
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

// ─── Sports Tips Knowledge ────────────────────────────────────────────────────
const SPORTS_TIPS = {
  badminton: {
    name: 'Cầu lông',
    tips: [
      'Giữ vợt nhẹ nhàng, không siết chặt — giúp cổ tay linh hoạt và đánh mạnh hơn.',
      'Luôn trở về vị trí trung tâm sân sau mỗi cú đánh để sẵn sàng cho pha tiếp theo.',
      'Luyện tập smash chéo sân — khó đỡ hơn smash thẳng.',
      'Mang giày cầu lông chuyên dụng để bảo vệ mắt cá chân khi di chuyển nhanh.',
      'Khởi động kỹ vai, cổ tay và đầu gối trước khi thi đấu để tránh chấn thương.',
      'Sử dụng cầu lông chất lượng tốt để kiểm soát đường bay chính xác hơn.',
    ],
    equipment: 'Vợt, cầu lông, giày chuyên dụng, quần áo thể thao thoáng khí.',
    benefits: 'Tăng cường phản xạ, đốt calo hiệu quả, cải thiện tim mạch và sự linh hoạt.',
  },
  football: {
    name: 'Bóng đá',
    tips: [
      'Kiểm soát bóng bằng lòng bàn chân để giữ bóng chắc và chuyền chính xác.',
      'Luôn quan sát đồng đội và không gian xung quanh trước khi nhận bóng.',
      'Tập sút bằng cả hai chân để trở thành cầu thủ toàn diện hơn.',
      'Mang giày đinh phù hợp với mặt sân (cỏ nhân tạo hoặc sân cứng).',
      'Uống đủ nước trước, trong và sau trận đấu — bóng đá tiêu hao năng lượng rất lớn.',
      'Luyện sút phạt đều đặn — đây là kỹ năng quyết định nhiều trận đấu.',
    ],
    equipment: 'Bóng đá, giày đinh, shin guard (bảo vệ ống chân), áo đấu.',
    benefits: 'Rèn luyện toàn thân, tăng sức bền, cải thiện kỹ năng làm việc nhóm.',
  },
  tennis: {
    name: 'Tennis',
    tips: [
      'Nắm vợt theo kiểu Continental để linh hoạt cho cả forehand và backhand.',
      'Giữ mắt trên bóng cho đến khi vợt chạm bóng — đừng nhìn nơi muốn đánh!',
      'Cú serve đóng vai trò then chốt — luyện tossing bóng đúng điểm trước.',
      'Di chuyển bằng bước nhỏ nhanh (split step) trước khi đối thủ đánh bóng.',
      'Dây vợt căng vừa phải (khoảng 55-60 lbs) để cân bằng lực và kiểm soát.',
      'Mang giày tennis để đảm bảo bám sân và hỗ trợ cổ chân.',
    ],
    equipment: 'Vợt tennis, bóng tennis, giày tennis, băng cổ tay.',
    benefits: 'Tăng phản xạ, sức mạnh tay, sức bền và tập trung tâm lý.',
  },
  pickleball: {
    name: 'Pickleball',
    tips: [
      'Luôn giữ vị trí ở kitchen line (vạch không-volley) để kiểm soát trận đấu.',
      'Dink shot (đánh nhẹ qua lưới) là vũ khí chiến lược quan trọng nhất trong pickleball.',
      'Tránh đứng ở "no man\'s land" (giữa sân) — dễ bị bắt bài.',
      'Giao bóng xoáy dưới (topspin drop serve) để tăng khó khăn cho đối thủ.',
      'Luyện backhand dink vì đây là điểm yếu của hầu hết người mới chơi.',
      'Pickleball phù hợp mọi lứa tuổi — sân nhỏ hơn, ít chạy hơn tennis nhưng chiến thuật nhiều.',
    ],
    equipment: 'Vợt pickleball, bóng pickleball có lỗ, giày court sports.',
    benefits: 'Thân thiện với khớp, cải thiện phản xạ, phù hợp người cao tuổi và người mới.',
  },
};

// ─── RAG: Step 1 — Generate Embedding ────────────────────────────────────────
async function generateEmbedding(text) {
  if (!embeddingModel) throw new Error('Embedding model chưa sẵn sàng');
  const result = await embeddingModel.embedContent(text);
  return result.embedding.values;
}

// ─── RAG: Step 2 — Retrieve Relevant Knowledge Chunks ────────────────────────
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
function buildAugmentedPrompt(retrievedChunks, userContext, userQuestion) {
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

  return `Bạn là trợ lý ảo KLOO - ứng dụng đặt sân thể thao chuyên nghiệp (cầu lông, bóng đá, tennis, pickleball).
Bạn thân thiện, nhiệt tình và chỉ hỗ trợ các chủ đề liên quan đến thể thao và dịch vụ KLOO.

[THÔNG TIN ĐƯỢC TRUY XUẤT TỪ CƠ SỞ DỮ LIỆU]
${knowledgeSection}

[LỊCH CÁ NHÂN CỦA NGƯỜI DÙNG]
${userContext}

[NGUYÊN TẮC TRẢ LỜI BẮT BUỘC]
1. Ưu tiên dùng thông tin trong phần THÔNG TIN ĐƯỢC TRUY XUẤT để trả lời chính xác.
2. Nếu câu hỏi KHÔNG liên quan đến: sân thể thao, KLOO, đặt sân, sự kiện, thanh toán, tập luyện thể thao, hoặc lời khuyên về 4 môn (cầu lông, bóng đá, tennis, pickleball) → từ chối lịch sự: "Xin lỗi, tôi chỉ hỗ trợ về sân thể thao và dịch vụ của KLOO. Bạn có câu hỏi nào về đặt sân hoặc các môn thể thao không?"
3. Nếu người dùng muốn TÌM SÂN hoặc GỢI Ý SÂN, thêm đúng 1 đoạn mã [ACTION_SEARCH:sport_type] ở cuối câu trả lời. Giá trị sport_type CHỈ được chọn trong: football, badminton, tennis, pickleball.
4. Không được bịa thông tin không có trong ngữ cảnh.
5. Trả lời ngắn gọn, thân thiện, tiếng Việt. KHÔNG dùng markdown, dấu *, **, #, hoặc ký hiệu đặc biệt.
6. Hướng dẫn đặt sân: Mở app KLOO → Tab "Đặt sân" → Chọn ngày → Chọn sân → Chọn giờ → Thanh toán ví KLOO hoặc SePay.

[CÂU HỎI NGƯỜI DÙNG]
${userQuestion}`;
}

// ─── Express App ──────────────────────────────────────────────────────────────
const app  = express();
const port = process.env.PORT || 3000;

// Keep-alive headers để Render không đột ngột cắt kết nối
app.use((req, res, next) => {
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('Keep-Alive', 'timeout=120');
  next();
});

app.use(cors());
app.use(express.json());

// Timeout middleware: trả về lỗi rõ ràng thay vì để kết nối bị cắt đột ngột
app.use((req, res, next) => {
  res.setTimeout(110_000, () => {
    console.error('⏰ Request timeout sau 110s:', req.path);
    if (!res.headersSent) {
      res.status(503).json({
        error: 'Yêu cầu mất quá nhiều thời gian. Máy chủ đang bận, vui lòng thử lại sau vài giây nhé!',
      });
    }
  });
  next();
});

// Health Check
app.get('/', (req, res) => {
  res.json({
    status: 'running',
    version: '3.1.0',
    mode: 'Retrieval-Augmented Generation (RAG)',
    models: {
      chat:      'gemini-2.5-flash-lite',
      vision:    'gemini-2.5-flash-lite',
      embedding: 'text-embedding-004 (768 dims)',
    },
  });
});

// ─── GET /courts — Lấy danh sách sân theo loại môn thể thao ─────────────────
// Query: ?sport_type=badminton&limit=8
app.get('/courts', async (req, res) => {
  const sportType = (req.query.sport_type || '').toLowerCase().trim();
  const limit     = Math.min(parseInt(req.query.limit) || 8, 20);

  try {
    let query = supabaseAdmin
      .from('courts')
      .select('id, name, sport_type, address, price_per_hour, image_url, status, sub_courts, description')
      .eq('status', 'active')
      .limit(limit);

    // Lọc theo loại sân nếu có
    if (sportType && ['football', 'badminton', 'tennis', 'pickleball'].includes(sportType)) {
      query = query.ilike('sport_type', `%${sportType}%`);
    }

    const { data, error } = await query;
    if (error) {
      console.error('❌ /courts error:', error.message);
      return res.status(500).json({ error: 'Không thể lấy danh sách sân.' });
    }

    const courts = (data || []).map(c => ({
      id:            c.id,
      name:          c.name,
      sport_type:    c.sport_type || 'Đa năng',
      address:       c.address || 'Chưa cập nhật',
      price_per_hour: c.price_per_hour || 0,
      image_url:     c.image_url || null,
      sub_courts:    c.sub_courts || 1,
      description:   c.description || '',
    }));

    console.log(`✅ /courts [${sportType || 'all'}] → ${courts.length} sân`);
    res.json({ courts, sport_type: sportType || 'all', count: courts.length });
  } catch (e) {
    console.error('❌ /courts exception:', e.message);
    res.status(500).json({ error: 'Lỗi server.' });
  }
});

// ─── POST /sports-tips — Lời khuyên về môn thể thao ─────────────────────────
// Body: { "sport": "badminton" }
app.post('/sports-tips', async (req, res) => {
  const sport = (req.body.sport || '').toLowerCase().trim();
  const validSports = ['badminton', 'football', 'tennis', 'pickleball'];

  if (!sport || !validSports.includes(sport)) {
    return res.status(400).json({
      error: 'Môn thể thao không hợp lệ. Chọn: badminton, football, tennis, pickleball.',
    });
  }

  const data = SPORTS_TIPS[sport];
  if (!data) {
    return res.status(404).json({ error: 'Không tìm thấy thông tin.' });
  }

  // Dùng Gemini để tạo lời khuyên tự nhiên hơn dựa trên data tĩnh
  try {
    if (chatModel) {
      const prompt = `Bạn là huấn luyện viên thể thao chuyên nghiệp trong ứng dụng KLOO.
Hãy đưa ra 3 lời khuyên ngắn gọn, thực tế và hữu ích nhất cho người mới bắt đầu chơi ${data.name}.
Sử dụng thông tin này làm cơ sở: ${data.tips.join('. ')}
Dụng cụ cần: ${data.equipment}
Lợi ích: ${data.benefits}

Trả lời thân thiện, ngắn gọn bằng tiếng Việt. KHÔNG dùng markdown hay ký hiệu đặc biệt. Mỗi lời khuyên trên 1 dòng với số thứ tự.`;

      const result = await chatModel.generateContent(prompt);
      let answer = result.response.text();
      answer = removeMarkdown(answer);
      return res.json({ sport, name: data.name, tips: answer, equipment: data.equipment, benefits: data.benefits });
    }
  } catch (e) {
    console.error('❌ /sports-tips Gemini error:', e.message);
  }

  // Fallback nếu Gemini lỗi
  res.json({
    sport,
    name:      data.name,
    tips:      data.tips.slice(0, 3).join('\n'),
    equipment: data.equipment,
    benefits:  data.benefits,
  });
});

// ─── SEED KNOWLEDGE BASE ──────────────────────────────────────────────────────
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
    // Sports tips knowledge
    {
      content: 'Lời khuyên chơi cầu lông (badminton): ' +
        'Giữ vợt nhẹ nhàng để cổ tay linh hoạt. ' +
        'Luôn trở về trung tâm sân sau mỗi cú đánh. ' +
        'Luyện smash chéo sân và drop shot để đối thủ khó đỡ. ' +
        'Mang giày cầu lông chuyên dụng để bảo vệ mắt cá chân. ' +
        'Khởi động vai và cổ tay kỹ trước khi thi đấu.',
      category: 'sport_tips',
      metadata: { topic: 'badminton_tips', sport: 'badminton' },
    },
    {
      content: 'Lời khuyên chơi bóng đá (football): ' +
        'Kiểm soát bóng bằng lòng bàn chân để chuyền chính xác. ' +
        'Quan sát đồng đội và không gian trước khi nhận bóng. ' +
        'Tập sút bằng cả hai chân để toàn diện hơn. ' +
        'Uống đủ nước vì bóng đá tiêu hao năng lượng rất lớn. ' +
        'Mang giày đinh phù hợp với mặt sân.',
      category: 'sport_tips',
      metadata: { topic: 'football_tips', sport: 'football' },
    },
    {
      content: 'Lời khuyên chơi tennis: ' +
        'Giữ mắt trên bóng đến khi vợt chạm bóng. ' +
        'Luyện serve kỹ vì đây là cú đánh quan trọng nhất. ' +
        'Di chuyển bằng bước nhỏ nhanh (split step) trước khi đối thủ đánh. ' +
        'Dây vợt căng 55-60 lbs để cân bằng lực và kiểm soát. ' +
        'Mang giày tennis chuyên dụng để bám sân tốt.',
      category: 'sport_tips',
      metadata: { topic: 'tennis_tips', sport: 'tennis' },
    },
    {
      content: 'Lời khuyên chơi pickleball: ' +
        'Luôn giữ vị trí ở kitchen line để kiểm soát trận đấu. ' +
        'Dink shot (đánh nhẹ qua lưới) là vũ khí chiến lược quan trọng nhất. ' +
        'Tránh đứng ở no man\'s land giữa sân vì dễ bị bắt bài. ' +
        'Luyện backhand dink vì đây là điểm yếu của hầu hết người mới. ' +
        'Pickleball phù hợp mọi lứa tuổi, thân thiện với khớp hơn tennis.',
      category: 'sport_tips',
      metadata: { topic: 'pickleball_tips', sport: 'pickleball' },
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
      const embedding = await generateEmbedding(chunk.content);
      const { error } = await supabaseAdmin.from('knowledge_base').insert({
        content:   chunk.content,
        category:  chunk.category,
        metadata:  chunk.metadata,
        embedding,
      });

      if (error) {
        console.error(`  ❌ [${i + 1}/${allChunks.length}] Lỗi insert: ${error.message}`);
        errorCount++;
      } else {
        successCount++;
        console.log(`  ✅ [${i + 1}/${allChunks.length}] ${chunk.category}: "${chunk.content.substring(0, 50)}..."`);
      }

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
      courts:      allChunks.filter(c => c.category === 'court_info').length,
      events:      allChunks.filter(c => c.category === 'event_info').length,
      guides:      allChunks.filter(c => ['app_guide', 'app_policy', 'faq'].includes(c.category)).length,
      sport_tips:  allChunks.filter(c => c.category === 'sport_tips').length,
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

      // ── Vision Prompt với 2 bước kiểm duyệt chặt chẽ ─────────────────
      // Bước 1: Phân loại ảnh
      // Bước 2: Chỉ xử lý nếu thuộc phạm vi thể thao
      const visionSystemPrompt = `Bạn là trợ lý AI của ứng dụng KLOO - đặt sân thể thao. Nhiệm vụ của bạn là phân tích ảnh liên quan đến thể thao và từ chối lịch sự các ảnh không phù hợp.

BƯỚC 1 - KIỂM TRA ẢNH:
Xác định ảnh thuộc loại nào:

CHẤP NHẬN (liên quan đến thể thao và KLOO):
- Sân thể thao: sân cầu lông, sân bóng đá, sân tennis, sân pickleball
- Dụng cụ thể thao: vợt cầu lông/tennis/pickleball, bóng đá, giày thể thao, quần áo thi đấu
- Hóa đơn/biên lai đặt sân, QR code thanh toán sân
- Ảnh chụp màn hình ứng dụng KLOO, lịch đặt sân
- Kết quả thi đấu, bảng điểm thể thao

TỪ CHỐI (KHÔNG liên quan, phải từ chối ngay):
- Phòng gym, máy tập gym, dụng cụ tập gym (tạ, thanh tập, máy chạy bộ, máy đạp xe...)
- Yoga, thiền, stretching trong nhà
- Ảnh selfie, chân dung người không liên quan thể thao sân
- Ảnh đồ ăn, thức uống, nhà hàng
- Ảnh phong cảnh, du lịch, thiên nhiên
- Ảnh động vật, mèo, chó, thú cưng
- Meme, ảnh hài hước không liên quan thể thao
- Tài liệu học tập, sách vở, code
- Ảnh chụp màn hình mạng xã hội, chat cá nhân
- Ảnh xe cộ, nhà cửa, đồ vật không liên quan

BƯỚC 2 - TRẢ LỜI:

NẾU ảnh KHÔNG thuộc danh sách CHẤP NHẬN → trả lời CHÍNH XÁC câu này (không thêm bớt):
"Xin lỗi, tôi chỉ có thể phân tích ảnh liên quan đến sân thể thao, dụng cụ thể thao, hoặc hóa đơn đặt sân. Bạn hãy gửi ảnh phù hợp để tôi hỗ trợ bạn nhé!"

NẾU ảnh CHẤP NHẬN → phân tích chi tiết và hữu ích:
- Mô tả những gì thấy trong ảnh
- Đưa ra nhận xét/lời khuyên liên quan đến sport
- Nếu người dùng có câu hỏi kèm theo ("${userCaption}"), trả lời câu hỏi đó
- Nếu phù hợp, gợi ý người dùng đặt sân qua KLOO

QUAN TRỌNG: KHÔNG dùng markdown, dấu *, **, #. Chỉ viết tiếng Việt. Ngắn gọn và thân thiện.`;

      const result = await visionModel.generateContent([
        { text: visionSystemPrompt },
        { inlineData: { data: base64Image, mimeType } },
      ]);

      cleanupFile(imageFile.path);
      let answer = result.response.text();
      answer = removeMarkdown(answer);
      console.log(`🖼️ [Vision] Answer: "${answer.substring(0, 100)}..."`);
      return res.json({ answer });

    } catch (error) {
      cleanupFile(imageFile.path);
      console.error('❌ Vision error:', error.message);
      return res.status(500).json({ error: 'Lỗi khi xử lý ảnh. Vui lòng thử lại!' });
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

    // ── Guardrail: Câu hỏi ngoài phạm vi ─────────────────────────────────
    if (retrievedChunks.length === 0) {
      console.log('  ⚠️  0 chunks retrieved → Câu hỏi ngoài phạm vi, từ chối ngay.');
      return res.json({
        answer:
          'Xin lỗi, tôi chỉ hỗ trợ các câu hỏi về sân thể thao và dịch vụ của KLOO. ' +
          'Bạn có thể hỏi tôi về cách đặt sân, giá sân, lịch sự kiện, lời khuyên tập luyện, hoặc chính sách hoàn tiền nhé!',
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
      generationConfig: { maxOutputTokens: 400 },
    });
    const result = await chat.sendMessage(augmentedPrompt);
    let answer   = result.response.text();
    answer       = removeMarkdown(answer);

    console.log(`  ✅ Answer: "${answer.substring(0, 80)}..." (${answer.length} chars)\n`);
    res.json({ answer });

  } catch (error) {
    console.error('❌ RAG pipeline error:', error.message);
    res.status(500).json({ error: 'Đã xảy ra lỗi khi xử lý yêu cầu. Vui lòng thử lại!' });
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

// ─── Multer Error Handler ─────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ error: 'Ảnh quá lớn. Vui lòng gửi ảnh nhỏ hơn 5MB.' });
    }
    return res.status(400).json({ error: `Lỗi upload: ${err.message}` });
  }
  if (err && err.message && err.message.includes('Chỉ chấp nhận')) {
    return res.status(400).json({ error: err.message });
  }
  next(err);
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
  console.log(`\n🚀 KLOO Backend (RAG v3.1) đang chạy tại http://localhost:${port}`);
  console.log(`   Chat/Vision model: gemini-2.5-flash-lite`);
  console.log(`   Embedding model: text-embedding-004 (768 dims)`);
  console.log(`   Vector DB: Supabase pgvector`);
  console.log(`   Endpoints: /ask, /courts, /sports-tips, /admin/seed-knowledge\n`);
});
