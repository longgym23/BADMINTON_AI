/**
 * KLOO Chatbot Backend — Node.js / Express
 * ═══════════════════════════════════════════════════════════════
 * RAG Improvements (All 3 Phases):
 *
 * Phase 1 — Cơ bản:
 *   - Embedding cache (in-memory, TTL 5 phút) → giảm API calls
 *   - Similarity threshold tích hợp vào hybrid SQL → loại bỏ noise
 *   - Markdown-aware chunking (ở ingest_kb.js)
 *
 * Phase 2 — Multi-turn & Intent routing:
 *   - quickIntent(): phát hiện câu hỏi đơn giản → bỏ qua RAG tốn kém
 *   - sessionStore: lưu lịch sử hội thoại theo session_id (multi-turn)
 *
 * Phase 3 — Hybrid BM25 + Vector:
 *   - retrieveKnowledge() gọi match_kb_hybrid() thay vì match_kb_chunks()
 *   - Kết hợp cosine similarity (60%) + ts_rank BM25 (40%)
 *   - Bắt được tên riêng, mã ID, từ khóa chính xác mà vector bỏ sót
 * ═══════════════════════════════════════════════════════════════
 */

require('dotenv').config();
const express  = require('express');
const cors     = require('cors');
const multer   = require('multer');
const fs       = require('fs-extra');
const path     = require('path');
const crypto   = require('crypto');
const { GoogleGenerativeAI }                      = require('@google/generative-ai');
const { MailerSend, EmailParams, Sender, Recipient } = require('mailersend');
const { createClient }                            = require('@supabase/supabase-js');

// ─── MailerSend ───────────────────────────────────────────────────────────────
const mailerSend = new MailerSend({ apiKey: process.env.MAILERSEND_API_KEY });

// ─── Supabase Admin Client ────────────────────────────────────────────────────
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

// ─── OTP Store (in-memory) ────────────────────────────────────────────────────
const otpStore = new Map(); // email → { otp, expiresAt, verified, resetToken }

// ─── Multer ───────────────────────────────────────────────────────────────────
const upload = multer({ dest: 'uploads/', limits: { fileSize: 10 * 1024 * 1024 } });
fs.ensureDirSync('uploads');

// ─── Gemini AI Setup ──────────────────────────────────────────────────────────
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
if (!GEMINI_API_KEY || GEMINI_API_KEY === 'YOUR_API_KEY_PLACEHOLDER') {
  console.error('[ERROR] Gemini API Key chưa được cấu hình trong .env!');
}

let genAI, model, visionModel, embedModel;
try {
  genAI        = new GoogleGenerativeAI(GEMINI_API_KEY);
  model        = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  visionModel  = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  const embeddingModelName = process.env.GEMINI_EMBEDDING_MODEL || 'gemini-embedding-2-preview';
  embedModel   = genAI.getGenerativeModel({ model: embeddingModelName });
  console.log(`[INFO] Gemini models loaded. Embedding: ${embeddingModelName}`);
} catch (err) {
  console.error('[ERROR] Khởi tạo Gemini thất bại:', err.message);
}

