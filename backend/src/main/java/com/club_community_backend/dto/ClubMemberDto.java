package com.club_community_backend.dto;

import lombok.*;

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
}