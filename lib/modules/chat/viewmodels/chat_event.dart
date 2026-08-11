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
  final double? userLat;
  final double? userLng;

  const ChatMessageSent({required this.text, this.imagePath, this.audioPath, this.userLat, this.userLng});

  @override
  List<Object> get props => [text, imagePath ?? '', audioPath ?? '', userLat ?? 0, userLng ?? 0];
}
