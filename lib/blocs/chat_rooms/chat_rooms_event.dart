part of 'chat_rooms_bloc.dart';

abstract class ChatRoomsEvent extends Equatable {
  const ChatRoomsEvent();

  @override
  List<Object?> get props => [];
}

class ChatRoomsLoadStarted extends ChatRoomsEvent {
  final String userId;

  const ChatRoomsLoadStarted({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class _ChatRoomsUpdated extends ChatRoomsEvent {
  final List<ChatRoom> rooms;

  const _ChatRoomsUpdated({required this.rooms});

  @override
  List<Object?> get props => [rooms];
}

class _ChatRoomsErrorOccurred extends ChatRoomsEvent {
  final String error;

  const _ChatRoomsErrorOccurred({required this.error});

  @override
  List<Object?> get props => [error];
}
