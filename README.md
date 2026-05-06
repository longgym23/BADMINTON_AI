# 🏸 KLOO — Ứng dụng quản lý đặt sân thể thao tích hợp AI

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![Node.js](https://img.shields.io/badge/Backend-Node.js%2FExpress-339933?logo=nodedotjs)
![Gemini](https://img.shields.io/badge/AI-Gemini%202.5-4285F4?logo=google)

**Đồ án tốt nghiệp | Flutter + Node.js + Supabase + Gemini AI**

</div>

---

## 📱 Giới thiệu

**KLOO** là ứng dụng mobile đặt sân thể thao (cầu lông, bóng đá, pickleball, tennis) tích hợp Chatbot AI thông minh, được xây dựng bằng Flutter và Node.js. Hệ thống sử dụng kiến trúc RAG (Retrieval-Augmented Generation) Hybrid để chatbot có thể trả lời chính xác về thông tin sân, chính sách đặt sân, và hỗ trợ thao tác booking trực tiếp qua hội thoại.

## ✨ Tính năng nổi bật

| Module | Tính năng |
|--------|-----------|
| 🔐 **Auth** | Đăng nhập email/password + Google OAuth, quên mật khẩu OTP |
| 🏸 **Đặt sân** | Atomic booking, thanh toán QR VietQR (SePay), ví nội bộ, hủy sân hoàn tiền |
| 🤖 **Chatbot AI** | Hybrid RAG (BM25 + Vector), Vision AI, multi-turn, GPS-aware search |
| 🗺️ **Bản đồ** | Google Maps, tìm sân theo vị trí GPS |
| 💬 **Social** | Direct message, nhóm chat, hệ thống bạn bè, online/offline |
| 🔔 **Notification** | Firebase FCM push notification + Supabase Realtime |
| 📊 **Admin** | Dashboard thống kê doanh thu, quản lý sân/booking/user |
| 🌐 **i18n** | Đa ngôn ngữ Việt/Anh, chuyển đổi realtime |

---

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────┐
│                 Flutter Mobile App                   │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────┐ │
│  │  Screens │→ │ViewModels│→ │   Repositories     │ │
│  │  (UI)    │  │(MVVM/BLoC│  │(Supabase + Backend)│ │
│  └──────────┘  └──────────┘  └────────────────────┘ │
└─────────────────┬───────────────────────────────────┘
                  │ REST API / Supabase Realtime
        ┌─────────┴──────────┐
        │   Node.js Backend   │        ┌──────────────┐
        │  (Render.com)       │◄──────►│  Supabase DB │
        │                     │        │  (PostgreSQL) │
        │  ┌───────────────┐  │        │  + pgvector  │
        │  │  RAG Pipeline  │  │        └──────────────┘
        │  │  BM25 + Vector │  │
        │  │  Gemini 2.5   │  │        ┌──────────────┐
        │  └───────────────┘  │◄──────►│ Firebase FCM │
        └─────────────────────┘        └──────────────┘
```

### Stack công nghệ

**Frontend (Flutter)**
- State Management: `Provider` + `flutter_bloc`
- Architecture: Clean Architecture + MVVM
- Database client: `supabase_flutter`
- Maps: `google_maps_flutter` + `geolocator`
- Localization: `easy_localization` (Vi/En)
- Push: `firebase_messaging` + `flutter_local_notifications`

**Backend (Node.js/Express)**
- AI: Google Gemini 2.5 Flash Lite (text + vision)
- RAG: pgvector (semantic) + BM25 (keyword) Hybrid
- Email OTP: MailerSend
- Push: Firebase Admin SDK
- OTP storage: Supabase `otp_verifications` table

**Database (Supabase / PostgreSQL)**
- Auth: email/password + Google OAuth
- Storage: Supabase Storage (avatar, court images)
- Realtime: Supabase Realtime subscriptions
- Vector: pgvector extension cho RAG

---

## 🚀 Hướng dẫn cài đặt

### Yêu cầu

- Flutter SDK >= 3.10.0
- Node.js >= 18.x
- Tài khoản: Supabase, Firebase, Google Cloud (Maps API), MailerSend

### 1. Clone & Cài đặt Flutter

```bash
git clone https://github.com/longgym23/badminton_ai.git
cd badminton_ai
flutter pub get
```

### 2. Cấu hình Firebase

```bash
# Cài FlutterFire CLI
dart pub global activate flutterfire_cli

# Cấu hình tự động
flutterfire configure
```

Đảm bảo `google-services.json` (Android) đã được đặt vào `android/app/`.

### 3. Cấu hình Supabase

Tạo file `lib/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const supabaseUrl    = 'YOUR_SUPABASE_URL';
  static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

Chạy migration:
```sql
-- Trong Supabase SQL Editor
-- Chạy file: supabase/migrations/20260506_otp_verifications.sql
```

### 4. Cài đặt Backend

```bash
cd badminton_ai_backend
npm install

# Tạo file .env
cp .env.example .env
```

Cập nhật `.env`:
```env
PORT=3000
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
GEMINI_API_KEY=your_gemini_api_key
MAILERSEND_API_KEY=your_mailersend_api_key
MAILERSEND_FROM_EMAIL=noreply@yourdomain.com
GROQ_API_KEY=your_groq_api_key
```

Chạy backend:
```bash
node server.js
# hoặc với nodemon:
npx nodemon server.js
```

### 5. Chạy Flutter App

```bash
flutter run
# Hoặc build release APK:
flutter build apk --release
```

---

## 🤖 RAG Chatbot Architecture

Chatbot sử dụng **Hybrid RAG** — kết hợp 2 phương pháp tìm kiếm:

```
User Query
    │
    ▼
┌─────────────────────────────────────────┐
│           Intent Detection               │
│  (booking/cancel/find-court/wallet/...)  │
└──────────────┬──────────────────────────┘
               │
    ┌──────────┴──────────┐
    │   Parallel Search   │
    ├─────────────────────┤
    │  Vector Search (60%)│  ← pgvector cosine similarity
    │  BM25 Keyword (40%) │  ← Full-text search PostgreSQL
    └──────────┬──────────┘
               │ Top-K merged results
               ▼
    ┌──────────────────────┐
    │  Gemini 2.5 Flash    │
    │  + User Context      │  ← bookings, balance, GPS
    │  + Session History   │  ← 6 turns memory
    └──────────────────────┘
               │
               ▼
          Response
```

**Vision AI** (Two-Pass): Khi user gửi ảnh → Gemini trích xuất text/keyword từ ảnh → tìm kiếm RAG dựa trên keyword → trả về thông tin liên quan.

---

## 📁 Cấu trúc thư mục

```
lib/
├── blocs/              # BLoC state management
├── config/             # App configuration (Supabase, API keys)
├── data/
│   ├── models/         # Data models (BookingModel, UserModel,...)
│   └── repositories/   # Data access layer (Supabase)
├── providers/          # Provider state (Auth, Language,...)
├── screens/            # UI screens
│   ├── admin/          # Admin dashboard screens
│   └── user/           # User-facing screens
├── services/           # External services (FCM, STT, Payment)
├── utils/              # Utilities (AppColors, AppLogger,...)
├── viewmodels/         # MVVM ViewModels
└── widgets/            # Reusable widgets

badminton_ai_backend/
├── server.js           # Main Express server + all routes
├── .env                # Environment variables (git-ignored)
└── uploads/            # Temp upload directory

test/
└── widget_test.dart    # Unit tests (68 tests)

supabase/
└── migrations/         # SQL migration files
```

---

## 🧪 Chạy Unit Tests

```bash
flutter test test/widget_test.dart --reporter=expanded
# Expected: 68/68 tests passed
```

**Các nhóm test:**
- Chính sách hủy sân (9 tests)
- BookingModel parse/serialize (10 tests)
- UserModel parse/serialize (9 tests)
- Slot conflict detection (5 tests)
- Email/Password validation (4 tests)
- Price formatting (4 tests)
- CourtLocationModel (6 tests)
- Booking price calculation (6 tests)
- EventModel + business logic (9 tests)
- Role-based access control (6 tests)

---

## 📡 API Endpoints (Backend)

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/ask` | Gửi tin nhắn chat (text) |
| POST | `/ask/image` | Gửi ảnh cho Vision AI |
| POST | `/forgot-password` | Gửi OTP về email |
| POST | `/verify-otp` | Xác thực OTP |
| POST | `/reset-password` | Đặt lại mật khẩu |
| POST | `/api/send-notification` | Gửi FCM push notification |
| GET | `/` | Health check |

---

## 👨‍💻 Tác giả

**Nguyễn Long** — Sinh viên ngành Công nghệ thông tin  
Đồ án tốt nghiệp 2025-2026

---

## 📄 License

MIT License — Xem [LICENSE](LICENSE) để biết thêm chi tiết.
