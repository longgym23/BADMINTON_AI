import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:badminton_ai/data/models/chat_message_model.dart';
import 'package:badminton_ai/data/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _messagesSubscription;
  String? _userId;

  ChatBloc({required ChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(ChatInitial()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageSent>(_onChatMessageSent);
    on<_ChatMessagesUpdated>((event, emit) => emit(ChatLoaded(event.messages)));
    on<_ChatErrorOccurred>((event, emit) => emit(ChatError(event.error)));
  }

  void _onChatStarted(ChatStarted event, Emitter<ChatState> emit) {
    _userId = event.userId;
    emit(ChatLoading());

    _messagesSubscription?.cancel();
    _messagesSubscription = _chatRepository
        .getMessages(event.userId)
        .listen(
          (messages) {
            add(_ChatMessagesUpdated(messages));
          },
          onError: (error) {
            add(_ChatErrorOccurred(error.toString()));
          },
        );
  }

  void _onChatMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) return;

    // Không emit Loading ở đây để tránh rebuild toàn bộ list làm mất UX
    // (tin nhắn user sẽ hiện ngay nhờ local update hoặc stream)
    // Tuy nhiên, logic ChatProvider cũ có loading indicator cho "AI đang soạn..."
    // Trong BLoC, ta có thể handle việc này bằng cách thêm field isLoading vào State Loaded
    // Hoặc đơn giản là cứ gửi, Stream sẽ update tin nhắn user.
    // Để hiển thị "AI đang soạn", ta cần state mới hoặc field trong ChatLoaded.
    // Tạm thời ta sẽ xử lý AI call ở đây.

    try {
      // 1. Lưu tin nhắn User
      final userMessage = ChatMessageModel(
        id: '',
        text: event.text.isEmpty
            ? (event.imagePath != null ? '[Ảnh]' : '[Audio]')
            : event.text,
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: event.imagePath,
        audioPath: event.audioPath,
      );
      await _chatRepository.sendMessage(userId, userMessage);

      // 2. Call API (logic cũ)
      // Để UI hiển thị loading, ta có thể emit state mới hoặc dùng Bloc riêng cho status.
      // Nhưng để đơn giản, ta giữ nguyên Stream lo việc hiển thị tin nhắn.
      // Ta có thể emit 1 event internal để báo đang loading nếu muốn.

      const String backendUrl = 'https://badminton-ai-fgsz.onrender.com/ask';
      String answer = "Xin lỗi, tôi chưa hiểu ý bạn.";

      try {
        http.Response response;

        if (event.imagePath != null) {
          var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
          request.files.add(
            await http.MultipartFile.fromPath('image', event.imagePath!),
          );
          request.fields['prompt'] = event.text.isNotEmpty
              ? event.text
              : 'Phân tích ảnh này';
          var streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        } else if (event.audioPath != null) {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('$backendUrl/audio'),
          );
          request.files.add(
            await http.MultipartFile.fromPath('audio', event.audioPath!),
          );
          if (event.text.isNotEmpty) request.fields['prompt'] = event.text;
          var streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        } else {
          response = await http
              .post(
                Uri.parse(backendUrl),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'prompt': event.text}),
              )
              .timeout(const Duration(seconds: 45));
        }

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          answer = responseBody['answer'] ?? "Xin lỗi, tôi chưa hiểu ý bạn.";
        } else {
          try {
            final responseBody = jsonDecode(response.body);
            answer =
                "Lỗi: " +
                (responseBody['error'] ??
                    'Lỗi server (${response.statusCode})');
          } catch (e) {
            answer = 'Lỗi server (${response.statusCode})';
          }
        }
      } catch (e) {
        answer = "Lỗi kết nối tới server. Vui lòng thử lại sau.";
      }

      // 3. Lưu tin nhắn AI
      final aiMessage = ChatMessageModel(
        id: '',
        text: answer,
        isUser: false,
        timestamp: DateTime.now(),
      );
      await _chatRepository.sendMessage(userId, aiMessage);
    } catch (e) {
      // Handle error silently or via state
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}

// Internal events for Stream updates
class _ChatMessagesUpdated extends ChatEvent {
  final List<ChatMessageModel> messages;
  const _ChatMessagesUpdated(this.messages);
  @override
  List<Object> get props => [messages];
}

class _ChatErrorOccurred extends ChatEvent {
  final String error;
  const _ChatErrorOccurred(this.error);
  @override
  List<Object> get props => [error];
}

extension ChatBlocInternal on ChatBloc {
  void _onChatMessagesUpdated(
    _ChatMessagesUpdated event,
    Emitter<ChatState> emit,
  ) {
    emit(ChatLoaded(event.messages));
  }

  void _onChatErrorOccurred(_ChatErrorOccurred event, Emitter<ChatState> emit) {
    emit(ChatError(event.error));
  }
}
