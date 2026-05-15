package com.club_community_backend.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum ClubJoinMethodRole {
    FREE("자유 가입"),
    EMAIL("이메일 대조"),
    CODE("암호 작성"),
    APPROVAL("관리자 확인");

    private final String description;
}
