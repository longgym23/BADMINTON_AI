import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// Model để lưu trữ tin nhắn với hỗ trợ ảnh và audio
class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath; // Đường dẫn ảnh (nếu có)
  final String? audioPath; // Đường dẫn audio (nếu có)
  final bool isRecording; // Đang ghi âm

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.audioPath,
    this.isRecording = false,
  });
}

class ChatbotTab extends StatefulWidget {
  const ChatbotTab({super.key});

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends State<ChatbotTab> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speechToText.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );
    if (!available) {
      print('Speech recognition not available');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _speechToText.stop();
    super.dispose();
  }

  // Hiển thị menu chọn ảnh
  Future<void> _showImagePickerMenu() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _takePhotoFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Chọn ảnh từ thư viện
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _showImageDescriptionDialog(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Chụp ảnh từ camera
  Future<void> _takePhotoFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _showImageDescriptionDialog(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chụp ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hiển thị dialog để thêm mô tả cho ảnh (giống ChatGPT)
  Future<void> _showImageDescriptionDialog(String imagePath) async {
    final TextEditingController descriptionController = TextEditingController();
    final colors = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm mô tả cho ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hiển thị preview ảnh
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: 'Nhập mô tả cho ảnh (tùy chọn)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendMessage(
                descriptionController.text.trim(),
                imagePath: imagePath,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.secondary,
              foregroundColor: colors.primary,
            ),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  // Bắt đầu/dừng nhận diện giọng nói (nút micro)
  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      // Dừng nhận diện và gửi
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });

      if (_recognizedText.isNotEmpty) {
        _sendMessage(_recognizedText);
        _recognizedText = '';
      }
    } else {
      // Bắt đầu nhận diện
      if (!_speechToText.isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nhận diện giọng nói không khả dụng'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isListening = true;
        _recognizedText = '';
      });

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
            // Cập nhật text vào ô nhập
            _controller.text = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  // Gửi tin nhắn (text, ảnh hoặc audio)
  Future<void> _sendMessage(
    String text, {
    String? imagePath,
    String? audioPath,
  }) async {
    // Nếu không có text, ảnh hoặc audio thì không gửi
    if (text.trim().isEmpty && imagePath == null && audioPath == null) return;

    // Kiểm tra đăng nhập
    final isLoggedIn =
        context.read<AppAuthProvider>().authState == AuthState.authenticated;
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần đăng nhập để sử dụng chatbot.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Hiển thị tin nhắn người dùng ngay lập tức
    setState(() {
      _messages.add(
        ChatMessage(
          text: text.isEmpty ? (imagePath != null ? '[Ảnh]' : '[Audio]') : text,
          isUser: true,
          imagePath: imagePath,
          audioPath: audioPath,
        ),
      );
      _isLoading = true;
    });
    _controller.clear();

    const String backendUrl = 'https://badminton-ai-fgsz.onrender.com/ask';

    try {
      http.Response response;

      if (imagePath != null) {
        // Gửi ảnh
        var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
        if (text.isNotEmpty) {
          request.fields['prompt'] = text;
        } else {
          request.fields['prompt'] = 'Phân tích ảnh này';
        }

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else if (audioPath != null) {
        // Gửi audio
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$backendUrl/audio'),
        );
        request.files.add(
          await http.MultipartFile.fromPath('audio', audioPath),
        );
        if (text.isNotEmpty) {
          request.fields['prompt'] = text;
        }

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Gửi text thông thường
        response = await http
            .post(
              Uri.parse(backendUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'prompt': text}),
            )
            .timeout(const Duration(seconds: 45));
      }

      if (mounted) {
        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          final String answer =
              responseBody['answer'] ?? "Xin lỗi, tôi chưa hiểu ý bạn.";
          setState(() {
            _messages.add(ChatMessage(text: answer, isUser: false));
          });
        } else {
          String errorMessage = 'Lỗi không xác định từ server.';
          try {
            final responseBody = jsonDecode(response.body);
            errorMessage =
                responseBody['error'] ?? 'Lỗi server (${response.statusCode})';
          } catch (e) {
            errorMessage =
                'Lỗi server (${response.statusCode}) - Không thể đọc phản hồi.';
          }
          setState(() {
            _messages.add(
              ChatMessage(text: "Lỗi: $errorMessage", isUser: false),
            );
          });
        }
      }
    } catch (e) {
      print("Lỗi gọi API Backend: $e");
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "Lỗi kết nối tới server. Vui lòng kiểm tra mạng.",
              isUser: false,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, colors);
              },
            ),
          ),
          // Hiển thị text đang nhận diện
          if (_isListening && _recognizedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              color: colors.primary.withOpacity(0.3),
              child: Row(
                children: [
                  Icon(Icons.mic, color: colors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _recognizedText,
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Hiển thị "AI đang soạn..."
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "AI đang soạn...",
                    style: TextStyle(
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          // Ô nhập liệu và các nút chức năng
          _buildInputArea(colors),
        ],
      ),
    );
  }

  // Widget cho một bong bóng tin nhắn
  Widget _buildMessageBubble(ChatMessage message, ColorScheme colors) {
    final alignment = message.isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleColor = message.isUser
        ? colors.secondary
        : colors.primary.withOpacity(0.8);
    final textColor = message.isUser ? colors.primary : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18.0),
                topRight: const Radius.circular(18.0),
                bottomLeft: message.isUser
                    ? const Radius.circular(18.0)
                    : const Radius.circular(4.0),
                bottomRight: message.isUser
                    ? const Radius.circular(4.0)
                    : const Radius.circular(18.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị ảnh nếu có
                if (message.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(message.imagePath!),
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                // Hiển thị audio indicator nếu có
                if (message.audioPath != null)
                  Row(
                    children: [
                      Icon(Icons.audiotrack, color: textColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '[Audio]',
                        style: TextStyle(color: textColor, fontSize: 12),
                      ),
                    ],
                  ),
                // Hiển thị text
                if (message.text.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top:
                          (message.imagePath != null ||
                              message.audioPath != null)
                          ? 8.0
                          : 0,
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(color: textColor, fontSize: 15),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget cho khu vực nhập liệu (giống hình ảnh)
  Widget _buildInputArea(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.9),
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
          // Nút đính kèm (paperclip) - màu cam
          IconButton(
            icon: Icon(
              Icons.attach_file,
              color: colors.secondary, // Màu cam (secondary)
            ),
            onPressed: _isLoading ? null : _showImagePickerMenu,
            tooltip: 'Đính kèm',
          ),
          // Ô nhập text
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800]?.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              onChanged: (text) {
                setState(() {}); // Cập nhật UI khi text thay đổi
              },
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  _sendMessage(text);
                }
              },
              enabled: !_isLoading,
            ),
          ),
          const SizedBox(width: 8.0),
          // Nút micro (màu cam) - nhận diện giọng nói
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening
                  ? Colors.red
                  : colors
                        .secondary, // Màu cam khi không active, đỏ khi đang nghe
            ),
            onPressed: _isLoading ? null : _toggleVoiceInput,
            tooltip: _isListening ? 'Dừng nói' : 'Nói',
          ),
          const SizedBox(width: 4.0),
          // Nút gửi (send) - màu xám
          IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: _isLoading || _controller.text.trim().isEmpty
                  ? Colors.grey[600]
                  : Colors.grey[300],
            ),
            onPressed: (_isLoading || _controller.text.trim().isEmpty)
                ? null
                : () => _sendMessage(_controller.text),
            tooltip: 'Gửi',
          ),
        ],
      ),
    );
  }
}
