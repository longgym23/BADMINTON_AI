// Import các thư viện cần thiết
require('dotenv').config(); // Load biến môi trường từ .env (cho local)
const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const cors = require('cors');

// Kiểm tra API Key
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
if (!GEMINI_API_KEY || GEMINI_API_KEY === 'YOUR_API_KEY_PLACEHOLDER') {
  console.error('Gemini API Key không được tìm thấy hoặc chưa được cấu hình trong biến môi trường!');
  // Không nên thoát ở đây nếu deploy, Render có thể restart
  // process.exit(1);
}

// Khởi tạo Gemini
let genAI;
let model;
try {
  genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
} catch(error) {
  console.error('Lỗi khởi tạo Gemini (kiểm tra API Key?):', error);
  // Không nên thoát ở đây
}


// Định nghĩa System Prompt (Mồi cho AI)
const systemPrompt =
`Bạn là trợ lý ảo cho ứng dụng đặt sân cầu lông 'Badminton Pro'.
Nhiệm vụ của bạn là trả lời các câu hỏi của người dùng một cách thân thiện,
ngắn gọn và hữu ích. Các chủ đề chính bao gồm:
1.  **Cách đặt sân:** Người dùng chọn ngày, chọn sân, sau đó chọn giờ
    và sân con trên biểu đồ.
2.  **Cách hủy sân:** Người dùng vào Tab "Tài khoản" -> "Lịch sử đặt sân"
    và nhấn nút hủy.
3.  **Giá cả:** Giá được hiển thị khi chọn sân.
4.  **Admin:** Admin có thể quản lý sân và lịch đặt.
Chỉ trả lời các câu hỏi liên quan đến việc sử dụng ứng dụng. Từ chối
trả lời các câu hỏi không liên quan (ví dụ: chính trị, thời tiết).`;


// Khởi tạo Express app
const app = express();
const port = process.env.PORT || 3000; // Render sẽ tự cung cấp PORT

// Middleware
app.use(cors()); // Cho phép cross-origin requests từ Flutter app
app.use(express.json()); // Parse JSON body từ request

// Định nghĩa Endpoint '/ask'
app.post('/ask', async (req, res) => {
  const userPrompt = req.body.prompt;

  if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim().length === 0) {
    return res.status(400).json({ error: 'Câu hỏi (prompt) không hợp lệ.' });
  }

  // Đảm bảo model đã sẵn sàng
  if (!model) {
      console.error('Gemini model chưa sẵn sàng (lỗi khởi tạo?).');
      return res.status(500).json({ error: 'Lỗi khởi tạo AI model.' });
  }

  try {
    // Gọi Gemini
    const chat = model.startChat({
      history: [{ role: 'user', parts: [{ text: systemPrompt }] }],
      generationConfig: {
        maxOutputTokens: 250,
      },
    });

    const result = await chat.sendMessage(userPrompt);

    // Truy cập response và text (cách chính xác đã sửa)
    const response = result.response;
    if (!response) {
      console.error('Gemini API không trả về response hợp lệ.', { userPrompt });
      return res.status(500).json({ error: 'AI không thể tạo câu trả lời (response null).' });
    }

    const text = response.text();
    if (!text || text.trim().length === 0) {
      console.warn('Gemini không trả về nội dung text.', { response });
      return res.status(500).json({ error: 'AI không thể tạo câu trả lời (text rỗng).' });
    }

    // Trả kết quả về cho Flutter app
    res.json({ answer: text });

  } catch (error) {
    console.error('Lỗi khi gọi Gemini API:', error);
    // Trả lỗi chung cho client
    res.status(500).json({ error: 'Đã xảy ra lỗi khi kết nối với AI.' });
  }
});

// Endpoint kiểm tra server hoạt động
app.get('/', (req, res) => {
  res.send('Badminton AI Backend is running!');
});

// Chạy server
app.listen(port, () => {
  console.log(`Server đang chạy tại http://localhost:${port}`);
});

