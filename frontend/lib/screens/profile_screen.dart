import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.isVerified = false, this.onVerified});

  final bool isVerified;
  final VoidCallback? onVerified;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _idController = TextEditingController();
  String _selectedVisa = 'E-9';
  String _selectedNation = '중국';
  bool _submitting = false;

  static const _visaTypes = ['E-9', 'D-2', 'D-4', 'F-4', 'H-2', 'F-2', 'F-5', 'F-6', 'E-7', 'D-10'];
  static const _nations = ['중국', '베트남', '기타'];

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    if (_idController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비자 번호를 입력해 주세요.')),
      );
      return;
    }
    setState(() => _submitting = true);
    // MVP: 실제 검증 없이 입력값 존재 시 인증 완료 처리
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _submitting = false);
    widget.onVerified?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          '프로필',
          style: TextStyle(color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _avatarSection(),
          const SizedBox(height: 16),
          _verificationSection(),
          const SizedBox(height: 16),
          _infoSection(),
        ],
      ),
    );
  }

  Widget _avatarSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF2563EB),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('익명 사용자', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 4),
              if (widget.isVerified)
                Row(
                  children: const [
                    Icon(Icons.verified, color: Color(0xFF2563EB), size: 16),
                    SizedBox(width: 4),
                    Text('실명 인증 완료', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
                  ],
                )
              else
                const Text('미인증', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verificationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: widget.isVerified ? _verifiedBadge() : _verificationForm(),
    );
  }

  Widget _verifiedBadge() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: const [
              Icon(Icons.verified, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '실명 인증이 완료되었습니다',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D4ED8),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '커뮤니티 서비스를 이용할 수 있습니다.',
                      style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _verificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '실명 인증',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 4),
        const Text(
          '커뮤니티 이용을 위해 비자 정보를 입력해 주세요.\n인증 정보는 국적 확인에만 사용됩니다.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 20),

        // 국적 선택
        const Text('국적', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        _dropdown(
          value: _selectedNation,
          items: _nations,
          onChanged: (v) => setState(() => _selectedNation = v),
        ),
        const SizedBox(height: 14),

        // 비자 유형 선택
        const Text('비자 유형', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        _dropdown(
          value: _selectedVisa,
          items: _visaTypes,
          onChanged: (v) => setState(() => _selectedVisa = v),
        ),
        const SizedBox(height: 14),

        // 비자 번호
        const Text('비자 번호', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: _idController,
          decoration: _inputDecoration('예: A12345678'),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              disabledBackgroundColor: const Color(0xFF93C5FD),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('인증 완료', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _infoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '앱 정보',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.info_outline, 'Local Bridge', 'v1.0.0 MVP'),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          _infoRow(Icons.shield_outlined, '개인정보 처리방침', ''),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
          _infoRow(Icons.help_outline, '이용약관', ''),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Color(0xFF374151), fontSize: 14)),
        const Spacer(),
        if (value.isNotEmpty)
          Text(value, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
        if (value.isEmpty)
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
      ],
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required void Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
        items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
    );
  }
}
