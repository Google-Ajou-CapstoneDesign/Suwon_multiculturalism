import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/chat_response.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.onResult});

  /// 백엔드 응답에서 받은 경고 카드·지도 핀·다음 행동을 부모(HomeScreen)에 전달
  final void Function(List<WarningCard> cards, List<MapPin> pins, List<String> actions)? onResult;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <ChatMessage>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  final _sessionId = const Uuid().v4();

  bool _isLoading = false;
  File? _pendingImage;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text:
          'Hello!\nI\'m an AI assistant to help you settle down in Suwon City.\nIs there any service you want? Feel free to ask me anything!',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── 이미지 선택 ────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;
    setState(() => _pendingImage = File(picked.path));
  }

  // ── 메시지 전송 ───────────────────────────────────────
  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    final image = _pendingImage;
    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, image: image, isUser: true));
      _pendingImage = null;
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final res = await ChatService.send(
        sessionId: _sessionId,
        message: text.isEmpty ? '이 계약서를 분석해줘.' : text,
        image: image,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: res.reply,
          isUser: false,
          warningCards: res.warningCards,
          mapPins: res.mapPins,
          nextActions: res.nextActions,
        ));
        _isLoading = false;
      });

      // 부모에게 분석 결과 전달 (이미지 탭·지도 탭 업데이트)
      if (res.hasWarnings || res.hasPins) {
        widget.onResult?.call(res.warningCards, res.mapPins, res.nextActions);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: '오류가 발생했습니다.\n서버 연결을 확인해주세요.\n($e)',
          isUser: false,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── UI ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(),
      body: Column(
        children: [
          Expanded(child: _messageList()),
          if (_pendingImage != null) _imagePreviewBar(),
          _inputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: const BackButton(color: Color(0xFF374151)),
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF2563EB),
            child: const Icon(Icons.location_city, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text(
            'Suwon City',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // 로딩 인디케이터
        if (index == _messages.length) return const TypingIndicator();

        final msg = _messages[index];

        // 날짜 구분선 (첫 메시지 또는 날짜 변경 시)
        final showDate = index == 0 ||
            !_isSameDay(_messages[index - 1].timestamp, msg.timestamp);

        return Column(
          children: [
            if (showDate) DateSeparator(date: msg.timestamp),
            ChatBubble(
              message: msg,
              onActionTap: () {
                // 하단 탭을 '이미지' 탭으로 전환 요청
                DefaultTabController.of(context).animateTo(1);
              },
            ),
          ],
        );
      },
    );
  }

  /// 전송 전 이미지 미리보기 바
  Widget _imagePreviewBar() {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_pendingImage!, width: 56, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('계약서 이미지 첨부됨', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ),
          IconButton(
            onPressed: () => setState(() => _pendingImage = null),
            icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  /// 하단 입력 바
  Widget _inputBar() {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'message...',
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        maxLines: null,
                      ),
                    ),
                    IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined, color: Color(0xFF6B7280)),
                      tooltip: '계약서 이미지 첨부',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
