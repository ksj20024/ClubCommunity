// lib/core/providers/club_creation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClubCreationState {
  final int clubId;
  final bool useAutoDoc;

  ClubCreationState({required this.clubId, required this.useAutoDoc});
}

// 🎯 [최신 스펙]: StateProvider 대신 'Notifier'를 상속받습니다.
class ClubCreationNotifier extends Notifier<ClubCreationState?> {
  @override
  ClubCreationState? build() {
    return null; // 초기 상태는 개설 세션 없음(null)
  }

  // 🎯 외부에서 개설 데이터를 주입할 때 안전하게 캡슐화되어 작동할 메서드
  void setCreationState(ClubCreationState newState) {
    state = newState;
  }

  // 🎯 개설 완료 또는 실패 시 창고를 비우는 청소 메서드
  void clear() {
    state = null;
  }
}

// 🎯 [최신 스펙]: NotifierProvider 개설 완료
final clubCreationProvider = NotifierProvider<ClubCreationNotifier, ClubCreationState?>(() {
  return ClubCreationNotifier();
});