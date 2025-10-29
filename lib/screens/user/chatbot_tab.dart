import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import gói http
import 'dart:convert'; // Import dart:convert để xử lý JSON
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/auth_provider.dart'; // Để kiểm tra đăng nhập

// Model đơn giản để lưu trữ tin nhắn
class ChatMessage {
  final String text;
  final bool isUser; // True nếu là tin nhắn của người dùng

  ChatMessage({required this.text, required this.isUser});
}

class ChatbotTab extends StatefulWidget {
  const ChatbotTab({super.key});

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends State<ChatbotTab> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false; // Trạng thái chờ AI trả lời

  // SỬA: Hàm gọi API Backend trên Render
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Kiểm tra đăng nhập trước khi gửi
    final isLoggedIn = context.read<AppAuthProvider>().authState == AuthState.authenticated;
    if (!isLoggedIn) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để sử dụng chatbot.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Hiển thị tin nhắn người dùng ngay lập tức
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true; // Bắt đầu chờ
    });
    _controller.clear(); // Xóa ô nhập

    // !!! THAY THẾ URL NÀY BẰNG URL RENDER CỦA BẠN !!!
    const String backendUrl = 'https://badminton-ai-fgsz.onrender.com';
    // Ví dụ: 'https://badminton-ai-backend-xyz1.onrender.com/ask'
    // Đảm bảo có '/ask' ở cuối

    // Kiểm tra URL placeholder
     if (backendUrl.contains('https://badminton-ai-fgsz.onrender.com')) {
        print("LỖI: Chưa thay thế URL Render trong chatbot_tab.dart!");
         setState(() {
            _messages.add(ChatMessage(text: "Lỗi cấu hình: URL backend chưa được thiết lập.", isUser: false));
            _isLoading = false;
         });
         return;
     }


    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': text}), // Gửi prompt dưới dạng JSON
      ).timeout(const Duration(seconds: 45)); // Tăng timeout lên 45 giây cho Render free

      if (mounted) { // Kiểm tra widget còn tồn tại không
        if (response.statusCode == 200) {
          // Nếu thành công (200 OK)
          final responseBody = jsonDecode(response.body);
          final String answer = responseBody['answer'] ?? "Xin lỗi, tôi chưa hiểu ý bạn.";
          // Hiển thị tin nhắn của AI
          setState(() {
            _messages.add(ChatMessage(text: answer, isUser: false));
          });
        } else {
          // Nếu có lỗi từ server (4xx, 5xx)
          String errorMessage = 'Lỗi không xác định từ server.';
          try {
             final responseBody = jsonDecode(response.body);
             errorMessage = responseBody['error'] ?? 'Lỗi server (${response.statusCode})';
          } catch(e) {
              errorMessage = 'Lỗi server (${response.statusCode}) - Không thể đọc phản hồi.';
          }
          print("Lỗi API Backend: ${response.statusCode} - ${response.body}");
          setState(() {
            _messages.add(ChatMessage(text: "Lỗi: $errorMessage", isUser: false));
          });
        }
      }

    } catch (e) {
       // Lỗi mạng hoặc timeout
       print("Lỗi gọi API Backend: $e");
        if (mounted) {
           setState(() {
            _messages.add(ChatMessage(text: "Lỗi kết nối tới server. Vui lòng kiểm tra mạng.", isUser: false));
           });
        }
    } finally {
        // Luôn dừng loading sau khi hoàn tất hoặc lỗi
        if(mounted){
             setState(() {
                 _isLoading = false; // Ngừng chờ
             });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý AI'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              reverse: false, // Hiển thị từ trên xuống
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, colors);
              },
            ),
          ),
          // Hiển thị "AI đang soạn..."
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.secondary)
                  ),
                  const SizedBox(width: 8),
                  Text("AI đang soạn...", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                ],
              ),
            ),

          // Ô nhập liệu và nút gửi
          _buildInputArea(colors),
        ],
      ),
    );
  }

  // Widget cho một bong bóng tin nhắn
  Widget _buildMessageBubble(ChatMessage message, ColorScheme colors) {
    final alignment = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.isUser ? colors.secondary : colors.primary.withOpacity(0.8); // Vàng / Xanh đậm
    final textColor = message.isUser ? colors.primary : Colors.white; // Chữ Xanh đậm / Trắng

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), // Giới hạn chiều rộng
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18.0),
                topRight: const Radius.circular(18.0),
                bottomLeft: message.isUser ? const Radius.circular(18.0) : const Radius.circular(4.0), // Bo góc khác nhau
                bottomRight: message.isUser ? const Radius.circular(4.0) : const Radius.circular(18.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ]
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // Widget cho khu vực nhập liệu
  Widget _buildInputArea(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.9), // Nền xanh đậm
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white), // Chữ nhập màu trắng
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi của bạn...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: colors.primary.withOpacity(0.5), // Nền ô nhập đậm hơn
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              ),
              onSubmitted: _sendMessage, // Gửi khi nhấn Enter trên bàn phím (nếu có)
              enabled: !_isLoading, // Vô hiệu hóa khi đang chờ AI
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.send_rounded, color: _isLoading ? Colors.grey : colors.secondary), // Icon màu vàng
            onPressed: _isLoading ? null : () => _sendMessage(_controller.text), // Disable nút khi đang chờ
            tooltip: 'Gửi',
          ),
        ],
      ),
    );
  }
}

