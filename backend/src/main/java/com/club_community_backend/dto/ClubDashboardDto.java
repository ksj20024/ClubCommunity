package com.club_community_backend.dto;

import lombok.Builder;
import lombok.Getter;
import java.time.LocalDateTime;
import java.util.List;

public class ClubDashboardDto {

    @Getter @Builder
    public static class Response {
        private long memberCount;                 // 동아리 정식 소속 멤버 수
        private long todayPostCount;              // 오늘 하루 누적 작성 게시글 수
        private List<NoticeSummary> notices;      // 공지사항 최신글 목록
        private List<ActivitySummary> activities; // 활동 게시판 최신글 목록 (썸네일 포함)
        private List<FreeSummary> frees;          // 자유게시판 최신글 목록 (추천/비추천 포함)
    }

    @Getter @Builder
    public static class NoticeSummary {
        private Long postId;
        private String title;
        private String writerName;
        private LocalDateTime createdAt;
    }

    @Getter @Builder
    public static class ActivitySummary {
        private Long postId;
        private String title;
        private String writerName;
        private String thumbnailUrl; // 📸 활동사진첩 첫 번째 이미지 경로
        private LocalDateTime createdAt;
    }

    @Getter @Builder
    public static class FreeSummary {
        private Long postId;
        private String title;
        private String writerName;
        private int upvoteCount;     // 👍 추천 수 (Entity 필드명 일치)
        private int downvoteCount;   // 👎 비추천 수 (Entity 필드명 일치)
        private LocalDateTime createdAt;
    }
}