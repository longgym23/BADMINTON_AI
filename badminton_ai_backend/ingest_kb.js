
require('dotenv').config();
const fs = require('fs-extra');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// ─── Validate Environment ────────────────────────────────────────────────────
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('[ERROR] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
  process.exit(1);
}
if (!GEMINI_API_KEY || GEMINI_API_KEY === 'YOUR_API_KEY_HERE') {
  console.error('[ERROR] Missing GEMINI_API_KEY in .env');
  process.exit(1);
}

// ─── Clients ─────────────────────────────────────────────────────────────────
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
const embeddingModelName = process.env.GEMINI_EMBEDDING_MODEL || 'gemini-embedding-2-preview';
const embedModel = genAI.getGenerativeModel({ model: embeddingModelName });

// ─── Argument Parser ─────────────────────────────────────────────────────────
function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (!next || next.startsWith('--')) args[key] = true;
      else { args[key] = next; i++; }
    }
  }
  return args;
}

// ─── Phase 1: Markdown-Aware Chunking ────────────────────────────────────────
/**
 * Cắt text thành chunks theo đoạn văn/heading.
 * Ưu tiên cắt tại ranh giới tự nhiên (heading, đoạn trống) thay vì cắt cứng.
 *
 * @param {string} text - Nội dung cần chunk
 * @param {object} opts
 * @param {number} opts.chunkSize  - Giới hạn ký tự mỗi chunk (default: 1200)
 * @param {number} opts.overlapWords - Số từ overlap giữa 2 chunk liên tiếp (default: 30)
 */
