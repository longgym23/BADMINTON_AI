import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:badminton_ai/data/models/chat_message_model.dart';
import 'package:badminton_ai/data/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  String? _userId;

  ChatBloc({required ChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(ChatInitial()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageSent>(_onChatMessageSent);
  }

  Future<void> _onChatStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    _userId = event.userId;
    emit(ChatLoading());

    try {
      final messages = await _chatRepository.fetchChatHistory(event.userId);
      emit(ChatLoaded(messages));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onChatMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) return;

    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final currentList = List<ChatMessageModel>.from(currentState.messages);

      // 1. Optimistic UI: Hiển thị ngay tin nhắn của User
      final tempUserMessage = ChatMessageModel(
        id: 'temp_user_msg_${DateTime.now().millisecondsSinceEpoch}',
        text: event.text,
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: event.imagePath,
        audioPath: event.audioPath,
      );
      currentList.insert(0, tempUserMessage);

      // Thêm "AI đang gõ..."
      final typingMessage = ChatMessageModel(
        id: 'typing',
        text: 'AI đang nghĩ...',
        isUser: false,
        timestamp: DateTime.now(),
      );
      currentList.insert(0, typingMessage);

      emit(ChatLoaded(List.from(currentList))); // Update UI lập tức

      try {
        // 2. Gửi API (Hàm này sẽ gọi AI và lưu luôn vào DB)
        await _chatRepository.sendMessageWithRAG(
          userId,
          event.text,
          imagePath: event.imagePath,
          audioPath: event.audioPath,
          userLat: event.userLat,
          userLng: event.userLng,
        );

        // 3. Lấy lại toàn bộ lịch sử từ Server để đảm bảo nhất quán & có ID thật
        final updatedMessages = await _chatRepository.fetchChatHistory(userId);
        emit(ChatLoaded(updatedMessages));
      } catch (e) {
        // Lỗi thì fetch lại lịch sử cũ
        final restoredMessages = await _chatRepository.fetchChatHistory(userId);
        emit(ChatLoaded(restoredMessages));
      }
    }
  }
}
