import 'package:flutter/material.dart';
// 1. Flutter Web 전용 URL 전략 라이브러리 임포트
import 'package:flutter_web_plugins/url_strategy.dart';

import 'features/main/screens/main_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';

void main() {
  // 2. runApp 호출 전에 URL 전략을 Path 방식으로 변경
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '동아리 커뮤니티 플랫폼',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}