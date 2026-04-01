// Import các thư viện cần thiết
require('dotenv').config();
const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs-extra');
const path = require('path');

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

// Khởi tạo Gemini
let genAI;
let model;
let visionModel;
try {
  genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  visionModel = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' }); // Model hỗ trợ vision
} catch (error) {
  console.error('Lỗi khởi tạo Gemini (kiểm tra API Key?):', error);
}

// Định nghĩa System Prompt
const systemPrompt =
  `Bạn là trợ lý ảo cho ứng dụng đặt sân cầu lông 'KLOO'.
Nhiệm vụ của bạn là trả lời các câu hỏi của người dùng một cách thân thiện,
ngắn gọn và hữu ích. Các chủ đề chính bao gồm:
1. Cách đặt sân: Người dùng chọn ngày, chọn sân, sau đó chọn giờ
   và sân con trên biểu đồ.
2. Cách hủy sân: Người dùng vào Tab "Tài khoản" -> "Lịch sử đặt sân"
   và nhấn nút hủy.
3. Giá cả: Giá được hiển thị khi chọn sân.
4. Admin: Admin có thể quản lý sân và lịch đặt.
Chỉ trả lời các câu hỏi liên quan đến việc sử dụng ứng dụng. Từ chối
trả lời các câu hỏi không liên quan (ví dụ: chính trị, thời tiết).
QUAN TRỌNG: Trả lời bằng văn bản thuần túy, KHÔNG sử dụng markdown formatting như dấu *, **, #, hoặc các ký hiệu định dạng khác.`;

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

// Định nghĩa Endpoint '/ask' - xử lý cả text và ảnh
app.post('/ask', upload.single('image'), async (req, res) => {
  const imageFile = req.file;
  const userPrompt = req.body.prompt || (imageFile ? 'Phân tích ảnh này và trả lời câu hỏi liên quan đến ứng dụng đặt sân cầu lông.' : '');

  // Nếu có ảnh, xử lý với Vision API
  if (imageFile) {
    const userPrompt = req.body.prompt || 'Phân tích ảnh này và trả lời câu hỏi liên quan đến ứng dụng đặt sân cầu lông.';
    const imageFile = req.file;

    if (!imageFile) {
      return res.status(400).json({ error: 'Không có ảnh được gửi lên.' });
    }

    if (!visionModel) {
      cleanupFile(imageFile.path);
      return res.status(500).json({ error: 'Lỗi khởi tạo AI vision model.' });
    }

    try {
      // Đọc file ảnh
      const imageData = await fs.readFile(imageFile.path);
      const base64Image = imageData.toString('base64');
      const mimeType = imageFile.mimetype || 'image/jpeg';

      // Gửi ảnh và prompt lên Gemini Vision
      const result = await visionModel.generateContent([
        {
          text: `${systemPrompt}\n\n${userPrompt}`,
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
        return res.status(500).json({ error: 'AI không thể phân tích ảnh.' });
      }

      let text = response.text();
      cleanupFile(imageFile.path);

      if (!text || text.trim().length === 0) {
        return res.status(500).json({ error: 'AI không thể tạo câu trả lời từ ảnh.' });
      }

      // Loại bỏ markdown formatting
      text = removeMarkdown(text);

      res.json({ answer: text });
      return;
    } catch (error) {
      cleanupFile(imageFile.path);
      console.error('Lỗi khi xử lý ảnh với Gemini:', error);
      res.status(500).json({ error: 'Đã xảy ra lỗi khi xử lý ảnh.' });
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
      history: [{ role: 'user', parts: [{ text: systemPrompt }] }],
      generationConfig: {
        maxOutputTokens: 250,
      },
    });

    const result = await chat.sendMessage(userPrompt);
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

    res.json({ answer: text });
  } catch (error) {
    console.error('Lỗi khi gọi Gemini API:', error);
    res.status(500).json({ error: 'Đã xảy ra lỗi khi kết nối với AI.' });
  }
});

// Endpoint '/ask/audio' để xử lý audio
app.post('/ask/audio', upload.single('audio'), async (req, res) => {
  const userPrompt = req.body.prompt || '';
  const audioFile = req.file;

  if (!audioFile) {
    return res.status(400).json({ error: 'Không có audio được gửi lên.' });
  }

  // Lưu ý: Gemini có thể xử lý audio, nhưng cần model phù hợp
  // Ở đây tôi sẽ trả về thông báo yêu cầu chuyển audio thành text trước
  // Hoặc bạn có thể tích hợp speech-to-text service như Google Speech-to-Text API

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
app.listen(port, () => {
  console.log(`Server đang chạy tại http://localhost:${port}`);
});
