package com.club_community_backend.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum ClubRole {
    MEMBER("ROLE_MEMBER"),
    CLUBADMIN("ROLE_CLUB_ADMIN"),
    CLUBPRESIDENT("ROLE_CLUB_PRESIDENT");

    private final String status;
}
