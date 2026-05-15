package com.club_community_backend.constant;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum UserRole {
    USER("ROLE_USER"),
    SYSADMIN("ROLE_SYSTEM_ADMIN");

    private final String status;
}
