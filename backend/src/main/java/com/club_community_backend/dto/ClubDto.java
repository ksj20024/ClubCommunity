package com.club_community_backend.dto;

import com.club_community_backend.constant.ClubJoinMethodRole;
import com.club_community_backend.constant.ClubTypeRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.EnumSet;

public class ClubDto {

    // 동아리 생성 수정 시 필드 값 검증 메서드 중복 방지
    public interface ClubValidatable {
        String getClubName();
        String getSchoolName();
        String getDomainRestriction();
        String getClubPassword();
        EnumSet<ClubJoinMethodRole> getJoinType();
        ClubTypeRole getClubType();
    }

    @Getter @Builder
    @AllArgsConstructor @NoArgsConstructor
    public static class CreateRequest implements ClubValidatable {
        private String clubName;
        private String schoolName;
        private String domainRestriction;
        private Boolean useAutoCreateApplicationDoc;
        private String clubPassword;
        private EnumSet<ClubJoinMethodRole> joinType;
        private ClubTypeRole clubType;
        private String studentNo;
        private String email;
    }

    @Getter @Builder
    @AllArgsConstructor @NoArgsConstructor
    public static class UpdateRequest implements ClubValidatable {
        private String clubName;
        private String schoolName;
        private String domainRestriction;
        private Boolean useAutoCreateApplicationDoc;
        private String clubPassword;
        private EnumSet<ClubJoinMethodRole> joinType;
        private ClubTypeRole clubType;
    }

    @Getter @Builder
    public static class InfoResponse {
        private Long id;
        private String clubName;
        private String schoolName;
        private String domainRestriction;
        private Boolean useAutoCreateApplicationDoc;
        private String clubPassword; // 필요 시 마스킹 처리하거나 제외
        private EnumSet<ClubJoinMethodRole> joinType;
        private ClubTypeRole clubType;
    }

    @Getter @Builder
    public static class UserJoinedResponse {
        private Long id;
        private String clubName;
        private String schoolName;    // 연합 동아리일 경우 null이 될 수 있음
        private ClubTypeRole clubType; // 일반 / 학교 / 연합
    }

    @Getter
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class ListResponse {
        private Long id;
        private String clubName;
        private String schoolName;
        private ClubTypeRole clubType;
        private EnumSet<ClubJoinMethodRole> clubJoinMethod;
        // 필요하다면 동아리 소개글이나 카테고리 등의 필드 추가
    }

}
