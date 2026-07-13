import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CoLocalApp());
}

class CoLocalApp extends StatelessWidget {
  const CoLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Co-Local',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        fontFamily: 'Pretendard',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