// ─── System Prompt ────────────────────────────────────────────────────────────
const SYSTEM_PROMPT =
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
5. Tự động nhận diện Action mà người dùng có ý định muốn thực hiện:
   - "search_courts": Khi user muốn tìm sân, xem danh sách sân, đặt lịch.
   - "view_schedule": Khi user muốn xem lịch hẹn, quản lý lịch đã đặt.
   - "cancel_booking": Khi user muốn hủy lịch đã đặt.
   - "view_expense": Khi user muốn xem số dư, nạp ví, chi tiêu.
   - "none": Hỏi đáp thông thường.`;

// ═══════════════════════════════════════════════════════════════════════════════
// PHASE 1 — EMBEDDING CACHE (TTL 5 phút, max 300 entries)
// Mục đích: tránh gọi Embedding API lặp lại cho cùng một câu hỏi
// ═══════════════════════════════════════════════════════════════════════════════
const _embCache = new Map(); // key: text_prefix → { vec: number[], expireAt: number }
const EMBED_CACHE_TTL  = 5 * 60 * 1000; // 5 phút
const EMBED_CACHE_MAX  = 300;

async function embedText(text) {
  if (!embedModel) throw new Error('Embedding model chưa sẵn sàng.');

  // Cache key: dùng 250 ký tự đầu (đủ phân biệt, không tốn bộ nhớ)
  const cacheKey = text.slice(0, 250);
  const cached   = _embCache.get(cacheKey);
  if (cached && Date.now() < cached.expireAt) {
    return cached.vec; // Cache HIT — bỏ qua API call
  }

  // Cache MISS — gọi API
  const res = await embedModel.embedContent({
    content: { parts: [{ text }], role: 'user' },
    outputDimensionality: 1536,
  });
  const v =
    res?.embedding?.values ||
    res?.embedding?.value  ||
    res?.embedding         ||
    res?.data?.[0]?.embedding;
  if (!Array.isArray(v)) throw new Error('Embedding API trả về dữ liệu không hợp lệ.');

  // Lưu cache, tự dọn khi đầy (LRU đơn giản: xóa entry đầu tiên)
  if (_embCache.size >= EMBED_CACHE_MAX) {
    _embCache.delete(_embCache.keys().next().value);
  }
  _embCache.set(cacheKey, { vec: v, expireAt: Date.now() + EMBED_CACHE_TTL });

  return v;
}

// ═══════════════════════════════════════════════════════════════════════════════
// PHASE 2 — INTENT PRE-ROUTING
// Phát hiện nhanh ý định câu hỏi để bỏ qua RAG khi không cần thiết
// Tiết kiệm: ~150ms latency + 1 Embedding API call cho mỗi câu chào/đơn giản
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Phân loại nhanh intent từ text (không dùng AI — heuristic thuần).
 * @returns {'greeting'|'cancel_booking'|'pricing'|'search'|'schedule'|'general'}
 */
function quickIntent(prompt) {
  if (!prompt || typeof prompt !== 'string') return 'general';
  const p = prompt.toLowerCase().trim();

  // Chào hỏi, cảm ơn — không cần RAG
  if (/^(xin chào|chào|hi\b|hello|hey|alo|cảm ơn|thanks|thank you)/.test(p)) return 'greeting';
  if (/^(ok|oke|okay|được|rồi|vâng|dạ|ừ|uhm)$/.test(p))                      return 'greeting';

  // Hủy lịch
  if (/(hủy|cancel).*(lịch|đặt|sân|booking)/i.test(p))  return 'cancel_booking';

  // Giá cả / phí
  if (/(giá|bao nhiêu|tiền|phí|cost|giờ|price)/.test(p)) return 'pricing';

  // Tìm / đặt sân
  if (/(tìm|đặt|sân nào|có sân|book|search)/.test(p))    return 'search';

  // Lịch của tôi
  if (/(lịch|schedule|booking|đã đặt|sắp tới)/.test(p))  return 'schedule';

  return 'general'; // Cần RAG đầy đủ
}

// ═══════════════════════════════════════════════════════════════════════════════
// PHASE 2 — MULTI-TURN CONVERSATION HISTORY
// Lưu lịch sử hội thoại theo session (user_id hoặc session_id)
// Gemini nhớ được context của 3 cặp Q&A gần nhất
// ═══════════════════════════════════════════════════════════════════════════════
const sessionStore = new Map(); // sessionId → Gemini history[]
const SESSION_MAX_TURNS = 6;    // Tối đa 6 lượt (3 cặp user/model)
const SESSION_TTL       = 30 * 60 * 1000; // Session tự hết hạn sau 30 phút không dùng
const _sessionTTLMap    = new Map(); // sessionId → expireAt

function getSession(sessionId) {
  if (!sessionId) return [];
  const expireAt = _sessionTTLMap.get(sessionId);
  if (expireAt && Date.now() > expireAt) {
    sessionStore.delete(sessionId);
    _sessionTTLMap.delete(sessionId);
    return [];
  }
  return sessionStore.get(sessionId) || [];
}

function saveSession(sessionId, history) {
  if (!sessionId) return;
  // Chỉ giữ N lượt gần nhất
  const trimmed = history.slice(-SESSION_MAX_TURNS);
  sessionStore.set(sessionId, trimmed);
  _sessionTTLMap.set(sessionId, Date.now() + SESSION_TTL);

  // Giới hạn tổng số session trong memory (tránh leak)
  if (sessionStore.size > 500) {
    sessionStore.delete(sessionStore.keys().next().value);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PHASE 3 — HYBRID RETRIEVAL (BM25 + Vector Cosine Similarity)
// Gọi Supabase RPC match_kb_hybrid() thay vì match_kb_chunks()
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Lấy các knowledge chunks liên quan nhất theo hybrid score.
 * Hybrid score = 0.6 × vector_similarity + 0.4 × bm25_ts_rank
 *
 * @param {string} userPrompt - Câu hỏi gốc của user
 * @param {string} intentHint - Intent từ quickIntent() để điều chỉnh trọng số
 * @returns {Array} rows - Danh sách chunks, mỗi chunk có { content, title, source, similarity, bm25_score, hybrid_score }
 */
async function retrieveKnowledge(userPrompt, intentHint = 'general') {
  if (!supabaseAdmin || !userPrompt) return [];
  try {
    const queryEmbedding = await embedText(userPrompt);

    // Điều chỉnh trọng số theo intent:
    // - "pricing"/"search": từ ngữ semantic quan trọng → tăng vector weight
    // - "cancel_booking": tên riêng/thời gian quan trọng → tăng bm25 weight
    let vectorWeight = 0.6;
    let bm25Weight   = 0.4;
    if (intentHint === 'cancel_booking' || intentHint === 'schedule') {
      vectorWeight = 0.5; bm25Weight = 0.5; // cân bằng hơn
    }

    const { data, error } = await supabaseAdmin.rpc('match_kb_hybrid', {
      query_text:           userPrompt,
      query_embedding:      queryEmbedding,
      match_count:          6,
      vector_weight:        vectorWeight,
      bm25_weight:          bm25Weight,
      similarity_threshold: 0.45,
    });

    if (error) {
      console.error('[RAG] Hybrid retrieve error:', error.message);
      return [];
    }
    return Array.isArray(data) ? data : [];
  } catch (e) {
    console.error('[RAG] Hybrid retrieve exception:', e.message);
    return [];
  }
}

// ─── User Context (không đổi) ─────────────────────────────────────────────────
async function getUserContext(userId) {
  if (!userId || !supabaseAdmin) return '';
  try {
    const today = new Date().toISOString().split('T')[0];
    const { data: bookings } = await supabaseAdmin
      .from('bookings')
      .select('booking_date, time_slot, court_name, status')
      .eq('user_id', userId)
      .gte('booking_date', today)
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
    console.error('[RAG] getUserContext error:', e.message);
    return '';
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
function buildSourcesBlock(rows) {
  if (!rows || rows.length === 0) return '';
  const lines = rows.map((r, idx) => {
    const source = r.source || r.title || 'KB';
    const score  = r.hybrid_score != null
      ? ` [hybrid=${r.hybrid_score.toFixed(3)}]`
      : '';
    return `S${idx + 1} | ${source}${score} | ${String(r.content || '').replace(/\s+/g, ' ').trim()}`;
  });
  return `SOURCES:\n${lines.join('\n')}\n`;
}

function removeMarkdown(text) {
  if (!text || typeof text !== 'string') return text;
  return text
    .replace(/\*\*/g, '')
    .replace(/\*/g, '')
    .replace(/#{1,6}\s/g, '')
    .replace(/`/g, '')
    .replace(/~~/g, '')
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .trim();
}

