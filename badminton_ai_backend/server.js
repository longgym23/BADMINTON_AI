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
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs-extra');
const path = require('path');
const crypto = require('crypto');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { MailerSend, EmailParams, Sender, Recipient } = require('mailersend');
const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');

// ─── Firebase Admin Setup ─────────────────────────────────────────────────────
try {
  const serviceAccount = require('./firebase-service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('[FIREBASE] Admin SDK initialized successfully.');
} catch (error) {
  console.error('[ERROR] Failed to initialize Firebase Admin:', error);
}

// ─── MailerSend ───────────────────────────────────────────────────────────────
const mailerSend = new MailerSend({ apiKey: process.env.MAILERSEND_API_KEY });

// ─── Supabase Admin Client ────────────────────────────────────────────────────
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

// ─── OTP — dùng Supabase thay vì in-memory để tồn tại sau khi restart server ─
// Bảng: otp_verifications (email PK, otp, expires_at, verified, reset_token, reset_token_expires_at)

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
  genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  visionModel = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  const embeddingModelName = process.env.GEMINI_EMBEDDING_MODEL || 'gemini-embedding-2-preview';
  embedModel = genAI.getGenerativeModel({ model: embeddingModelName });
  console.log(`[INFO] Gemini models loaded. Embedding: ${embeddingModelName}`);
} catch (err) {
  console.error('[ERROR] Khởi tạo Gemini thất bại:', err.message);
}

// ─── System Prompt ────────────────────────────────────────────────────────────
const SYSTEM_PROMPT =
  `Bạn là trợ lý AI thông minh của Hệ thống quản lý đặt sân thể thao 'KLOO'.
Nhiệm vụ của bạn là giải đáp thắc mắc về hệ thống đặt sân, nội quy, chính sách, giá cả sân bãi và kiến thức thể thao.
ĐẶC BIỆT LƯU Ý:
1. CHÍNH SÁCH HỦY SÂN MỚI (ƯU TIÊN TUYỆT ĐỐI GHI ĐÈ KẾT QUẢ TỪ NGUỒN):
   - Hủy trước 2 tiếng so với giờ chơi: Hoàn tiền 100% vào Số Dư Ví.
   - Hủy trong vòng 2 tiếng trước giờ chơi: Hoàn tiền 50% vào Số Dư Ví.
   - Đã tới hoặc quá giờ chơi: Cấm hủy, KHÔNG hoàn tiền.
2. Chỉ dựa vào kiến thức cung cấp trong phần SOURCES để trả lời nội quy, giá cả. Nếu đọc hóa đơn chụp màn hình, hãy kết hợp với dữ liệu USER_CONTEXT để xác nhận giao dịch.
3. Chuyên môn của bạn bao gồm 4 bộ môn: CẦU LÔNG, PICKLEBALL, BÓNG ĐÁ, TENNIS.
   Với câu hỏi về kiến thức thể thao (cách chơi, luật, dụng cụ vợt, bóng, giày...), HÃY TỰ DO SỬ DỤNG KIẾN THỨC CỦA LLM để tư vấn thật chi tiết, nhiệt tình và đúng chuyên môn. KHÔNG phụ thuộc vào SOURCES đối với kiến thức thể thao chung.
   Hãy từ chối trả lời lịch sự nếu ảnh/câu hỏi hoàn toàn không liên quan đến 4 bộ môn trên.
4. LUÔN LUÔN PHẢI CÓ VĂN BẢN TRONG TRƯỜNG "answer". Kể cả khi bạn đã chọn được "action", bạn VẪN BẮT BUỘC phải viết nội dung tư vấn, trả lời vào "answer". KHÔNG sử dụng Markdown (như *, **, #) trong answer.
5. Tự động nhận diện Action mà người dùng có ý định muốn thực hiện:
   - "search_courts": Khi user tìm sân, hỏi giá, đặt sân.
   - "view_schedule": Xem lịch đã đặt, check lịch.
   - "cancel_booking": Khi user MUỐN THỰC SỰ HỦY SÂN (ví dụ: "tôi muốn hủy sân", "hủy lịch đặt của tôi"). KHÔNG dùng action này khi user chỉ HỎI VỀ CHÍNH SÁCH/QUY ĐỊNH hủy sân.
   - "view_expense": Xem số dư ví, nạp tiền.
   - "none": Hỏi đáp thông thường, tư vấn dụng cụ, hỏi về chính sách/quy định hủy sân.`;

