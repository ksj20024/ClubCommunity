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

}
