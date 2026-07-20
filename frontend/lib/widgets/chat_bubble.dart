import 'dart:io';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  static const _userColor = Color(0xFF2563EB);
  static const _botColor = Color(0xFFF3F4F6);
  static const _botTextColor = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: message.isUser ? _userRow() : _botRow(),
    );
  }

  // ── 사용자 말풍선 ──────────────────────────────────────
  Widget _userRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Spacer(),
        Flexible(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.image != null) _imagePreview(message.image!),
              if (message.text != null && message.text!.isNotEmpty)
                _bubble(
                  text: message.text!,
                  bgColor: _userColor,
                  textColor: Colors.white,
                  isUser: true,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── 봇 말풍선 ──────────────────────────────────────────
  Widget _botRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 8),
        _avatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.text != null && message.text!.isNotEmpty)
                _bubble(
                  text: message.text!,
                  bgColor: _botColor,
                  textColor: _botTextColor,
                  isUser: false,
                ),
            ],
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _avatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF2563EB),
      child: const Icon(Icons.location_city, color: Colors.white, size: 16),
    );
  }

  Widget _bubble({
    required String text,
    required Color bgColor,
    required Color textColor,
    required bool isUser,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 15, height: 1.4)),
    );
  }

  Widget _imagePreview(File file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image, color: Colors.grey, size: 40),
          ),
        ),
      ),
    );
  }

}

// ── 날짜 구분선 ──────────────────────────────────────────
class DateSeparator extends StatelessWidget {
  const DateSeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        ],
      ),
    );
  }
}

// ── 로딩 인디케이터 말풍선 ────────────────────────────────
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF2563EB),
            child: const Icon(Icons.location_city, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    color: Color(0xFF2563EB),
                    backgroundColor: Color(0xFFBFDBFE),
                  ),
                ),
                SizedBox(width: 8),
                Text('분석 중...', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