// ═══════════════════════════════════════════════════════════════════════════════
// PHASE 1 — EMBEDDING CACHE (TTL 5 phút, max 300 entries)
// ═══════════════════════════════════════════════════════════════════════════════
const _embCache = new Map();
const EMBED_CACHE_TTL = 5 * 60 * 1000;
const EMBED_CACHE_MAX = 300;

async function embedText(text) {
  if (!embedModel) throw new Error('Embedding model chưa sẵn sàng.');
  const cacheKey = text.slice(0, 250);
  const cached = _embCache.get(cacheKey);
  if (cached && Date.now() < cached.expireAt) return cached.vec;

  const res = await embedModel.embedContent({ content: { parts: [{ text }], role: 'user' }, outputDimensionality: 1536 });
  const v = res?.embedding?.values || res?.embedding?.value || res?.embedding || res?.data?.[0]?.embedding;
  if (!Array.isArray(v)) throw new Error('Embedding API trả về dữ liệu không hợp lệ.');

  if (_embCache.size >= EMBED_CACHE_MAX) _embCache.delete(_embCache.keys().next().value);
  _embCache.set(cacheKey, { vec: v, expireAt: Date.now() + EMBED_CACHE_TTL });
  return v;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Phase 2 — Quick Intent Pre-routing
// ═══════════════════════════════════════════════════════════════════════════════
function quickIntent(prompt) {
  if (!prompt || typeof prompt !== 'string') return 'general';
  const p = prompt.toLowerCase().trim();
  if (/^(xin chào|chào|hi\b|hello|hey|alo|cảm ơn|thanks|thank you)/.test(p)) return 'greeting';
  if (/^(ok|oke|okay|được|rồi|vâng|dạ|ừ|uhm)$/.test(p)) return 'greeting';
  // Ưu tiên kiểm tra: hỏi về CHÍNH SÁCH/QUY ĐỊNH hủy trước → general (để AI giải thích chính sách)
  if (/(chính sách|quy định|quy trình|điều kiện|điều khoản|như thế nào|ra sao|thế nào|hoàn tiền|phí|mấy|bao lâu).*(hủy|cancel)/i.test(p)) return 'general';
  if (/(hủy|cancel).*(chính sách|quy định|quy trình|điều kiện|điều khoản|như thế nào|ra sao|thế nào|hoàn tiền)/i.test(p)) return 'general';
  // Chỉ gán cancel_booking khi user MUỐN THỰC SỰ HỦY (có ngôi thứ nhất / hành động cụ thể)
  if (/(tôi muốn hủy|cho tôi hủy|giúp tôi hủy|hủy giúp|hủy lịch của tôi|hủy đặt sân|hủy booking|cancel booking|cancel lịch)/i.test(p)) return 'cancel_booking';
  if (/(giá|bao nhiêu|tiền|phí|cost|giờ|price)/.test(p)) return 'pricing';
  if (/(tìm|đặt|sân nào|có sân|book|search)/.test(p)) return 'search';
  if (/(lịch|schedule|booking|đã đặt|sắp tới)/.test(p)) return 'schedule';
  return 'general';
}

// ═══════════════════════════════════════════════════════════════════════════════
// Phase 2 — Multi-turn Session Stores
// ═══════════════════════════════════════════════════════════════════════════════
const sessionStore = new Map();
const SESSION_MAX_TURNS = 6;
const SESSION_TTL = 30 * 60 * 1000;
const _sessionTTLMap = new Map();

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
  sessionStore.set(sessionId, history.slice(-SESSION_MAX_TURNS));
  _sessionTTLMap.set(sessionId, Date.now() + SESSION_TTL);
  if (sessionStore.size > 500) sessionStore.delete(sessionStore.keys().next().value);
}

// ═══════════════════════════════════════════════════════════════════════════════
// Phase 3 — Hybrid Retrieval
// ═══════════════════════════════════════════════════════════════════════════════
async function retrieveKnowledge(userPrompt, intentHint = 'general') {
  if (!supabaseAdmin || !userPrompt) return [];
  try {
    const queryEmbedding = await embedText(userPrompt);
    let vectorWeight = 0.6;
    let bm25Weight = 0.4;
    // Tăng trọng số bám keyword nếu người dùng hỏi về thanh toán hóa đơn / mã lịch cụ thể (Từ Two-Pass image keywords)
    if (intentHint === 'cancel_booking' || intentHint === 'schedule') {
      vectorWeight = 0.5; bm25Weight = 0.5;
    }

    const { data, error } = await supabaseAdmin.rpc('match_kb_hybrid', {
      query_text: userPrompt,
      query_embedding: queryEmbedding,
      match_count: 6,
      vector_weight: vectorWeight,
      bm25_weight: bm25Weight,
      similarity_threshold: 0.45,
    });
    if (error) { console.error('[RAG] Hybrid retrieve error:', error.message); return []; }
    return Array.isArray(data) ? data : [];
  } catch (e) {
    console.error('[RAG] Hybrid exception:', e.message); return [];
  }
}

