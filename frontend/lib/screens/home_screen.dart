import 'package:flutter/material.dart';
import '../models/chat_response.dart';
import 'chat_screen.dart';
import 'community_screen.dart';
import 'map_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 채팅 → 지도 탭으로 공유되는 데이터
  List<MapPin> _mapPins = [];
  List<String> _nextActions = [];

  // 프로필 실명 인증 상태
  bool _isVerified = false;

  void _onChatResult(List<MapPin> pins, List<String> actions) {
    setState(() {
      _mapPins = pins;
      _nextActions = actions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ChatScreen(onResult: _onChatResult),
      CommunityScreen(
        isVerified: _isVerified,
        onGoToProfile: () => setState(() => _selectedIndex = 4),
      ),
      MapScreen(mapPins: _mapPins, nextActions: _nextActions),
      const NotificationScreen(),
      ProfileScreen(
        isVerified: _isVerified,
        onVerified: () => setState(() => _isVerified = true),
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    const items = [
      BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
      BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: '커뮤니티'),
      BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: '지도'),
      BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: '알림'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '프로필'),
    ];

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2563EB),
      unselectedItemColor: const Color(0xFF9CA3AF),
      backgroundColor: Colors.white,
      elevation: 8,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: items,
    );
  }
}
