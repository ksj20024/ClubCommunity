// lib/features/auth/screens/auth_guard_screen.dart 수정본
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 💡 추가
import '../../../core/api/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/user_info_response.dart';

// 🎯 ConsumerStatefulWidget으로 변경하여 Riverpod 창고에 접근할 권한을 얻습니다.
class AuthGuardScreen extends ConsumerStatefulWidget {
  const AuthGuardScreen({super.key});

  @override
  ConsumerState<AuthGuardScreen> createState() => _AuthGuardScreenState();
}

class _AuthGuardScreenState extends ConsumerState<AuthGuardScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  void _checkUserSession() async {
    final result = await ApiService.getMe();

    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        final loggedInUser = UserInfoResponse.fromJson(result['data']);

        // 🎯 [핵심]: 받아온 유저 알맹이를 Riverpod 세션 창고에 영구 저장!
        ref.read(authProvider.notifier).setUser(loggedInUser);

        // 🚀 이제 짐(arguments) 없이 몸만 가볍게 메인 화면으로 이동합니다.
        Navigator.pushReplacementNamed(context, '/');
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );
  }
}