// ─── User Context ─────────────────────────────────────────────────────────────
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
      .limit(5); // Nhìn sâu lịch sử để AI thấy được hóa đơn đặt sân (nếu bị dời ngày/sắp tới dài)

    let context = 'USER_CONTEXT:\n';
    if (!bookings || bookings.length === 0) {
      context += '- Lịch đặt sắp tới: Không có\n';
    } else {
      context += '- Lịch đặt 5 lượt sắp tới: ';
      bookings.forEach(b => context += `${b.booking_date} lúc ${b.time_slot}h tại ${b.court_name} (${b.status}). `);
      context += '\n';
    }
    return context;
  } catch (e) {
    console.error('[RAG] getUserContext error:', e.message); return '';
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
function buildSourcesBlock(rows) {
  if (!rows || rows.length === 0) return '';
  const lines = rows.map((r, idx) => `S${idx + 1} | ${r.source || r.title || 'KB'} | ${String(r.content || '').replace(/\s+/g, ' ').trim()}`);
  return `SOURCES:\n${lines.join('\n')}\n`;
}

function removeMarkdown(text) {
  if (!text || typeof text !== 'string') return text;
  return text.replace(/\*\*/g, '').replace(/\*/g, '').replace(/#{1,6}\s/g, '').replace(/`/g, '').replace(/~~/g, '').replace(/\[([^\]]+)\]\([^)]+\)/g, '$1').trim();
}

function safeJsonParse(text) {
  if (!text || typeof text !== 'string') return null;
  const match = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  let cleanText = match ? match[1] : text;
  const start = cleanText.indexOf('{');
  const end = cleanText.lastIndexOf('}');
  if (start >= 0 && end > start) cleanText = cleanText.slice(start, end + 1);
  try { return JSON.parse(cleanText); } catch (_) { return null; }
}

function normalizeAction(action) {
  const a = action && typeof action === 'object' ? action : {};
  const type = typeof a.type === 'string' ? a.type : 'none';
  const allowed = new Set(['search_courts', 'view_schedule', 'view_expense', 'cancel_booking', 'none']);
  if (!allowed.has(type)) return { type: 'none' };
  const out = { type };
  // Bổ sung các môn thể thao
  if (type === 'search_courts' && typeof a.sport === 'string') out.sport = a.sport;
  return out;
}

const cleanupFile = (filePath) => {
  if (filePath && fs.existsSync(filePath)) fs.unlink(filePath).catch(err => console.error('[WARN] Lỗi xóa file tạm:', err));
};

// ─── Haversine Distance (km) ──────────────────────────────────────────────────
function haversineKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2
    + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ─── Nearby Courts from Supabase (theo bán kính km) ──────────────────────────
async function getNearbyCourts(userLat, userLng, radiusKm = 5, sportType = null) {
  if (!supabaseAdmin || userLat == null || userLng == null) return [];
  try {
    let query = supabaseAdmin
      .from('courts')
      .select('id, name, address, latitude, longitude, price_per_hour, sport_type, image_url, rating, total_reviews');
    if (sportType) query = query.eq('sport_type', sportType);
    const { data, error } = await query.limit(200);
    if (error || !data) return [];

    return data
      .map(c => ({
        ...c,
        distance_km: (c.latitude && c.longitude)
          ? haversineKm(userLat, userLng, c.latitude, c.longitude)
          : 9999,
      }))
      .filter(c => c.distance_km <= radiusKm)
      .sort((a, b) => a.distance_km - b.distance_km)
      .slice(0, 10); // trả về tối đa 10 sân gần nhất
  } catch (e) {
    console.error('[NEARBY] Error:', e.message); return [];
  }
}

// ─── Detect Nearby Query & Radius ────────────────────────────────────────────
function isNearbyQuery(prompt) {
  const p = (prompt || '').toLowerCase();
  return /(gần tôi|gần đây|xung quanh|quanh đây|nearby|trong bán kính|trong vòng|cách đây|gần nhà|khu vực này)/.test(p);
}

function extractRadiusKm(prompt) {
  const m = (prompt || '').match(/(\d+(?:\.\d+)?)\s*km/i);
  return m ? parseFloat(m[1]) : null;
}



// ─── Express App ──────────────────────────────────────────────────────────────
const app = express();
const port = process.env.PORT || 3000;
app.use(cors());
app.use(express.json());

// ═══════════════════════════════════════════════════════════════════════════════
// POST /ask — Chatbot Endpoint (KLOO AI)
// ═══════════════════════════════════════════════════════════════════════════════
app.post('/ask', upload.single('image'), async (req, res) => {
  const imageFile = req.file;
  const userId = req.body.user_id || '';
  const sessionId = req.body.session_id || userId || null;
  const userPrompt = req.body.prompt || (imageFile ? 'Trợ giúp tôi với bức ảnh này.' : '');
  // ─── Vị trí GPS của user (tùy chọn) ───
  const userLat = req.body.user_lat != null ? parseFloat(req.body.user_lat) : null;
  const userLng = req.body.user_lng != null ? parseFloat(req.body.user_lng) : null;

  const intent = quickIntent(userPrompt);
  const needsRAG = !['greeting'].includes(intent);

  // ────────────────────────────────────────────────────────────────────────────
  // NHỊP 1: Tách từ khóa bằng Vision (Two-pass RAG) nếu có ảnh
  // ────────────────────────────────────────────────────────────────────────────
  let queryText = userPrompt;
  let base64Image = null;
  let safeMime = null;

  if (imageFile) {
    try {
      const imageData = await fs.readFile(imageFile.path);
      base64Image = imageData.toString('base64');
      safeMime = imageFile.mimetype || 'image/jpeg';
      if (safeMime === 'image/jpg') safeMime = 'image/jpeg';
      if (!['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'].includes(safeMime)) {
        safeMime = 'image/jpeg';
      }

      if (needsRAG && visionModel) {
        // Gọi LLM cực lẹ không ghi nhớ lịch sử, chỉ lấy 1 câu keyword
        const extractResult = await visionModel.generateContent({
          contents: [{
            role: 'user',
            parts: [
              { text: "Nhiệm vụ: Tìm danh từ riêng, thương hiệu, mã ID, loại sân (Bóng đá, Cầu lông, Pickleball, Tennis), hoặc số tiền có trong ảnh. Trả lời đúng từ khóa, không giải thích dài dòng." },
              { inlineData: { data: base64Image, mimeType: safeMime } }
            ]
          }]
        });
        const extractedKeywords = extractResult.response?.text() || '';
        queryText = userPrompt + " " + extractedKeywords.replace(/\n|`/g, ' ').trim();
        console.log('[🚀 TWO-PASS RAG] Nhịp 1 Extracted:', extractedKeywords);
      }
    } catch (e) {
      console.error('[WARN] Lỗi Nhịp 1 Vision bóc tách từ khóa:', e.message);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // RAG RETRIEVAL & DB CONTEXT (Gộp chung Query Text Đã Bóc Tách)
  // ────────────────────────────────────────────────────────────────────────────
  const [kbRows, userContext, nearbyCourts] = await Promise.all([
    needsRAG ? retrieveKnowledge(queryText, intent) : Promise.resolve([]),
    getUserContext(userId),
    // Tìm sân theo vị trí nếu có GPS và câu hỏi liên quan đến tìm sân gần
    (userLat != null && userLng != null && (intent === 'search' || isNearbyQuery(userPrompt)))
      ? getNearbyCourts(userLat, userLng, extractRadiusKm(userPrompt) || 5)
      : Promise.resolve([]),
  ]);

  const sourcesBlock = buildSourcesBlock(kbRows);
  const sessionHistory = getSession(sessionId);

  // Block vị trí (thêm vào prompt nếu có GPS)
  let locationBlock = '';
  if (userLat != null && userLng != null) {
    const radius = extractRadiusKm(userPrompt) || 5;
    if (nearbyCourts.length > 0) {
      const courtLines = nearbyCourts.map(c =>
        `- ${c.name} (${c.distance_km.toFixed(1)}km) | ${c.address} | ${c.sport_type || ''} | ${c.price_per_hour || '?'}d/h | rating: ${c.rating || 'N/A'}`
      ).join('\n');
      locationBlock = `USER_LOCATION: lat=${userLat.toFixed(5)}, lng=${userLng.toFixed(5)}\n`
        + `CÁC SÂN TRONG BÁN KÍNH ${radius}km (sắp xếp theo khoảng cách gần nhất):\n${courtLines}\n`
        + `HÃY DÙNG DŨ LIỆU TRÊN ĐÊ TRẢ LỜI CHÍNH XÁC VỀ SÂN GẦN USER.\n`;
    } else {
      locationBlock = `USER_LOCATION: lat=${userLat.toFixed(5)}, lng=${userLng.toFixed(5)}\n`
        + `Không tìm thấy sân nào trong bán kính ${radius}km.\n`;
    }
  }

  const fullPrompt =
    `${SYSTEM_PROMPT}\n\n` +
    `Cấu trúc JSON bắt buộc:\n` +
    `{\n` +
    `  "answer": "Câu trả lời của bạn, bỏ qua các dấu * tạo in đậm",\n` +
    `  "action": { "type": "search_courts|view_schedule|view_expense|cancel_booking|none", "sport": "badminton|football|tennis|pickleball" },\n` +
    `  "used_sources": ["S1","S2"]\n` +
    `}\n\n` +
    `${sourcesBlock}\n` +
    `${userContext}\n` +
    `${locationBlock}\n` +
    `NHẮC NHỞ QUAN TRỌNG: Nếu ảnh KHÔNG liên quan đến 4 bộ môn thể thao trên, HÃY giữ phép lịch sự và chối từ dễ thương. \n\n` +
    `USER_ASK: ${userPrompt}`;


  // ────────────────────────────────────────────────────────────────────────────
  // NHỊP 2: Chốt câu trả lời cuối với Full Prompt + Image
  // ────────────────────────────────────────────────────────────────────────────
  if (imageFile) {
    if (!visionModel) {
      cleanupFile(imageFile.path);
      return res.status(500).json({ error: 'Vision model chưa sẵn sàng.' });
    }
    try {
      const result = await visionModel.generateContent({
        contents: [{
          role: 'user',
          parts: [
            { text: fullPrompt },
            { inlineData: { data: base64Image, mimeType: safeMime } }
          ]
        }],
        generationConfig: { responseMimeType: "application/json" }
      });

      cleanupFile(imageFile.path);
      const text = result.response?.text() || '';
      const parsed = safeJsonParse(text);

      if (parsed && typeof parsed.answer === 'string') {
        if (sessionId) { // Lưu lại bộ nhớ Multi-turn để hội thoại lần sau trơn tru
          saveSession(sessionId, [...sessionHistory, { role: 'user', parts: [{ text: userPrompt }] }, { role: 'model', parts: [{ text: JSON.stringify(parsed) }] }]);
        }
        return res.json({
          answer: removeMarkdown(parsed.answer),
          action: normalizeAction(parsed.action),
          citations: buildCitations(kbRows),
          nearby_courts: nearbyCourts,
          _debug: { two_pass_keywords: queryText.replace(userPrompt, '').trim() }
        });

      }
      return res.json({ answer: removeMarkdown(text), action: { type: 'none' }, citations: [] });
    } catch (err) {
      console.error('[ERROR] Lỗi Vision API Nhịp 2:', err);
      cleanupFile(imageFile?.path);
      return res.json({
        answer: `(Lỗi Backend: ${err.message}) Xin lỗi bạn, mình không thể xử lý hình ảnh này ạ.`,
        action: { type: 'none' }, citations: [],
      });
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Xử lý nếu là Text đơn thuần
  // ────────────────────────────────────────────────────────────────────────────
  if (!userPrompt || userPrompt.trim().length === 0) {
    return res.status(400).json({ error: 'Câu hỏi không hợp lệ.' });
  }

  try {
    const chat = model.startChat({
      history: sessionHistory,
      generationConfig: {
        maxOutputTokens: 600,
        responseMimeType: "application/json"
      },
    });

    const result = await chat.sendMessage(fullPrompt);
    const text = result.response?.text() || '';
    if (!text || text.trim().length === 0) return res.status(500).json({ error: 'AI trả về nội dung rỗng.' });

    const parsed = safeJsonParse(text);

    if (sessionId) {
      saveSession(sessionId, [...sessionHistory, { role: 'user', parts: [{ text: userPrompt }] }, { role: 'model', parts: [{ text: text }] }]);
    }

    if (parsed && typeof parsed.answer === 'string') {
      const used = Array.isArray(parsed.used_sources) ? parsed.used_sources : [];
      return res.json({
        answer: removeMarkdown(parsed.answer),
        action: normalizeAction(parsed.action),
        used_sources: used,
        citations: buildCitations(kbRows),
        nearby_courts: nearbyCourts,
      });
    }

    res.json({ answer: removeMarkdown(text), action: { type: 'none' }, citations: [] });
  } catch (err) {
    console.error('[ERROR] /ask text:', err.message);
    res.status(500).json({ error: 'Lỗi khi gọi API.' });
  }
});

// Helper tạo citations array
function buildCitations(kbRows) {
  return (kbRows || []).map((r, idx) => ({
    id: `S${idx + 1}`,
    document_id: r.document_id,
    chunk_id: r.chunk_id,
    title: r.title,
    source: r.source,
    url: r.url,
    excerpt: r.content?.slice(0, 240) || '',
    similarity: r.similarity,
    bm25_score: r.bm25_score,
    hybrid_score: r.hybrid_score,
  }));
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORGOT PASSWORD FLOW  (OTP lưu trong Supabase — tồn tại sau restart server)
// ═══════════════════════════════════════════════════════════════════════════════

app.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email || !email.includes('@')) {
    return res.status(400).json({ error: 'Email không hợp lệ.' });
  }
  const normalizedEmail = email.toLowerCase().trim();

  // Kiểm tra email tồn tại trong Supabase Auth
  const { data: users, error: fetchError } = await supabaseAdmin.auth.admin.listUsers();
  if (fetchError) return res.status(500).json({ error: 'Lỗi kết nối server.' });
  const userExists = users.users.some(u => u.email?.toLowerCase() === normalizedEmail);
  if (!userExists) {
    // Không lộ thông tin email có tồn tại hay không (bảo mật)
    return res.json({ message: 'Nếu email tồn tại, bạn sẽ nhận được mã OTP.' });
  }

  const otp = crypto.randomInt(100000, 999999).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString(); // 10 phút

  // Upsert OTP vào Supabase (ghi đè nếu email đã có OTP cũ)
  const { error: upsertError } = await supabaseAdmin
    .from('otp_verifications')
    .upsert({
      email: normalizedEmail,
      otp,
      expires_at: expiresAt,
      verified: false,
      reset_token: null,
      reset_token_expires_at: null,
    }, { onConflict: 'email' });

  if (upsertError) {
    console.error('[OTP] Upsert error:', upsertError.message);
    return res.status(500).json({ error: 'Không thể tạo mã OTP. Vui lòng thử lại.' });
  }

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

app.post('/verify-otp', async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) return res.status(400).json({ error: 'Thiếu email hoặc mã OTP.' });

  const normalizedEmail = email.toLowerCase().trim();

  // Đọc record từ Supabase
  const { data: record, error } = await supabaseAdmin
    .from('otp_verifications')
    .select('*')
    .eq('email', normalizedEmail)
    .single();

  if (error || !record) return res.status(400).json({ error: 'Không tìm thấy yêu cầu OTP.' });
  if (new Date(record.expires_at) < new Date()) {
    // Xóa record hết hạn
    await supabaseAdmin.from('otp_verifications').delete().eq('email', normalizedEmail);
    return res.status(400).json({ error: 'Mã OTP đã hết hạn.' });
  }
  if (record.otp !== otp.trim()) return res.status(400).json({ error: 'Mã OTP không đúng.' });

  const resetToken = crypto.randomBytes(32).toString('hex');
  const resetTokenExpiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString(); // 15 phút

  // Cập nhật trạng thái verified + reset token
  const { error: updateError } = await supabaseAdmin
    .from('otp_verifications')
    .update({
      verified: true,
      reset_token: resetToken,
      reset_token_expires_at: resetTokenExpiresAt,
    })
    .eq('email', normalizedEmail);

  if (updateError) {
    console.error('[OTP] Update verified error:', updateError.message);
    return res.status(500).json({ error: 'Lỗi server khi xác thực OTP.' });
  }

  res.json({ message: 'Xác thực OTP thành công.', resetToken });
});

app.post('/reset-password', async (req, res) => {
  const { email, resetToken, newPassword } = req.body;
  if (!email || !resetToken || !newPassword)
    return res.status(400).json({ error: 'Dữ liệu không đầy đủ.' });
  if (newPassword.length < 6)
    return res.status(400).json({ error: 'Mật khẩu phải có ít nhất 6 ký tự.' });

  const normalizedEmail = email.toLowerCase().trim();

  // Đọc record từ Supabase
  const { data: record, error } = await supabaseAdmin
    .from('otp_verifications')
    .select('*')
    .eq('email', normalizedEmail)
    .single();

  if (error || !record || !record.verified)
    return res.status(400).json({ error: 'Phiên không hợp lệ.' });
  if (record.reset_token !== resetToken)
    return res.status(400).json({ error: 'Token không hợp lệ.' });
  if (new Date(record.reset_token_expires_at) < new Date()) {
    await supabaseAdmin.from('otp_verifications').delete().eq('email', normalizedEmail);
    return res.status(400).json({ error: 'Phiên đã hết hạn. Vui lòng yêu cầu lại.' });
  }

  // Tìm user ID từ Auth
  const { data: users, error: listError } = await supabaseAdmin.auth.admin.listUsers();
  if (listError) return res.status(500).json({ error: 'Lỗi kết nối server.' });

  const user = users.users.find(u => u.email?.toLowerCase() === normalizedEmail);
  if (!user) return res.status(404).json({ error: 'Không tìm thấy tài khoản.' });

  // Đổi mật khẩu qua Supabase Admin
  const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
    user.id, { password: newPassword },
  );
  if (updateError) {
    console.error('[ERROR] Supabase update password:', updateError);
    return res.status(500).json({ error: 'Không thể cập nhật mật khẩu.' });
  }

  // Xóa OTP record sau khi reset thành công
  await supabaseAdmin.from('otp_verifications').delete().eq('email', normalizedEmail);

  res.json({ message: 'Mật khẩu đã được cập nhật thành công.' });
});

// ─── Audio endpoint (placeholder) ────────────────────────────────────────────

app.post('/ask/audio', upload.single('audio'), (req, res) => {
  cleanupFile(req.file?.path);
  res.json({ answer: 'Tính năng xử lý audio đang được phát triển. Vui lòng dùng nhận diện giọng nói để chuyển sang text nhé!' });
});

// ─── Health check ─────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  const cacheSize = _embCache.size;
  const sessionSize = sessionStore.size;
  res.json({
    status: 'running',
    version: '2.0.0 (Phase 1+2+3)',
    rag: 'Hybrid BM25 + Vector (pgvector)',
    stats: { embed_cache_entries: cacheSize, active_sessions: sessionSize },
  });
});

// ─── Push Notification Endpoint ────────────────────────────────────────────────
app.post('/api/send-notification', express.json(), async (req, res) => {
  const { receiver_id, title, body, data } = req.body;
  if (!receiver_id || !title || !body) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    // Lấy FCM token từ bảng users hoặc profiles
    let { data: userData, error } = await supabaseAdmin
      .from('profiles')
      .select('fcm_token')
      .eq('id', receiver_id)
      .single();

    if (error || !userData?.fcm_token) {
      // Fallback: Thử bảng users
      const { data: userData2 } = await supabaseAdmin
        .from('users')
        .select('fcm_token')
        .eq('id', receiver_id)
        .single();

      if (!userData2 || !userData2.fcm_token) {
        return res.status(404).json({ error: 'User FCM token not found' });
      }
      userData = userData2;
    }

    const message = {
      notification: { title, body },
      data: data || { type: 'general' },
      token: userData.fcm_token,
    };

    const response = await admin.messaging().send(message);
    res.json({ success: true, messageId: response });

  } catch (error) {
    console.error('[FCM] Send error:', error.code, error.message);

    // FIX #7: Token hết hạn → tự động xóa khỏi Supabase để tránh lỗi lặp lại
    if (
      error.code === 'messaging/registration-token-not-registered' ||
      error.code === 'messaging/invalid-registration-token'
    ) {
      console.warn(`[FCM] Stale token detected for receiver_id=${req.body.receiver_id} — clearing from DB`);
      try {
        await supabaseAdmin
          .from('profiles')
          .update({ fcm_token: null })
          .eq('id', req.body.receiver_id);
      } catch (dbErr) {
        console.error('[FCM] Failed to clear stale token:', dbErr.message);
      }
      return res.status(410).json({ error: 'FCM token expired and has been cleared' });
    }

    res.status(500).json({ error: error.message });
  }
});
// ─── SePay Webhook Endpoint ─────────────────────────────────────────────────────────────
app.post('/api/sepay-webhook', express.json(), async (req, res) => {
  try {
    const { transferAmount, transferType, content, referenceCode } = req.body;
    
    // 1. Kiểm tra phải là tiền vào (in) không
    if (transferType !== 'in') {
      return res.status(200).json({ success: true, message: 'Bỏ qua giao dịch tiền ra' });
    }

    if (!content) {
      return res.status(200).json({ success: true, message: 'Không có nội dung chuyển khoản' });
    }

    const contentUpper = content.toUpperCase();

    // 2. Xử lý thanh toán ĐẶT SÂN
    if (contentUpper.includes('DATSAN')) {
      const match = contentUpper.match(/DATSAN\s*([A-Z0-9-]+)/);
      if (match && match[1]) {
        let bookingRef = match[1].replace(/-/g, ''); // Xóa gạch ngang nếu có
        
        // Thử format có dấu gạch dưới (do hệ thống cũ có thể lưu kiểu này)
        const refWithUnderscore = bookingRef.length > 5
          ? `${bookingRef.substring(0, 5)}_${bookingRef.substring(5)}`
          : bookingRef;
        
        // Cập nhật trạng thái booking thành PAID
        const { data, error } = await supabaseAdmin
          .from('bookings')
          .update({ status: 'PAID', transaction_id: referenceCode })
          .or(`transaction_id.eq.${bookingRef},transaction_id.eq.${refWithUnderscore}`)
          .select();
        
        if (error) throw error;
        
        if (data && data.length > 0) {
          console.log(`[Webhook] Đã xác nhận ĐẶT SÂN: ${bookingRef}`);
          return res.status(200).json({ success: true, message: 'Xác nhận đặt sân thành công' });
        } else {
          return res.status(200).json({ success: false, message: 'Không tìm thấy Booking ID' });
        }
      }
    }

    // 3. Xử lý NẠP TIỀN VÀO VÍ
    if (contentUpper.includes('NAPTIEN')) {
      const match = contentUpper.match(/NAPTIEN\s*([A-Z0-9-]+)/);
      if (match && match[1]) {
        // userIdShort lúc này là chuỗi 32 ký tự (đã bị bỏ dấu gạch ngang ở app)
        const str = match[1].replace(/-/g, '').toLowerCase();
        
        if (str.length >= 32) {
          // Khôi phục lại định dạng UUID chuẩn (có dấu gạch ngang)
          const fullUserId = `${str.slice(0,8)}-${str.slice(8,12)}-${str.slice(12,16)}-${str.slice(16,20)}-${str.slice(20,32)}`;
          
          // Kiểm tra xem user có tồn tại không
          const { data: users, error: userError } = await supabaseAdmin
            .from('profiles')
            .select('id')
            .eq('id', fullUserId);
            
          if (users && users.length > 0) {
            // Không cần tìm PENDING nữa, ghi thẳng SUCCESS
            const { error: insertError } = await supabaseAdmin
              .from('wallet_transactions')
              .insert({
                user_id: fullUserId,
                amount: transferAmount,
                type: 'TOPUP',
                status: 'SUCCESS',
                reference_id: referenceCode,
                description: 'Nạp tiền tự động qua VietQR'
              });
              
            if (insertError) throw insertError;
            console.log(`[Webhook] Đã nạp tiền cho user ${fullUserId}: ${transferAmount}đ`);
            return res.status(200).json({ success: true, message: 'Nạp tiền thành công' });
          } else {
            console.error(`[Webhook] Không tìm thấy user với mã UUID: ${fullUserId}`);
            return res.status(200).json({ success: false, message: 'Không tìm thấy user' });
          }
        } else {
           console.error(`[Webhook] Chuỗi NAPTIEN không đủ 32 ký tự: ${str}`);
           return res.status(200).json({ success: false, message: 'Sai định dạng User ID' });
        }
      }
    }

    // Giao dịch không nằm trong kịch bản của app
    return res.status(200).json({ success: true, message: 'Giao dịch không khớp cú pháp hệ thống' });

  } catch (error) {
    console.error('[Webhook] Lỗi xử lý SePay Webhook:', error);
    // Vẫn trả về 200 để SePay không gửi lại nhiều lần nếu lỗi do data
    return res.status(200).json({ success: false, error: 'Internal Server Error' });
  }
});


// ─── Start Server ─────────────────────────────────────────────────────────────
app.listen(port, '0.0.0.0', () => {
  console.log(`\n KLOO Chatbot Backend v2.0 (Phase 1+2+3)`);
  console.log(`  Running at http://0.0.0.0:${port}`);
  console.log(`  RAG: Hybrid BM25 + Vector (pgvector)`);
  console.log(`  Embedding cache: TTL ${EMBED_CACHE_TTL / 60000} min, max ${EMBED_CACHE_MAX}`);
  console.log(`  Session history: max ${SESSION_MAX_TURNS} turns, TTL ${SESSION_TTL / 60000} min\n`);
});
