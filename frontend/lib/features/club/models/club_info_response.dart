// lib/features/club_workspace/models/club_info_response.dart

class ClubInfoResponse {
  final int id;
  final String clubName;
  final String? schoolName;    // null 허용 스펙 반영
  final String clubType;       // 일반(GENERAL), 학교(SCHOOL), 연합(UNION) 등 Enum 문자열

  ClubInfoResponse({
    required this.id,
    required this.clubName,
    this.schoolName,
    required this.clubType,
  });

  factory ClubInfoResponse.fromJson(Map<String, dynamic> json) {
    return ClubInfoResponse(
      id: (json['id'] as num).toInt(),
      clubName: json['clubName'] as String? ?? '이름 없는 동아리',
      schoolName: json['schoolName'] as String?,
      clubType: json['clubType'] as String? ?? 'GENERAL',
    );
  }
}