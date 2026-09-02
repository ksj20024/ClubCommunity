// lib/features/auth/models/user_context_response.dart

class UserContextResponse {
  final UserJoinedResponse? clubInfo;
  final int? uid;              // 💡 사이트 회원 PK
  final int? clubMemberId;     // 💡 동아리 멤버십 PK (비회원시 null)
  final String? realName;      // 실시간 연동 실명
  final String? phoneNumber;   // 💡 실시간 연동 전화번호
  final String? email;         // 동아리별 독립 고유 이메일
  final String? studentNo;
  final String? clubRole;      // CLUBPRESIDENT, CLUBADMIN, MEMBER, NONE
  final String? joinStatus;    // APPROVED, PENDING, REJECTED, NONE
  final bool isManager;
  final String? telegramChatId;
  final bool isAlertEnabled;
  final SubmittedDocResponse? submittedDoc;

  UserContextResponse({
    this.clubInfo,
    this.uid,
    this.clubMemberId,
    this.realName,
    this.phoneNumber,
    this.email,
    this.studentNo,
    this.clubRole,
    this.joinStatus,
    this.isManager = false,
    this.telegramChatId,
    required this.isAlertEnabled,
    this.submittedDoc,
  });

  factory UserContextResponse.fromJson(Map<String, dynamic> json) {
    return UserContextResponse(
      clubInfo: json['clubInfo'] != null ? UserJoinedResponse.fromJson(json['clubInfo']) : null,
      uid: json['uid'] as int?,
      clubMemberId: json['clubMemberId'] as int?,
      realName: json['realName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      studentNo: json['studentNo'] as String?,
      clubRole: json['clubRole'] as String?,
      joinStatus: json['joinStatus'] as String?,

      // 🎯 [완치 구역]: 백엔드 Jackson 파서가 보낸 진짜 키값 "manager"를 최우선 맵핑
      isManager: json['manager'] ?? json['isManager'] ?? false,

      telegramChatId: json['telegramChatId'] as String?,

      // 🎯 [완치 구역]: 백엔드 Jackson 파서가 보낸 진짜 키값 "alertEnabled"를 최우선 맵핑
      isAlertEnabled: json['alertEnabled'] ?? json['isAlertEnabled'] ?? false,

      submittedDoc: json['submittedDoc'] != null ? SubmittedDocResponse.fromJson(json['submittedDoc']) : null,
    );
  }

  UserContextResponse copyWith({
    UserJoinedResponse? clubInfo,
    int? uid,
    int? clubMemberId,
    String? realName,
    String? phoneNumber,
    String? email,
    String? studentNo,
    String? clubRole,
    String? joinStatus,
    bool? isManager,
    String? telegramChatId,
    bool? isAlertEnabled,
    SubmittedDocResponse? submittedDoc,
  }) {
    return UserContextResponse(
      clubInfo: clubInfo ?? this.clubInfo,
      uid: uid ?? this.uid,
      clubMemberId: clubMemberId ?? this.clubMemberId,
      realName: realName ?? this.realName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      studentNo: studentNo ?? this.studentNo,
      clubRole: clubRole ?? this.clubRole,
      joinStatus: joinStatus ?? this.joinStatus,
      isManager: isManager ?? this.isManager,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      isAlertEnabled: isAlertEnabled ?? this.isAlertEnabled,
      submittedDoc: submittedDoc ?? this.submittedDoc,
    );
  }
}

class UserJoinedResponse {
  final int? id;
  final String? clubName;
  final String? schoolName;
  final String? clubType;

  UserJoinedResponse({this.id, this.clubName, this.schoolName, this.clubType});

  factory UserJoinedResponse.fromJson(Map<String, dynamic> json) {
    return UserJoinedResponse(
      id: json['id'] as int?,
      clubName: json['clubName'] as String?,
      schoolName: json['schoolName'] as String?,
      clubType: json['clubType'] as String?,
    );
  }
}

class SubmittedDocResponse {
  final int? id;
  final Map<String, dynamic> formAnswers;
  final String? docPdfUrl;

  SubmittedDocResponse({this.id, this.formAnswers = const {}, this.docPdfUrl});

  factory SubmittedDocResponse.fromJson(Map<String, dynamic> json) {
    return SubmittedDocResponse(
      id: json['id'] as int?,
      formAnswers: json['formAnswers'] as Map<String, dynamic>? ?? {},
      docPdfUrl: json['docPdfUrl'] as String?,
    );
  }
}