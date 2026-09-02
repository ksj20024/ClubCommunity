// lib/core/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/models/user_info_response.dart';

// 🎯 [최신 스펙]: StateNotifier 대신 'Notifier'를 상속받습니다.
class AuthNotifier extends Notifier<UserInfoResponse?> {

  // 🎯 [최신 스펙]: 기존의 생성자 'super(null)' 대신 'build()' 메서드가 초기 상태를 결정합니다.
  @override
  UserInfoResponse? build() {
    return null; // 앱 처음 켜졌을 때의 초기 세션 값 (비로그인 상태)
  }

  // 로그인 성공 및 세션 복원 시 유저 데이터 박제
  void setUser(UserInfoResponse user) {
    state = user; // 내부 변수 state를 교체하는 방식은 동일합니다.
  }

  // 로그아웃 및 회원 탈퇴 시 세션 파기
  void clearUser() {
    state = null;
  }
}

// 🎯 [최신 스펙]: StateNotifierProvider 대신 'NotifierProvider'를 개설합니다.
// 제네릭 순서도 <창고클래스, 상태타입> 으로 더 직관적으로 바뀌었습니다.
final authProvider = NotifierProvider<AuthNotifier, UserInfoResponse?>(() {
  return AuthNotifier();
});