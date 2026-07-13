import 'package:flutter/material.dart';
import '../models/chat_response.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.mapPins, required this.nextActions});

  final List<MapPin> mapPins;
  final List<String> nextActions;

  static const _typeIcon = {
    'labor': Icons.work_outline,
    'welfare': Icons.volunteer_activism_outlined,
    'legal': Icons.gavel_outlined,
  };

  static const _typeLabel = {
    'labor': '노동청',
    'welfare': '복지센터',
    'legal': '법률상담',
  };

  static const _typeColor = {
    'labor': Color(0xFF2563EB),
    'welfare': Color(0xFF059669),
    'legal': Color(0xFF7C3AED),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          '지원 기관 지도',
          style: TextStyle(color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: mapPins.isEmpty ? _emptyState() : _content(),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, size: 64, color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text(
            '"가까운 노동청 찾아줘" 라고 채팅하면\n주변 기관이 여기에 표시됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (nextActions.isNotEmpty) ...[
          _nextActionsCard(),
          const SizedBox(height: 16),
        ],
        const Text(
          '가까운 지원 기관',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 8),
        ...mapPins.map(_pinCard),
      ],
    );
  }

  Widget _nextActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '다음 행동 지침',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8), fontSize: 14),
          ),
          const SizedBox(height: 10),
          ...nextActions.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: const Color(0xFF2563EB),
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E40AF), height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _pinCard(MapPin pin) {
    final color = _typeColor[pin.type] ?? const Color(0xFF6B7280);
    final icon = _typeIcon[pin.type] ?? Icons.place_outlined;
    final label = _typeLabel[pin.type] ?? pin.type;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(pin.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ],
                ),
                if (pin.address != null) ...[
                  const SizedBox(height: 4),
                  Text(pin.address!, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                ],
                if (pin.phone != null) ...[
                  const SizedBox(height: 2),
                  Text('☎ ${pin.phone}', style: const TextStyle(color: Color(0xFF2563EB), fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
