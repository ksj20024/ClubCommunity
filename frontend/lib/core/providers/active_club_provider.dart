// lib/core/providers/active_club_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/models/user_context_response.dart';

class ActiveClubNotifier extends Notifier<UserContextResponse?> {
  @override
  UserContextResponse? build() => null;

  // 세션 정보 주입 및 업데이트 통합 제어
  void setClubSession(UserContextResponse session) {
    state = session;
  }

  void clear() {
    state = null;
  }
}

final activeClubProvider = NotifierProvider<ActiveClubNotifier, UserContextResponse?>(() {
  return ActiveClubNotifier();
});