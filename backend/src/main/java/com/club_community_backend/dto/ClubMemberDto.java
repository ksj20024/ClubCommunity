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

    // 동아리 내 유저 정보 통합 만능 DTO
    @Getter @Builder
    public static class UserContextResponse {
        // 1. 현재 바라보고 있는 동아리 정보
        private ClubDto.UserJoinedResponse clubInfo;

        // 2. 유저 프로필 정보
        private Long uid;          // 사이트 회원 PK
        private Long clubMemberId;    // 동아리 멤버십 PK (비회원이면 null)
        private String realName;      // 👑 UserEntity 통합 관리 (실시간 연동)
        private String phoneNumber;   // 👑 UserEntity 통합 관리 (실시간 연동)
        private String email;         // ✉️ ClubMemberEntity 고유 관리 (동아리별 독립 이메일)

        // 3. 동아리별 고유 정보 및 권한
        private String studentNo;
        private String clubRole;        // CLUBPRESIDENT, CLUBADMIN, MEMBER, NONE
        private String joinStatus;      // APPROVED, PENDING, REJECTED, NONE
        private boolean isManager;      // 운영진 여부

        // 4. 서류 상세 데이터 (상세조회 플래그 가동 시에만 로드)
        private SubmittedDocResponse submittedDoc;
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