function safeJsonParse(text) {
  if (!text || typeof text !== 'string') return null;
  
  // 1. Nếu có Markdown code block (```json ... ```), tách nó ra
  const match = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  let cleanText = match ? match[1] : text;

  // 2. Tìm block {} json
  const start = cleanText.indexOf('{');
  const end   = cleanText.lastIndexOf('}');
  if (start >= 0 && end > start) {
    cleanText = cleanText.slice(start, end + 1);
  }

  try { return JSON.parse(cleanText); } catch (_) { return null; }
}

function normalizeAction(action) {
  const a    = action && typeof action === 'object' ? action : {};
  const type = typeof a.type === 'string' ? a.type : 'none';
  const allowed = new Set(['search_courts', 'view_schedule', 'view_expense', 'cancel_booking', 'none']);
  if (!allowed.has(type)) return { type: 'none' };
  const out = { type };
  if (type === 'search_courts' && typeof a.sport === 'string') out.sport = a.sport;
  return out;
}

const cleanupFile = (filePath) => {
  if (filePath && fs.existsSync(filePath)) {
    fs.unlink(filePath).catch(err => console.error('[WARN] Lỗi xóa file tạm:', err));
  }
};

// ─── Express App ──────────────────────────────────────────────────────────────
const app  = express();
const port = process.env.PORT || 3000;
app.use(cors());
app.use(express.json());