function chunkText(text, { chunkSize = 1200, overlapWords = 30 } = {}) {
  const cleaned = text.replace(/\r\n/g, '\n').trim();
  if (!cleaned) return [];

  // Tách thành các section tự nhiên:
  // - Theo Markdown heading: # ## ###
  // - Theo đoạn trống đôi (\n\n)
  const rawSections = cleaned.split(/\n(?=#{1,3}\s)|\n{2,}/);
  const sections = rawSections.map(s => s.trim()).filter(Boolean);

  const chunks = [];
  let buffer = '';

  for (const section of sections) {
    const candidate = buffer ? buffer + '\n\n' + section : section;

    if (candidate.length > chunkSize && buffer.trim()) {
      // Lưu buffer hiện tại thành 1 chunk
      chunks.push(buffer.trim());

      // Tạo overlap: giữ N từ cuối của buffer
      const words = buffer.split(/\s+/);
      const overlapText = words.slice(-overlapWords).join(' ');

      // Buffer mới = overlap + section mới
      buffer = overlapText ? overlapText + '\n' + section : section;
    } else {
      buffer = candidate;
    }
  }

  // Đẩy phần còn lại
  if (buffer.trim()) chunks.push(buffer.trim());

  // Fallback: nếu vẫn không có gì (text rất ngắn)
  return chunks.length ? chunks : [cleaned];
}

// ─── Embedding ────────────────────────────────────────────────────────────────
async function embedText(text) {
  const res = await embedModel.embedContent({
    content: { parts: [{ text }], role: 'user' },
    outputDimensionality: 1536,
  });
  const v =
    res?.embedding?.values ||
    res?.embedding?.value ||
    res?.embedding ||
    res?.data?.[0]?.embedding;
  if (!Array.isArray(v)) throw new Error('Embedding API trả về dữ liệu không hợp lệ.');
  return v;
}

// ─── Upsert: Delete old doc by title before inserting ────────────────────────
async function deleteDocByTitle(title) {
  const { data: docs } = await supabase
    .from('kb_documents')
    .select('id')
    .eq('title', title);

  if (!docs || docs.length === 0) return 0;

  for (const doc of docs) {
    // Xóa chunks trước (FK constraint)
    await supabase.from('kb_chunks').delete().eq('document_id', doc.id);
    await supabase.from('kb_documents').delete().eq('id', doc.id);
  }
  return docs.length;
}

// ─── Core: Upsert Document + Chunks ─────────────────────────────────────────
async function upsertDocumentAndChunks({
  title, docType, source, url, tags, metadata, content,
  dryRun = false, upsert = false,
}) {
  const chunks = chunkText(content);

  console.log(`\n📄 Title    : ${title}`);
  console.log(`📦 Chunks   : ${chunks.length} (size ~${Math.round(content.length / chunks.length)} chars each)`);

  if (dryRun) {
    console.log('\n── DRY RUN: Preview chunks ──');
    chunks.forEach((c, i) => {
      console.log(`\n[Chunk ${i}] (${c.length} chars)\n${c.slice(0, 200)}${c.length > 200 ? '…' : ''}`);
    });
    console.log('\n✅ Dry run xong. Không insert gì vào DB.');
    return;
  }

  // Xóa document cũ cùng title nếu upsert mode
  if (upsert) {
    const deleted = await deleteDocByTitle(title);
    if (deleted > 0) console.log(`🗑️  Đã xóa ${deleted} document cũ cùng title.`);
  }

  // Insert document
  const { data: doc, error: docErr } = await supabase
    .from('kb_documents')
    .insert({ title, doc_type: docType || 'doc', source: source || null, url: url || null, tags: tags || [], metadata: metadata || {}, content })
    .select()
    .single();
  if (docErr) throw docErr;

  console.log(`🆔 Doc ID   : ${doc.id}`);

  // Embed & insert chunks in batches
  const rows = [];
  for (let idx = 0; idx < chunks.length; idx++) {
    process.stdout.write(`  ⏳ Embedding chunk ${idx + 1}/${chunks.length}...\r`);
    const emb = await embedText(chunks[idx]);
    rows.push({
      document_id: doc.id,
      chunk_index: idx,
      content: chunks[idx],
      metadata: {},
      embedding: emb,
    });
  }

  const batchSize = 20;
  for (let i = 0; i < rows.length; i += batchSize) {
    const batch = rows.slice(i, i + batchSize);
    const { error: chunkErr } = await supabase.from('kb_chunks').insert(batch);
    if (chunkErr) throw chunkErr;
  }

  console.log(`\n✅ Ingested : doc=${doc.id} | title="${title}" | chunks=${rows.length}`);
}

// ─── Ingest from File ─────────────────────────────────────────────────────────
async function ingestFile(filePath, { title, tags, dryRun, upsert }) {
  const abs = path.resolve(process.cwd(), filePath);
  const content = await fs.readFile(abs, 'utf8');
  await upsertDocumentAndChunks({
    title: title || path.basename(abs),
    docType: 'file',
    source: 'local_file',
    url: null,
    tags,
    metadata: { file: abs },
    content,
    dryRun,
    upsert,
  });
}

// ─── Ingest Courts from Supabase DB ──────────────────────────────────────────
async function ingestCourts({ tags, dryRun, upsert }) {
  const { data: courts, error } = await supabase
    .from('courts')
    .select('id, name, address, sport_type, price_per_hour, total_courts, rating, total_reviews');
  if (error) throw error;

  const lines = (courts || []).map((c) => {
    const sport = c.sport_type || '';
    const price = c.price_per_hour != null ? `${c.price_per_hour}đ/giờ` : '';
    const total = c.total_courts != null ? `${c.total_courts} sân con` : '';
    const rating = c.rating != null ? `rating ${c.rating} (${c.total_reviews || 0} reviews)` : '';
    return `COURT_FACT: id=${c.id}; name=${c.name}; address=${c.address}; sport=${sport}; price=${price}; capacity=${total}; ${rating}`.trim();
  });

  const content = ['DỮ LIỆU SÂN (tự động trích xuất từ DB)', ...lines].join('\n');

  await upsertDocumentAndChunks({
    title: 'Courts catalog',
    docType: 'db_extract',
    source: 'supabase:courts',
    url: null,
    tags,
    metadata: { table: 'courts', rows: (courts || []).length },
    content,
    dryRun,
    upsert,
  });
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  const args = parseArgs(process.argv);
  const tags = (args.tags ? String(args.tags) : '')
    .split(',').map(s => s.trim()).filter(Boolean);
  const dryRun = Boolean(args['dry-run']);
  const upsert = Boolean(args.upsert);

  if (dryRun) console.log('🔍 DRY RUN mode — Không ghi vào DB\n');
  if (upsert) console.log('♻️  UPSERT mode — Sẽ xóa document cũ cùng title\n');

  if (args.file) {
    await ingestFile(args.file, { title: args.title, tags, dryRun, upsert });
    return;
  }
  if (args.courts) {
    await ingestCourts({ tags, dryRun, upsert });
    return;
  }

  console.log('❓ Không có gì để ingest. Dùng --file <path> hoặc --courts.');
  console.log('   Options: --title "..." --tags tag1,tag2 --dry-run --upsert');
  process.exit(2);
}

main().catch((e) => {
  console.error('\n❌ Ingest failed:', e.message || e);
  process.exit(1);
});
