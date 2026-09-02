// lib/features/club/models/club_application_form.dart
class ClubApplicationForm {
  final String question;
  final String key;
  final String type;

  ClubApplicationForm({
    required this.question,
    required this.key,
    required this.type,
  });

  // 🎯 백엔드에서 온 JSON 맵을 클래스 인스턴스로 안전하게 세니타이징 파싱
  factory ClubApplicationForm.fromJson(Map<String, dynamic> json) {
    return ClubApplicationForm(
      question: json['question'] ?? '질문 문항 없음',
      key: json['key'] ?? '',
      type: json['type'] ?? 'TEXT',
    );
  }

  // 🎯 폼 입력창 속성을 모델이 스스로 판단하게 만듦 (UI 코드 다이어트)
  int get maxLines => type == 'LONG_TEXT' ? 5 : 1;
  int get minLines => type == 'LONG_TEXT' ? 3 : 1;
}