import 'dart:io';
import 'package:badminton_ai/blocs/chat/chat_bloc.dart';
import 'package:badminton_ai/data/models/chat_message_model.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/services/groq_stt_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/screens/user/booking/court_selection_screen.dart';
import 'package:badminton_ai/screens/user/booking/booking_history_screen.dart';
import 'package:badminton_ai/screens/user/profile/statistics_screen.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:flutter/cupertino.dart';

class ChatbotTab extends StatefulWidget {
  /// Callback để quay lại trang chủ (tab 0) thay vì Navigator.pop
  /// vì ChatbotTab là 1 tab trong IndexedStack, không phải route
  final VoidCallback? onBack;
  const ChatbotTab({super.key, this.onBack});

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends State<ChatbotTab> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _speechToText = stt.SpeechToText();
  final _audioRecorder = AudioRecorder(); // Groq fallback: ghi âm

  bool _isListening = false;
  bool _mounted = true; // Fix: tránh setState sau dispose
  String _recognizedText = '';
  String? _pendingImagePath; // Fix: image preview kiểu ChatGPT
  bool _useGroqFallback = true; // Bắt buộc dùng Groq Whisper để STT tiếng Việt chuẩn xác hơn
  bool _isTranscribing = false; // true = đang gửi audio lên Groq
  String? _recordingPath; // Đường dẫn file audio đang ghi

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
    if (_mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speechToText.initialize(
        onError: (_) {},
        onStatus: (status) {
          if (!_useGroqFallback && (status == 'done' || status == 'notListening')) {
            if (_mounted && _isListening && _recognizedText.isNotEmpty) {
              setState(() => _isListening = false);
              _sendMessage(_recognizedText);
            } else if (_mounted && _isListening) {
              setState(() => _isListening = false);
            }
          }
        },
      );

      if (!available) {
        _useGroqFallback = true;
        return;
      }

      // Kiểm tra locale mặc định của engine nhận dạng giọng nói
      final sttSystemLocale = await _speechToText.systemLocale();
      final sttLang = sttSystemLocale?.localeId ?? '';

      if (sttLang.startsWith('zh') || sttLang.startsWith('cmn')) {
        _useGroqFallback = true;
        return;
      }

      final locales = await _speechToText.locales();
      final hasVietnamese = locales.any((l) => l.localeId.startsWith('vi'));
      if (!hasVietnamese) {
        _useGroqFallback = true;
      }
    } catch (_) {
      _useGroqFallback = true;
    }
  }

  /// Kiểm tra text có chứa ký tự CJK (Trung/Nhật/Hàn) không.
  bool _containsCJK(String text) {
    return text.runes.any((r) =>
      (r >= 0x4E00 && r <= 0x9FFF) ||
      (r >= 0x3400 && r <= 0x4DBF) ||
      (r >= 0x3000 && r <= 0x303F)
    );
  }

  @override
  void dispose() {
    _mounted = false;
    _speechToText.cancel(); // Fix: cancel thay vì stop để tránh callback sau dispose
    _audioRecorder.dispose(); // Cleanup recorder
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? text, String? imagePath]) {
    if (!_mounted) return;
    final auth = context.read<AppAuthProvider>();
    if (auth.authState != AuthState.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để chat')),
      );
      return;
    }
    // Ưu tiên pending image nếu có
    final finalImage = imagePath ?? _pendingImagePath;
    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty && finalImage == null) return;

    if (_mounted) {
      setState(() {
        _pendingImagePath = null; // Xóa preview sau khi gửi
        _recognizedText = '';
      });
    }
    _textController.clear();
    FocusScope.of(context).unfocus();

    context.read<ChatBloc>().add(
      ChatMessageSent(text: messageText, imagePath: finalImage),
    );
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Trợ lý AI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.background,
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          // Fix màn đen: dùng onBack callback thay Navigator.pop
          // vì tab này nằm trong IndexedStack, Navigator.pop sẽ pop HomeScreen
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (!_isListening && !_isTranscribing) _buildSuggestionChips(),
          if (_pendingImagePath != null) _buildImagePreview(),
          _buildInputArea(),
          if (!isKeyboardVisible) const SizedBox(height: 92),
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

  Widget _buildSuggestionChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Chip('Tìm sân cầu lông'),
          _Chip('Tìm sân bóng đá'),
          _Chip('Tìm sân Pickleball'),
          _Chip('Tìm sân tennis'),
          _Chip('Cách hủy sân'),
          _Chip('Xem lịch đặt'),
          _Chip('Xem chi tiêu'),
          _Chip('Mua vợt cầu lông'),
          _Chip('Cách chọn giày'),
        ],
      ),
    );
  }

  Widget _Chip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        side: const BorderSide(color: AppColors.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => _sendMessage(label),
      ),
    );
  }

  /// Input area kiểu ChatGPT: chuyển đổi giữa mode gõ text và mode ghi âm
  Widget _buildInputArea() {
    // === ĐANG GHI ÂM hoặc ĐANG TRANSCRIBE → hiện Recording Bar ===
    if (_isListening || _isTranscribing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.borderColor)),
        ),
        child: Row(
          children: [
            // Nút Stop (■)
            GestureDetector(
              onTap: _isTranscribing ? null : _toggleEntryVoice,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isTranscribing
                      ? Colors.grey.shade300
                      : Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isTranscribing
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.stop_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Waveform animation
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: _isTranscribing
                    ? const Center(
                        child: Text(
                          'Đang nhận dạng...',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Waveform dots animation
                          ...List.generate(20, (i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1.5),
                              child: _WaveformBar(index: i),
                            );
                          }),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Nút Send (↑)
            GestureDetector(
              onTap: _isTranscribing ? null : _toggleEntryVoice,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isTranscribing
                      ? Colors.grey.shade300
                      : AppColors.brandOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // === MODE BÌNH THƯỜNG → Input text + mic + send ===
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
          GestureDetector(
            onTap: _toggleEntryVoice,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_none_rounded,
                color: AppColors.brandOrange,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.brandOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // --- Logic Helpers ---

  Future<void> _toggleEntryVoice() async {
    if (_isListening) {
      // === DỪNG GHI ÂM / NHẬN DẠNG ===
      if (_useGroqFallback) {
        await _audioRecorder.stop();
        if (!_mounted) return;

        if (_recordingPath != null) {
          setState(() {
            _isListening = false;
            _isTranscribing = true;
          });

          final text = await GroqSttService.transcribe(_recordingPath!);

          if (!_mounted) return;
          setState(() => _isTranscribing = false);

          if (text != null && text.isNotEmpty) {
            _sendMessage(text);
          }

          // Xóa file tạm
          try {
            final f = File(_recordingPath!);
            if (await f.exists()) await f.delete();
          } catch (_) {}
          _recordingPath = null;
        } else {
          setState(() => _isListening = false);
        }
      } else {
        await _speechToText.stop();
        if (!_mounted) return;
        setState(() => _isListening = false);
        if (_recognizedText.isNotEmpty) {
          final text = _recognizedText;
          _recognizedText = '';
          _sendMessage(text);
        }
      }
    } else {
      // === BẮT ĐẦU GHI ÂM / NHẬN DẠNG ===
      if (_useGroqFallback) {
        final hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission || !_mounted) return;

        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/groq_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

        try {
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.wav,
              sampleRate: 16000,
              numChannels: 1,
            ),
            path: filePath,
          );
          if (!_mounted) return;
          setState(() {
            _isListening = true;
            _recognizedText = '';
            _textController.clear();
            _recordingPath = filePath;
          });
        } catch (_) {}
      } else {
        // Native mode
        if (!_speechToText.isAvailable) {
          if (!await _speechToText.initialize()) return;
        }
        if (!_mounted) return;
        setState(() {
          _isListening = true;
          _recognizedText = '';
          _textController.clear();
        });
        _speechToText.listen(
          onResult: (res) {
            if (!_mounted) return;

            // CJK auto-detect → chuyển Groq im lặng + auto-retry
            if (res.recognizedWords.isNotEmpty && _containsCJK(res.recognizedWords)) {
              _speechToText.stop();
              setState(() {
                _isListening = false;
                _useGroqFallback = true;
                _recognizedText = '';
                _textController.clear();
              });
              // Auto-retry với Groq ngay lập tức
              Future.microtask(() => _toggleEntryVoice());
              return;
            }

            setState(() {
              _recognizedText = res.recognizedWords;
              _textController.text = res.recognizedWords;
            });
            if (res.finalResult && res.recognizedWords.isNotEmpty) {
              _speechToText.stop();
              setState(() => _isListening = false);
              final text = res.recognizedWords;
              _recognizedText = '';
              _textController.clear();
              _sendMessage(text);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: 'vi_VN',
        );
      }
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
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
      if (file != null && _mounted) {
        // Fix: Set pending image để hiện preview kiểu ChatGPT, không show dialog
        setState(() => _pendingImagePath = file.path);
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi ảnh: $e')));
      }
    }
  }

  /// Preview ảnh kiểu ChatGPT: thumbnail nhỏ phía trên input bar với nút X
  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: AppColors.surface,
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_pendingImagePath!),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () => setState(() => _pendingImagePath = null),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Text('Ảnh đã chọn', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _MessageBubble({required this.message});

  Map<String, dynamic>? _action() {
    final md = message.metadata;
    if (md == null) return null;
    final a = md['action'];
    return a is Map<String, dynamic> ? a : null;
  }

  List<dynamic> _citations() {
    final md = message.metadata;
    if (md == null) return const [];
    final c = md['citations'];
    return c is List ? c : const [];
  }

  Widget _buildSafeImage(String path) {
    if (path.isEmpty) return const SizedBox.shrink();
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return _buildBrokenImagePlaceholder();
      }
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildBrokenImagePlaceholder(),
      );
    } catch (_) {
      return _buildBrokenImagePlaceholder();
    }
  }

  Widget _buildBrokenImagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      width: double.infinity,
      height: 100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey, size: 24),
            SizedBox(height: 4),
            Text('Ảnh đã hết hạn', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isUser = message.isUser;

    // Prefer structured action from metadata (RAG v2).
    final action = !isUser ? _action() : null;
    final actionType = action?['type']?.toString();
    final actionSport = action?['sport']?.toString();

    // Backward compatibility: fallback to legacy tags inside text.
    final actionMatch =
        RegExp(r'\[ACTION_SEARCH:([^\]]+)\]').firstMatch(message.text);
    final String? legacySearchSportType =
        !isUser && actionMatch != null ? actionMatch.group(1) : null;

    final String? searchSportType = actionType == 'search_courts'
        ? (actionSport ?? legacySearchSportType)
        : legacySearchSportType;

    final viewSchedule = !isUser &&
        (actionType == 'view_schedule' ||
            message.text.contains('[ACTION_VIEW_SCHEDULE]'));
    final viewExpense = !isUser &&
        (actionType == 'view_expense' ||
            message.text.contains('[ACTION_VIEW_EXPENSE]'));
    final cancelBooking = !isUser &&
        (actionType == 'cancel_booking' ||
            message.text.contains('[ACTION_CANCEL_BOOKING]'));

    final cleanText = message.text
        .replaceAll(RegExp(r'\[ACTION_SEARCH:[^\]]+\]'), '')
        .replaceAll(RegExp(r'\[ACTION_VIEW_SCHEDULE\]'), '')
        .replaceAll(RegExp(r'\[ACTION_VIEW_EXPENSE\]'), '')
        .replaceAll(RegExp(r'\[ACTION_CANCEL_BOOKING\]'), '')
        .trim();

    // Check for "Success Card" trigger
    bool isSuccessCard =
        !isUser && message.type == 'booking_success';

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
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 100,
                                maxWidth: 160,
                              ),
                              child: _buildSafeImage(message.imagePath!),
                            ),
                          ),
                        ),
                      if (cleanText.isNotEmpty)
                        Text(
                          (!isUser && searchSportType != null)
                              ? 'Dưới đây là các sân bạn có thể tham khảo:'
                              : (!isUser && cancelBooking)
                                  ? 'Để hủy sân, bạn vui lòng nhấn vào nút "Hủy sân" bên dưới để chuyển đến màn hình Lịch đặt của tôi nhé.'
                                  : cleanText,
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
          
          // Thêm nút hành động cho các action
          if (!isUser && (viewSchedule || viewExpense || cancelBooking))
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 40),
              child: Row(
                children: [
                  if (viewSchedule)
                    _ActionButton(
                      icon: Icons.calendar_today,
                      label: 'Xem lịch',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
                      ),
                    ),
                  if (viewExpense)
                    _ActionButton(
                      icon: Icons.account_balance_wallet,
                      label: 'Xem chi tiêu',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                      ),
                    ),
                  if (cancelBooking)
                    _ActionButton(
                      icon: Icons.cancel,
                      label: 'Hủy sân',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
                      ),
                    ),
                ],
              ),
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

  void _showCitationsDialog(BuildContext context, List<dynamic> citations) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nguồn tham khảo'),
        content: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: citations.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final c = citations[index];
                final m = c is Map ? c : const {};
                final id = m['id']?.toString() ?? 'S\${index + 1}';
                final title = m['title']?.toString() ?? (m['source']?.toString() ?? 'KB');
                final excerpt = m['excerpt']?.toString() ?? '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\$id • \$title', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (excerpt.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(excerpt, style: const TextStyle(fontSize: 13)),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng', style: TextStyle(color: Colors.blue))),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thanh sóng waveform animation cho recording bar kiểu ChatGPT
class _WaveformBar extends StatefulWidget {
  final int index;
  const _WaveformBar({required this.index});

  @override
  State<_WaveformBar> createState() => _WaveformBarState();
}

class _WaveformBarState extends State<_WaveformBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Mỗi bar có thời gian animation khác nhau → hiệu ứng sóng
    final duration = 300 + (widget.index * 37) % 400;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    )..repeat(reverse: true);

    // Chiều cao random cho mỗi bar
    final minH = 4.0 + (widget.index % 3) * 2;
    final maxH = 10.0 + (widget.index * 7) % 16;
    _animation = Tween<double>(begin: minH, end: maxH).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: 3,
        height: _animation.value,
        decoration: BoxDecoration(
          color: AppColors.brandOrange,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
