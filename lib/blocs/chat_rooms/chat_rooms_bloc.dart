import 'dart:async';
import 'package:badminton_ai/data/repositories/chat_room_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:badminton_ai/domain/usecases/chat_rooms/watch_user_chat_rooms_usecase.dart';

part 'chat_rooms_event.dart';
part 'chat_rooms_state.dart';

class ChatRoomsBloc extends Bloc<ChatRoomsEvent, ChatRoomsState> {
  final WatchUserChatRoomsUseCase _watchUserChatRoomsUseCase;
  StreamSubscription? _roomsSubscription;

  ChatRoomsBloc({required WatchUserChatRoomsUseCase watchUserChatRoomsUseCase})
    : _watchUserChatRoomsUseCase = watchUserChatRoomsUseCase,
      super(ChatRoomsInitial()) {
    on<ChatRoomsLoadStarted>(_onLoadStarted);
    on<_ChatRoomsUpdated>(
      (event, emit) => emit(ChatRoomsLoaded(rooms: event.rooms)),
    );
    on<_ChatRoomsErrorOccurred>(
      (event, emit) => emit(ChatRoomsError(error: event.error)),
    );
  }

  void _onLoadStarted(
    ChatRoomsLoadStarted event,
    Emitter<ChatRoomsState> emit,
  ) {
    emit(ChatRoomsLoading());
    _roomsSubscription?.cancel();
    _roomsSubscription = _watchUserChatRoomsUseCase(event.userId).listen(
      (rooms) {
        if (!isClosed) add(_ChatRoomsUpdated(rooms: rooms));
      },
      onError: (error) {
        if (!isClosed) add(_ChatRoomsErrorOccurred(error: error.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _roomsSubscription?.cancel();
    return super.close();
  }
}
