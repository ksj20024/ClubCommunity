// lib/features/club/models/club_dashboard_response.dart

class ClubDashboardResponse {
  final int memberCount;
  final int todayPostCount;
  final List<LatestNoticeDto> notices;
  final List<LatestActivityDto> activities;
  final List<LatestFreePostDto> frees;

  ClubDashboardResponse({
    required this.memberCount,
    required this.todayPostCount,
    required this.notices,
    required this.activities,
    required this.frees,
  });

  factory ClubDashboardResponse.fromJson(Map<String, dynamic> rootJson) {
    // 🛡️ 백엔드의 캡슐화 포맷인 "data" 내부 오브젝트 가드 수립
    final Map<String, dynamic> json = rootJson['data'] != null
        ? rootJson['data'] as Map<String, dynamic>
        : rootJson;

    var noticeList = json['notices'] as List? ?? [];
    var activityList = json['activities'] as List? ?? [];
    var freeList = json['frees'] as List? ?? [];

    return ClubDashboardResponse(
      memberCount: json['memberCount'] ?? 0,
      todayPostCount: json['todayPostCount'] ?? 0,
      notices: noticeList.map((item) => LatestNoticeDto.fromJson(item as Map<String, dynamic>)).toList(),
      activities: activityList.map((item) => LatestActivityDto.fromJson(item as Map<String, dynamic>)).toList(),
      frees: freeList.map((item) => LatestFreePostDto.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

class LatestNoticeDto {
  final int postId;
  final String title;
  final String writerName;
  final String createdAt;

  LatestNoticeDto({
    required this.postId,
    required this.title,
    required this.writerName,
    required this.createdAt,
  });

  factory LatestNoticeDto.fromJson(Map<String, dynamic> json) {
    return LatestNoticeDto(
      postId: json['postId'] ?? 0,
      title: json['title'] ?? '',
      writerName: json['writerName'] ?? '익명',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class LatestActivityDto {
  final int postId; // 💡 [확장]: 상세 페이지 이동 프로세스를 위해 추가
  final String title;
  final String imageUrl;
  final String writerName; // 💡 [확장]: 작성자 매핑 추가
  final String createdAt;  // 💡 [확장]: 생성 시간 추가

  LatestActivityDto({
    required this.postId,
    required this.title,
    required this.imageUrl,
    required this.writerName,
    required this.createdAt,
  });

  factory LatestActivityDto.fromJson(Map<String, dynamic> json) {
    // 🎯 [완치 타격 구역]: 응답 로그에 명시된 'thumbnailUrl'을 가장 최우선 순위로 낚아챕니다!
    final String? rawPath = json['thumbnailUrl'] ?? json['thumbnailResponse'] ?? json['imageUrl'];
    String parsedPath = '';

    if (rawPath != null && rawPath.trim().isNotEmpty) {
      parsedPath = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    }

    return LatestActivityDto(
      postId: json['postId'] ?? json['id'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: parsedPath, // 상대 경로(/storage/posts/...) 완벽 저장
      writerName: json['writerName'] ?? '익명',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class LatestFreePostDto {
  final int postId;
  final String title;
  final String writerName;
  final int upvoteCount;
  final int downvoteCount;
  final String createdAt;

  LatestFreePostDto({
    required this.postId,
    required this.title,
    required this.writerName,
    required this.upvoteCount,
    required this.downvoteCount,
    required this.createdAt,
  });

  factory LatestFreePostDto.fromJson(Map<String, dynamic> json) {
    return LatestFreePostDto(
      postId: json['postId'] ?? 0,
      title: json['title'] ?? '',
      writerName: json['writerName'] ?? '익명',
      upvoteCount: json['upvoteCount'] ?? 0,
      downvoteCount: json['downvoteCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }
}