// ═══════════════════════════════════════════════════════════════════════════════
// POST /ask — Main chatbot endpoint (text + optional image)
// ═══════════════════════════════════════════════════════════════════════════════
app.post('/ask', upload.single('image'), async (req, res) => {
  const imageFile  = req.file;
  const userId     = req.body.user_id    || '';
  const sessionId  = req.body.session_id || userId || null;
  const userPrompt = req.body.prompt     || (imageFile ? 'Phân tích ảnh này.' : '');

  const intent     = quickIntent(userPrompt);
  const needsRAG   = !['greeting'].includes(intent);

  const [kbRows, userContext] = await Promise.all([
    needsRAG ? retrieveKnowledge(userPrompt, intent) : Promise.resolve([]),
    getUserContext(userId),
  ]);

  const sourcesBlock = buildSourcesBlock(kbRows);
  const sessionHistory = getSession(sessionId);

  const fullPrompt =
    `${SYSTEM_PROMPT}\n\n` +
    `Bạn PHẢI trả về JSON hợp lệ theo schema sau (KHÔNG thêm text ngoài JSON):\n` +
    `{\n` +
    `  "answer": "string (plain text, không markdown)",\n` +
    `  "action": { "type": "search_courts|view_schedule|view_expense|cancel_booking|none", "sport": "optional" },\n` +
    `  "used_sources": ["S1","S2"]\n` +
    `}\n\n` +
    `${sourcesBlock}\n` +
    `${userContext}\n` +
    `USER_ASK: ${userPrompt}`;

  // ─── Xử lý ảnh ────────────────────────────────────────────────────────────
  if (imageFile) {
    if (!visionModel) {
      cleanupFile(imageFile.path);
      return res.status(500).json({ error: 'Vision model chưa sẵn sàng.' });
    }
    try {
      const imageData   = await fs.readFile(imageFile.path);
      const base64Image = imageData.toString('base64');
      const mimeType    = imageFile.mimetype || 'image/jpeg';

      const result = await visionModel.generateContent({
        contents: [{
          role: 'user',
          parts: [
            { text: fullPrompt }, 
            { inlineData: { data: base64Image, mimeType } }
          ]
        }],
        generationConfig: { responseMimeType: "application/json" }
      });

      cleanupFile(imageFile.path);
      const text   = result.response?.text() || '';
      const parsed = safeJsonParse(text);

      if (parsed && typeof parsed.answer === 'string') {
        return res.json({
          answer:      removeMarkdown(parsed.answer),
          action:      normalizeAction(parsed.action),
          citations:   buildCitations(kbRows),
        });
      }
      return res.json({ answer: removeMarkdown(text) || 'Không thể phân tích ảnh này.', action: { type: 'none' }, citations: [] });
    } catch (err) {
      cleanupFile(imageFile?.path);
      return res.json({
        answer: 'Xin lỗi bạn, mình không thể xử lý hình ảnh này ạ. Bạn có thể hỏi mình bằng tin nhắn nhé!',
        action: { type: 'none' }, citations: [],
      });
    }
  }

  // ─── Xử lý text ───────────────────────────────────────────────────────────
  if (!userPrompt || userPrompt.trim().length === 0) {
    return res.status(400).json({ error: 'Câu hỏi không hợp lệ.' });
  }
  if (!model) {
    return res.status(500).json({ error: 'AI model chưa sẵn sàng.' });
  }

  try {
    const chat = model.startChat({
      history: sessionHistory,
      generationConfig: { 
        maxOutputTokens: 600,
        responseMimeType: "application/json" // Ép buộc Gemini xuất JSON chuẩn
      },
    });

    const result   = await chat.sendMessage(fullPrompt);
    const response = result.response;

    if (!response) {
      return res.status(500).json({ error: 'AI không thể tạo câu trả lời.' });
    }

    let text = response.text();
    if (!text || text.trim().length === 0) {
      return res.status(500).json({ error: 'AI trả về nội dung rỗng.' });
    }

    // Không parse removeMarkdown cho TỪNG JSON string (vì sẽ dễ break JSON parser)
    // Chỉ parse JSON trước, extract raw JSON ra
    const parsed = safeJsonParse(text);

    if (sessionId) {
      const newHistory = [
        ...sessionHistory,
        { role: 'user',  parts: [{ text: userPrompt }] },
        { role: 'model', parts: [{ text: text }] },
      ];
      saveSession(sessionId, newHistory);
    }

    // CHỈ CHẠY `removeMarkdown` sau khi ĐÃ parse ra field `answer`
    if (parsed && typeof parsed.answer === 'string') {
      const used      = Array.isArray(parsed.used_sources) ? parsed.used_sources : [];
      const citations = buildCitations(kbRows);
      return res.json({
        answer:      removeMarkdown(parsed.answer),
        action:      normalizeAction(parsed.action),
        used_sources: used,
        citations,
        _debug: { intent, rag_chunks: kbRows.length, session_turns: sessionHistory.length / 2 },
      });
    }

    // Fallback nếu JSON parse vẫn lỗi (mặc dù đã ép config JSON từ API)
    res.json({ answer: removeMarkdown(text), action: { type: 'none' }, citations: [] });

  } catch (err) {
    console.error('[ERROR] /ask:', err.message);
    res.status(500).json({ error: 'Đã xảy ra lỗi khi kết nối với AI.' });
  }
});

