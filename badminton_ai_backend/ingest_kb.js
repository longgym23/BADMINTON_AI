/**
 * Minimal KB ingestion script for Supabase pgvector RAG.
 *
 * Usage examples:
 *   node ingest_kb.js --file ./kb/policies.md --title "Policies" --tags policies,refund
 *   node ingest_kb.js --courts --tags courts
 *
 * Env required:
 *   SUPABASE_URL
 *   SUPABASE_SERVICE_ROLE_KEY
 *   GEMINI_API_KEY
 *
 * Notes:
 * - Embedding dimension is assumed 768 (see migration).
 * - Chunking is simple and deterministic (character-based) to keep dependencies minimal.
 */

require('dotenv').config();
const fs = require('fs-extra');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in env.');
  process.exit(1);
}
if (!GEMINI_API_KEY || GEMINI_API_KEY === 'YOUR_API_KEY_HERE') {
  console.error('Missing GEMINI_API_KEY in env.');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
const embeddingModelName = process.env.GEMINI_EMBEDDING_MODEL || 'gemini-embedding-2-preview'; // 3072 dim
const embedModel = genAI.getGenerativeModel({ model: embeddingModelName });

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (!next || next.startsWith('--')) args[key] = true;
      else {
        args[key] = next;
        i++;
      }
    }
  }
  return args;
}

function chunkText(text, { chunkSize = 1200, overlap = 150 } = {}) {
  const cleaned = text.replace(/\r\n/g, '\n').trim();
  const chunks = [];
  let i = 0;
  while (i < cleaned.length) {
    const end = Math.min(i + chunkSize, cleaned.length);
    const slice = cleaned.slice(i, end).trim();
    if (slice) chunks.push(slice);
    if (end === cleaned.length) break;
    i = Math.max(0, end - overlap);
  }
  return chunks;
}

async function embedText(text) {
  // outputDimensionality giới hạn output xuống 1536 chiều (gemini-embedding-2-preview hỗ trợ truncation)
  const res = await embedModel.embedContent({
    content: { parts: [{ text }], role: 'user' },
    outputDimensionality: 1536,
  });
  const v = res?.embedding?.values || res?.embedding?.value || res?.embedding || res?.data?.[0]?.embedding;
  if (!Array.isArray(v)) throw new Error('Embedding API returned an unexpected shape.');
  return v;
}

async function upsertDocumentAndChunks({ title, docType, source, url, tags, metadata, content }) {
  const { data: doc, error: docErr } = await supabase
    .from('kb_documents')
    .insert({
      title,
      doc_type: docType || 'doc',
      source: source || null,
      url: url || null,
      tags: tags || [],
      metadata: metadata || {},
      content,
    })
    .select()
    .single();
  if (docErr) throw docErr;

  const chunks = chunkText(content);
  const rows = [];
  for (let idx = 0; idx < chunks.length; idx++) {
    const c = chunks[idx];
    const emb = await embedText(c);
    rows.push({
      document_id: doc.id,
      chunk_index: idx,
      content: c,
      metadata: {},
      embedding: emb,
    });
  }

  // Insert chunks in batches.
  const batchSize = 20;
  for (let i = 0; i < rows.length; i += batchSize) {
    const batch = rows.slice(i, i + batchSize);
    const { error: chunkErr } = await supabase.from('kb_chunks').insert(batch);
    if (chunkErr) throw chunkErr;
  }

  console.log(`Ingested doc=${doc.id} title="${title}" chunks=${rows.length}`);
}

async function ingestFile(filePath, { title, tags }) {
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
  });
}

async function ingestCourts({ tags }) {
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

  const content = [
    'DỮ LIỆU SÂN (tự động trích xuất từ DB)',
    ...lines,
  ].join('\n');

  await upsertDocumentAndChunks({
    title: 'Courts catalog',
    docType: 'db_extract',
    source: 'supabase:courts',
    url: null,
    tags,
    metadata: { table: 'courts', rows: (courts || []).length },
    content,
  });
}

async function main() {
  const args = parseArgs(process.argv);
  const tags = (args.tags ? String(args.tags) : '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  if (args.file) {
    await ingestFile(args.file, { title: args.title, tags });
    return;
  }
  if (args.courts) {
    await ingestCourts({ tags });
    return;
  }

  console.log('Nothing to ingest. Use --file <path> or --courts.');
  process.exit(2);
}

main().catch((e) => {
  console.error('Ingest failed:', e);
  process.exit(1);
});

