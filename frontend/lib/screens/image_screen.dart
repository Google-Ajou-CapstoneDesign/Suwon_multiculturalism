import 'package:flutter/material.dart';
import '../models/chat_response.dart';

class ImageScreen extends StatelessWidget {
  const ImageScreen({super.key, required this.warningCards});

  final List<WarningCard> warningCards;

  static const _severityColor = {
    'high': Color(0xFFDC2626),
    'medium': Color(0xFFD97706),
    'low': Color(0xFF2563EB),
  };

  static const _severityLabel = {
    'high': '위반',
    'medium': '주의',
    'low': '확인',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          '계약서 분석 결과',
          style: TextStyle(color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: warningCards.isEmpty ? _emptyState() : _cardList(),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text(
            '채팅에서 계약서 이미지를 전송하면\n분석 결과가 여기에 표시됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _cardList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryBanner(),
        const SizedBox(height: 12),
        ...warningCards.map(_warningCard),
        const SizedBox(height: 16),
        _disclaimer(),
      ],
    );
  }

  Widget _summaryBanner() {
    final highCount = warningCards.where((c) => c.severity == 'high').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highCount > 0 ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D),
        ),
      ),
      child: Row(
        children: [
          Icon(
            highCount > 0 ? Icons.warning_rounded : Icons.info_outline,
            color: highCount > 0 ? const Color(0xFFDC2626) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '총 ${warningCards.length}개 항목 발견 (위반 $highCount건)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: highCount > 0 ? const Color(0xFFDC2626) : const Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningCard(WarningCard card) {
    final color = _severityColor[card.severity] ?? const Color(0xFF6B7280);
    final label = _severityLabel[card.severity] ?? card.severity;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(card.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(card.content, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '⚠️ 본 서비스는 법적 조언이 아닌 참고용 가이드입니다. 최종 판단은 전문가에게 문의하세요.',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, height: 1.5),
      ),
    );
  }
}
