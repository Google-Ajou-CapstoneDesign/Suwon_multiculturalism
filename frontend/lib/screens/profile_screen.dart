import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('프로필', style: TextStyle(color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: const Center(
        child: Text('프로필 기능은 준비 중입니다.', style: TextStyle(color: Color(0xFF9CA3AF))),
      ),
    );
  }
}
