import 'dart:io';
import 'package:badminton_ai/blocs/chat/chat_bloc.dart';
import 'package:badminton_ai/data/models/chat_message_model.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/screens/user/booking/court_selection_screen.dart';

class ChatbotTab extends StatefulWidget {
  const ChatbotTab({super.key});

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends State<ChatbotTab> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _speechToText = stt.SpeechToText();

  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _connectChat();
  }

  void _connectChat() {
    final userId = context.read<AppAuthProvider>().userId;
    if (userId != null) {
      context.read<ChatBloc>().add(ChatStarted(userId));
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _initializeSpeech() async {
    final micStatus = await Permission.microphone.request();
    // Yêu cầu thêm quyền nhận diện giọng nói (Speech) bắt buộc cho iOS và một số máy Android
    final speechStatus = await Permission.speech.request();

    if (micStatus.isGranted || speechStatus.isGranted) {
      bool available = await _speechToText.initialize(
        onError: (e) => debugPrint('STT Error: $e'),
        onStatus: (s) => debugPrint('STT Status: $s'),
      );
      if (!available) {
        debugPrint("Speech recognition not available on this device.");
      }
    } else {
      debugPrint("Microphone/Speech permission NOT granted.");
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _sendMessage([String? text, String? imagePath]) {
    final auth = context.read<AppAuthProvider>();
    if (auth.authState != AuthState.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để chat')),
      );
      return;
    }

    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty && imagePath == null) return;

    _textController.clear();
    _recognizedText = '';
    FocusScope.of(context).unfocus();

    context.read<ChatBloc>().add(
      ChatMessageSent(text: messageText, imagePath: imagePath),
    );

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Trợ lý AI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textBlack,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'TRỰC TUYẾN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_vert, color: AppColors.textBlack),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isListening) _buildVoiceIndicator(),
          _buildSuggestionChips(),
          _buildInputArea(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading && state is! ChatLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        List<ChatMessageModel> messages = [];
        if (state is ChatLoaded) {
          messages = state.messages;
        }

        if (messages.isEmpty && state is! ChatLoading) {
          // Sample Initial Message for Demo if empty
          return Center(
            child: Text(
              'Bắt đầu trò chuyện!',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isLast = index == 0;
            final showDate =
                index == messages.length - 1 ||
                !isSameDay(
                  messages[index].timestamp,
                  messages[index + 1].timestamp,
                );

            return Column(
              children: [
                if (showDate) _buildDateDivider(message.timestamp),
                _MessageBubble(message: message),
                if (isLast && !message.isUser) const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateDivider(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.borderColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Hôm nay, ${DateFormat('HH:mm').format(date)}",
        style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
      ),
    );
  }

  Widget _buildVoiceIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.errorBg,
      child: Row(
        children: [
          const Icon(Icons.mic, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _recognizedText,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Chip('Sân cầu lông gần đây'),
          _Chip('Tìm sân bóng đá gần đây'),
          _Chip('Sân Pickleball tốt nhất'),
          _Chip('Tìm sân cầu lông trống'),
        ],
      ),
    );
  }

  Widget _Chip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => _sendMessage(label),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: AppColors.brandOrange,
            ),
            onPressed: () => _showAttachmentSheet(),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _toggleEntryVoice,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isListening ? AppColors.errorBg : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: _isListening ? AppColors.error : AppColors.brandOrange,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _sendMessage(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: AppColors.surface, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // --- Logic Helpers ---

  Future<void> _toggleEntryVoice() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
      if (_recognizedText.isNotEmpty) {
        _sendMessage(_recognizedText);
        _recognizedText = '';
      }
    } else {
      if (!_speechToText.isAvailable) {
        // Try to initialize again just in case
        await _initializeSpeech();
        if (!_speechToText.isAvailable) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Không hỗ trợ nhận diện giọng nói. Quý khách lưu ý: Tính năng này thường không hoạt động trên Emulator giả lập.')));
          return;
        }
      }
      setState(() {
        _isListening = true;
        _recognizedText = '';
      });
      _speechToText.listen(
        onResult: (res) {
          setState(() {
            _recognizedText = res.recognizedWords;
            _textController.text = res.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
      );
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Thư viện'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file != null) _showImageDescDialog(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi ảnh: $e')));
    }
  }

  Future<void> _showImageDescDialog(String path) async {
    final ctl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(path), height: 150, fit: BoxFit.cover),
            TextField(
              controller: ctl,
              decoration: const InputDecoration(
                hintText: 'Mô tả (tùy chọn)...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sendMessage(ctl.text.trim(), path);
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    bool isUser = message.isUser;

    // Lọc mã ACTION
    final actionMatch = RegExp(r'\[ACTION_SEARCH:([^\]]+)\]').firstMatch(message.text);
    final String? searchSportType = !isUser && actionMatch != null ? actionMatch.group(1) : null;
    
    final cleanText = message.text.replaceAll(RegExp(r'\[ACTION_SEARCH:[^\]]+\]'), '').trim();

    // Check for "Success Card" trigger
    bool isSuccessCard =
        !isUser &&
        (cleanText.contains("thành công") ||
            message.type == 'booking_success');

    if (isSuccessCard) {
      return _buildSuccessCard(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary, // Blue avatar bg
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: AppColors.surface,
                    size: 16,
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFFFF8C00) // Darker Orange
                        : const Color(0xFFFFE0B2), // Light Orange
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    boxShadow: !isUser
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imagePath != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(message.imagePath!),
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      if (cleanText.isNotEmpty)
                        Text(
                          cleanText,
                          style: TextStyle(
                            color: isUser ? AppColors.surface : AppColors.textBlack,
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 40), // Spacer
            ],
          ),
          
          // Thêm Carousel hiển thị sân nếu có action
          if (searchSportType != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 40),
              child: _CourtListCarousel(sportType: searchSportType),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 40, top: 4, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successBg, // Light Green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.surface,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Giao dịch ghi nhận!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Giả lập giao diện
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Thanh toán hoàn tất",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Sân sẽ được giữ chỗ",
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourtListCarousel extends StatefulWidget {
  final String sportType;
  const _CourtListCarousel({required this.sportType});

  @override
  State<_CourtListCarousel> createState() => _CourtListCarouselState();
}

class _CourtListCarouselState extends State<_CourtListCarousel> {
  List<CourtLocationModel> courts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourts();
  }

  Future<void> _fetchCourts() async {
    try {
      final allData = await Supabase.instance.client.from('courts').select().limit(20);
      final allCourts = allData.map((e) => CourtLocationModel.fromSupabase(e)).toList();
      
      // Lọc logic tại app để đảm bảo linh hoạt
      courts = allCourts.where((c) {
        final t = (c.sportType ?? c.name).toLowerCase();
        final q = widget.sportType.toLowerCase();
        if (q == 'football' && (t.contains('bóng đá') || t.contains('football'))) return true;
        if (q == 'badminton' && (t.contains('cầu lông') || t.contains('badminton'))) return true;
        if (q == 'tennis' && (t.contains('tennis'))) return true;
        if (q == 'pickleball' && (t.contains('pickleball') || t.contains('pickle'))) return true;
        return t.contains(q);
      }).toList();
      
      // Nếu không tìm thấy, gợi ý đại các sân phổ biến
      if (courts.isEmpty) {
         courts = allCourts.take(4).toList(); 
      }

    } catch (e) {
      debugPrint("Lỗi fetch sân cho carousel: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    
    if (courts.isEmpty) {
      return Container(
         padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(
           color: AppColors.surface,
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: AppColors.borderColor),
         ),
         child: const Text('Hiện không có sân nào phù hợp ở khu vực bạn.', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
      );
    }

    return SizedBox(
      height: 155, // 60 ảnh + 95 nội dung
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: courts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final court = courts[index];
          return Container(
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
              boxShadow: [
                 BoxShadow(
                   color: Colors.black.withOpacity(0.04),
                   blurRadius: 4,
                   offset: const Offset(0, 2),
                 )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hình ảnh sân
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    color: AppColors.primaryBg,
                    child: court.imageUrl != null && court.imageUrl!.isNotEmpty
                         ? Image.network(court.imageUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.sports_tennis, color: AppColors.primary))
                         : const Icon(Icons.sports_score, color: AppColors.primary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        court.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textBlack),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on_outlined, size: 12, color: AppColors.brandOrangeDark),
                          const SizedBox(width: 4),
                          Text(
                            "${court.pricePerHour.toInt()}đ/h",
                            style: const TextStyle(color: AppColors.brandOrangeDark, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 26,
                        child: ElevatedButton(
                          onPressed: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => CourtSelectionScreen(
                                   selectedCourt: court,
                                   selectedDate: DateTime.now(),
                                 ),
                               ),
                             );
                          },
                          style: ElevatedButton.styleFrom(
                             backgroundColor: AppColors.primary,
                             foregroundColor: Colors.white,
                             padding: EdgeInsets.zero,
                             elevation: 0,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
                          ),
                          child: const Text('Đặt Ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

