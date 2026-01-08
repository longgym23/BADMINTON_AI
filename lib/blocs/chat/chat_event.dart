part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ChatStarted extends ChatEvent {
  final String userId;
  const ChatStarted(this.userId);

  @override
  List<Object> get props => [userId];
}

class ChatMessageSent extends ChatEvent {
  final String text;
  final String? imagePath;
  final String? audioPath;

  const ChatMessageSent({required this.text, this.imagePath, this.audioPath});

  @override
  List<Object> get props => [text, imagePath ?? '', audioPath ?? ''];
}
