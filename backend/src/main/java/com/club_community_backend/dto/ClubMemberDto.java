package com.club_community_backend.dto;

import lombok.*;

import java.time.LocalDateTime;
import java.util.Map;

public class ClubMemberDto {

    @Getter @Builder
    @AllArgsConstructor @NoArgsConstructor
    public static class JoinRequest {
        private String studentNo;      // SCHOOL 타입일 때 필수
        private String clubPassword;    // CODE 방식일 때 필수
        private String email;   // EMAIL 방식일 때 필수
        private Map<String, Object> answers;
    }

    @Getter @Builder
    public static class Response {
        private Long id;
        private String userId;
        private String realName;
        private String clubRole;
        private String joinStatus;
        private String studentNo;
    }

    @Getter
    @Builder
    public static class PendingResponse {
        private Long userId;
        private String userName;
        private String studentNo;
        private String email;
        private LocalDateTime appliedAt;
        // 표 형식 구성을 위해 Map 형태로 답변 전달
        private Map<String, Object> formAnswers;
        private Long applicationDocId; // 문서 상세 조회/다운로드를 위한 ID
    }
}