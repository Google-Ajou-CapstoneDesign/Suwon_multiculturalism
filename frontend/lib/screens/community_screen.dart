import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({
    super.key,
    required this.isVerified,
    this.onGoToProfile,
  });

  final bool isVerified;
  final VoidCallback? onGoToProfile;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedNation = 0; // 0=전체, 1=중국어, 2=베트남어

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          '커뮤니티',
          style: TextStyle(color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: widget.isVerified ? _communityBody() : _lockedBody(),
    );
  }

  // ── 미인증 잠금 화면 ────────────────────────────────────
  Widget _lockedBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 40, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 20),
            const Text(
              '실명 인증이 필요한 서비스입니다',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '같은 국적 근로자와 정보를 안전하게 나누려면\n비자 ID 실명 인증을 완료해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onGoToProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('프로필에서 인증하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '실명 인증 정보는 국적 확인에만 사용되며\n타인에게 공개되지 않습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── 인증 완료 커뮤니티 화면 ─────────────────────────────
  Widget _communityBody() {
    return Column(
      children: [
        _nationFilter(),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(child: _postList()),
      ],
    );
  }

  Widget _nationFilter() {
    const labels = ['전체', '중국어권', '베트남어권'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _selectedNation == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedNation = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _postList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _comingSoonBanner(),
        const SizedBox(height: 16),
        _stubPost(
          title: '비자 갱신 서류 준비 방법 공유합니다',
          body: 'E-9 비자 갱신할 때 필요한 서류 목록이에요. 저는 이렇게 준비했어요...',
          nation: '중국어권',
          time: '2시간 전',
          replies: 4,
        ),
        _stubPost(
          title: '수원시 외국인 복지센터 이용 후기',
          body: '지난주에 임금 관련 상담받고 왔는데 생각보다 친절하게 도와주셨어요.',
          nation: '베트남어권',
          time: '5시간 전',
          replies: 7,
        ),
        _stubPost(
          title: '야간수당 계산 방법 아시는 분?',
          body: '오후 10시 이후 근무하면 어떻게 계산해야 하는지 궁금합니다.',
          nation: '전체',
          time: '어제',
          replies: 2,
        ),
      ],
    );
  }

  Widget _comingSoonBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '커뮤니티 기능은 현재 준비 중입니다.\n곧 실명 인증된 같은 국적 근로자와 소통할 수 있어요.',
              style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stubPost({
    required String title,
    required String body,
    required String nation,
    required String time,
    required int replies,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(nation, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
              ),
              const Spacer(),
              Text(time, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text('댓글 $replies', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
