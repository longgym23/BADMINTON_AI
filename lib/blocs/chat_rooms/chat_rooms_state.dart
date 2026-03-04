part of 'chat_rooms_bloc.dart';

abstract class ChatRoomsState extends Equatable {
  const ChatRoomsState();

  @override
  List<Object?> get props => [];
}

class ChatRoomsInitial extends ChatRoomsState {}

class ChatRoomsLoading extends ChatRoomsState {}

class ChatRoomsLoaded extends ChatRoomsState {
  final List<ChatRoom> rooms;

  const ChatRoomsLoaded({required this.rooms});

  @override
  List<Object?> get props => [rooms];
}

class ChatRoomsError extends ChatRoomsState {
  final String error;

  const ChatRoomsError({required this.error});

  @override
  List<Object?> get props => [error];
}
