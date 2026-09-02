// lib/features/auth/models/user_info_response.dart

class UserInfoResponse {
  final int id;
  final String userId;
  final String email;
  final String? realName;
  final String? phoneNumber;
  final String role;

  UserInfoResponse({
    required this.id,
    required this.userId,
    required this.email,
    required this.realName,
    required this.phoneNumber,
    required this.role,
  });

  // JSON Map을 객체로 변환하는 팩토리 메서드
  factory UserInfoResponse.fromJson(Map<String, dynamic> json) {
    return UserInfoResponse(
      // 💡 json['id'] as int 대신 num으로 안전하게 받아 컴파일 환경에 맞춰 int로 변환합니다. (Web 빌드 에러 방어)
      id: (json['id'] as num).toInt(),
      userId: json['userId'] as String,
      email: json['email'] as String,
      realName: json['realName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String,
    );
  }
}