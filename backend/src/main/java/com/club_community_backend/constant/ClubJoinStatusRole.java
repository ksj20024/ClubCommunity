package com.club_community_backend.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum ClubJoinStatusRole {
    PENDING("대기중"),
    APPROVED("승인 완료"),
    REJECTED("가입 반려");

    private final String status;
}
