import 'package:flutter/material.dart';
import '../models/chat_response.dart';
import 'chat_screen.dart';
import 'image_screen.dart';
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

  // 채팅 → 이미지 탭, 지도 탭으로 공유되는 데이터
  List<WarningCard> _warningCards = [];
  List<MapPin> _mapPins = [];
  List<String> _nextActions = [];

  void _onChatResult(List<WarningCard> cards, List<MapPin> pins, List<String> actions) {
    setState(() {
      _warningCards = cards;
      _mapPins = pins;
      _nextActions = actions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ChatScreen(
        onResult: _onChatResult,
        onGoToImageTab: () => setState(() => _selectedIndex = 1),
      ),
      ImageScreen(warningCards: _warningCards),
      MapScreen(mapPins: _mapPins, nextActions: _nextActions),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    const items = [
      BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
      BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: '문서'),
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