// Helper tạo citations array
function buildCitations(kbRows) {
  return (kbRows || []).map((r, idx) => ({
    id:          `S${idx + 1}`,
    document_id: r.document_id,
    chunk_id:    r.chunk_id,
    title:       r.title,
    source:      r.source,
    url:         r.url,
    excerpt:     r.content?.slice(0, 240) || '',
    similarity:  r.similarity,
    bm25_score:  r.bm25_score,
    hybrid_score: r.hybrid_score,
  }));
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORGOT PASSWORD FLOW
// ═══════════════════════════════════════════════════════════════════════════════

app.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email || !email.includes('@')) {
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
    const sentFrom    = new Sender(process.env.MAILERSEND_FROM_EMAIL, 'KLOO App');
    const recipients  = [new Recipient(normalizedEmail)];
    const emailParams = new EmailParams()
      .setFrom(sentFrom).setTo(recipients)
      .setSubject(`[KLOO] Mã OTP đặt lại mật khẩu: ${otp}`)
      .setHtml(htmlContent);
    await mailerSend.email.send(emailParams);
    res.json({ message: 'Mã OTP đã được gửi đến email của bạn.' });
  } catch (err) {
    console.error('[ERROR] MailerSend:', JSON.stringify(err?.body || err));
    res.status(500).json({ error: 'Không thể gửi email. Vui lòng thử lại.' });
  }
});

