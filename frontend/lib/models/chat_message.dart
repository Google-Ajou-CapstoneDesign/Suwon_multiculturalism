import 'dart:io';
import 'chat_response.dart';

enum MessageType { text, image, action }

class ChatMessage {
  final String? text;
  final File? image;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;

  // 봇 응답에서 받은 추가 데이터
  final List<WarningCard> warningCards;
  final List<MapPin> mapPins;
  final List<String> nextActions;

  ChatMessage({
    this.text,
    this.image,
    required this.isUser,
    DateTime? timestamp,
    this.type = MessageType.text,
    this.warningCards = const [],
    this.mapPins = const [],
    this.nextActions = const [],
  }) : timestamp = timestamp ?? DateTime.now();
}
