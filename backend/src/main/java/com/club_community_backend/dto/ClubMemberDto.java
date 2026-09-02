package com.club_community_backend.dto;

import lombok.*;
import java.time.LocalDateTime;
import java.util.Map;

public class ClubMemberDto {

    @Getter @Builder
    @AllArgsConstructor @NoArgsConstructor
    public static class JoinRequest {
        private String studentNo;
        private String clubPassword;
        private String email;
        private Map<String, Object> answers;
    }

    @Getter @Setter @Builder
    @AllArgsConstructor @NoArgsConstructor
    public static class UpdateTelegramRequest {
        private String telegramChatId;
        private boolean isAlertEnabled;
    }

    // 동아리 내 유저 정보 통합 만능 DTO
    @Getter @Builder
    public static class UserContextResponse {
        private ClubDto.UserJoinedResponse clubInfo;

        private Long uid;
        private Long clubMemberId;
        private String realName;
        private String phoneNumber;
        private String email;

        private String studentNo;
        private String clubRole;
        private String joinStatus;
        private boolean isManager;

        // 현재 이 사람의 텔레그램 연동 ID (null이면 연동 안 됨 상태로 프론트 처리)
        private String telegramChatId;
        // 알림 수신 On/Off 스위치 상태
        private boolean isAlertEnabled;

        private SubmittedDocResponse submittedDoc;
        private String formSettings;
    }

    // 1. 학번 및 이메일 수정 요청 DTO
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateBasicInfoRequest {
        private String studentNo;
        private String email;
    }

    // 2. 가입 신청서 폼 답변 수정 요청 DTO
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateFormAnswersRequest {
        // 기존 UserContextResponse의 submittedDoc 구조에 맞춘 타입 (Map 또는 String 등 기존 필드 타입에 맞게 맞춰주세요)
        private Map<String, Object> formAnswers;
    }

    @Getter @Builder
    public static class SubmittedDocResponse {
        private Long id;
        private Map<String, Object> formAnswers;
        private String docPdfUrl;
    }

    @Getter @Builder
    public static class PendingResponse {
        private Long id;
        private String userName;
        private String studentNo;
        private String email;
        private LocalDateTime appliedAt;
        private Map<String, Object> formAnswers;
        private Long applicationDocId;
    }

    @Getter @Builder
    public static class MemberListResponse {
        private Long clubMemberId;    // 동아리 멤버십 PK
        private Long userId;          // 사이트 회원 PK
        private String realName;      // 👑 UserEntity에서 실시간 조인
        private String studentNo;     // ClubMemberEntity (학번)
        private String email;         // ClubMemberEntity (동아리 활동 이메일)
        private String clubRole;      // CLUBPRESIDENT, CLUBADMIN, MEMBER
        private LocalDateTime joinedAt; // 가입 승인 일자 (BaseTimeEntity의 createdAt 활용)
    }

}