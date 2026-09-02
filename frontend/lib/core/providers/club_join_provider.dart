// lib/features/club/providers/club_join_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClubJoinState {
  final String email;
  final String studentNo;
  final String clubPassword;
  final Map<String, Object> answers;

  ClubJoinState({
    this.email = '',
    this.studentNo = '',
    this.clubPassword = '',
    this.answers = const {},
  });

  ClubJoinState copyWith({
    String? email,
    String? studentNo,
    String? clubPassword,
    Map<String, Object>? answers,
  }) {
    return ClubJoinState(
      email: email ?? this.email,
      studentNo: studentNo ?? this.studentNo,
      clubPassword: clubPassword ?? this.clubPassword,
      answers: answers ?? this.answers,
    );
  }

  Map<String, dynamic> toJson({required bool isSchoolClub, required bool isCodeRequired}) {
    return {
      'email': email.trim(),
      'studentNo': isSchoolClub ? studentNo.trim() : null,
      'clubPassword': isCodeRequired ? clubPassword.trim() : null,
      'answers': answers,
    };
  }
}

// 🎯 [교정]: export 리스트에 확실히 존재하는 'Notifier'를 무조건 상속받습니다.
class ClubJoinNotifier extends Notifier<ClubJoinState> {

  @override
  ClubJoinState build() {
    return ClubJoinState(); // 초기 상태 도화지 수립
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updateStudentNo(String studentNo) {
    state = state.copyWith(studentNo: studentNo);
  }

  void updateClubPassword(String password) {
    state = state.copyWith(clubPassword: password);
  }

  void updateAnswer(String key, Object value) {
    final updatedAnswers = Map<String, Object>.from(state.answers);
    updatedAnswers[key] = value;
    state = state.copyWith(answers: updatedAnswers);
  }

  // 💡 가입 창을 나갈 때 명시적으로 메모리를 청소할 수 있도록 수동 메서드 보존
  void clear() {
    state = ClubJoinState();
  }
}

// 🎯 [교정]: export 리스트에 명시된 진짜 주인 'NotifierProvider'로 선언을 전면 교체합니다.
final clubJoinProvider = NotifierProvider<ClubJoinNotifier, ClubJoinState>(
      () => ClubJoinNotifier(),
);