package com.club_community_backend.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum ClubTypeRole {
    NORMAL("일반 동아리"),
    SCHOOL("학교 소속 동아리"),
    ASSOCIATION("연합 동아리");

    private final String clubType;
}
