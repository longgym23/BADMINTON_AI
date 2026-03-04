import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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

    // 1. Delegate toàn bộ logic cho Repository (bao gồm cả RAG)
    // Bloc chỉ lo việc gọi hàm, còn Repository sẽ update Stream messages

    // Vì hàm sendMessageWithRAG là async và mất thời gian,
    // ta có thể emit state để UI biết (nếu muốn hiển thị loading bar riêng)
    // Nhưng vì ta dùng Stream để hiển thị list message,
    // ngay khi user gửi, ta nên đảm bảo mesage user hiện lên.
    // Trong logic repository mới, ta lưu message user NGAY LẬP TỨC.
    // Nên UI sẽ update ngay qua Stream.

    try {
      await _chatRepository.sendMessageWithRAG(
        userId,
        event.text,
        imagePath: event.imagePath,
        audioPath: event.audioPath,
      );
    } catch (e) {
      add(_ChatErrorOccurred(e.toString()));
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
