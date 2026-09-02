import 'package:club_community_frontend/features/club/screens/post_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 1. Flutter Web 전용 URL 전략 라이브러리 임포트
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/api/api_service.dart';
import 'features/auth/screens/auth_guard_screen.dart';
import 'features/club/create/screens/club_create_screen.dart';
import 'features/club/create/screens/club_form_setting_screen.dart';
import 'features/club/create/screens/club_template_upload_screen.dart';
import 'features/club/screens/club_hub_screen.dart';
import 'features/club/screens/club_join_screen.dart';
import 'features/club/screens/club_search_screen.dart';
import 'features/club/screens/post_form_screen.dart';
import 'features/main/screens/main_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/profile/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await ApiService.initAuth();

  runApp(
    // 🎯 앱 최상단을 ProviderScope로 감싸 전역 상태 창고를 활성화합니다.
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
        textTheme: GoogleFonts.notoSansKrTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      initialRoute: '/auth-guard',
      routes: {
        '/': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/club/create': (context) => const ClubCreateScreen(),
        '/club/form-setting': (context) => const ClubFormSettingScreen(),
        '/club/template-upload': (context) => const ClubTemplateUploadScreen(),
        '/club/hub': (context) => const ClubHubScreen(),
        '/club/board/form': (context) => const PostFormScreen(),
        '/club/search': (context) => const ClubSearchScreen(),
        '/club/join': (context) => const ClubJoinScreen(),
        '/club/board/detail': (context) => const PostDetailScreen(),
        '/auth-guard': (context) => const AuthGuardScreen(),
      },
    );
  }
}