app.post('/verify-otp', (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) return res.status(400).json({ error: 'Thiếu email hoặc mã OTP.' });

  const normalizedEmail = email.toLowerCase().trim();
  const record          = otpStore.get(normalizedEmail);

  if (!record)                           return res.status(400).json({ error: 'Không tìm thấy yêu cầu OTP.' });
  if (Date.now() > record.expiresAt)   { otpStore.delete(normalizedEmail); return res.status(400).json({ error: 'Mã OTP đã hết hạn.' }); }
  if (record.otp !== otp.trim())         return res.status(400).json({ error: 'Mã OTP không đúng.' });

  const resetToken = crypto.randomBytes(32).toString('hex');
  record.verified  = true;
  record.resetToken = resetToken;
  record.resetTokenExpiresAt = Date.now() + 15 * 60 * 1000;
  otpStore.set(normalizedEmail, record);

  res.json({ message: 'Xác thực OTP thành công.', resetToken });
});

app.post('/reset-password', async (req, res) => {
  const { email, resetToken, newPassword } = req.body;
  if (!email || !resetToken || !newPassword) return res.status(400).json({ error: 'Dữ liệu không đầy đủ.' });
  if (newPassword.length < 6)                return res.status(400).json({ error: 'Mật khẩu phải có ít nhất 6 ký tự.' });

  const normalizedEmail = email.toLowerCase().trim();
  const record          = otpStore.get(normalizedEmail);

  if (!record || !record.verified)                       return res.status(400).json({ error: 'Phiên không hợp lệ.' });
  if (record.resetToken !== resetToken)                  return res.status(400).json({ error: 'Token không hợp lệ.' });
  if (Date.now() > record.resetTokenExpiresAt) { otpStore.delete(normalizedEmail); return res.status(400).json({ error: 'Phiên đã hết hạn.' }); }

  const { data: users, error: listError } = await supabaseAdmin.auth.admin.listUsers();
  if (listError) return res.status(500).json({ error: 'Lỗi kết nối server.' });

  const user = users.users.find(u => u.email?.toLowerCase() === normalizedEmail);
  if (!user) return res.status(404).json({ error: 'Không tìm thấy tài khoản.' });

  const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(user.id, { password: newPassword });
  if (updateError) {
    console.error('[ERROR] Supabase update password:', updateError);
    return res.status(500).json({ error: 'Không thể cập nhật mật khẩu.' });
  }

  otpStore.delete(normalizedEmail);
  res.json({ message: 'Mật khẩu đã được cập nhật thành công.' });
});

// ─── Audio endpoint (placeholder) ────────────────────────────────────────────
app.post('/ask/audio', upload.single('audio'), (req, res) => {
  cleanupFile(req.file?.path);
  res.json({ answer: 'Tính năng xử lý audio đang được phát triển. Vui lòng dùng nhận diện giọng nói để chuyển sang text nhé!' });
});

// ─── Health check ─────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  const cacheSize   = _embCache.size;
  const sessionSize = sessionStore.size;
  res.json({
    status:  'running',
    version: '2.0.0 (Phase 1+2+3)',
    rag:     'Hybrid BM25 + Vector (pgvector)',
    stats:   { embed_cache_entries: cacheSize, active_sessions: sessionSize },
  });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
app.listen(port, '0.0.0.0', () => {
  console.log(`\n🏸 KLOO Chatbot Backend v2.0 (Phase 1+2+3)`);
  console.log(`   ✅ Running at http://0.0.0.0:${port}`);
  console.log(`   ✅ RAG: Hybrid BM25 + Vector (pgvector)`);
  console.log(`   ✅ Embedding cache: TTL ${EMBED_CACHE_TTL / 60000} min, max ${EMBED_CACHE_MAX}`);
  console.log(`   ✅ Session history: max ${SESSION_MAX_TURNS} turns, TTL ${SESSION_TTL / 60000} min\n`);
});
