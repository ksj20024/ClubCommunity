package com.club_community_backend.entity;

import jakarta.persistence.Entity;
import lombok.*;

import java.time.LocalDateTime;

//@Entity
//@Getter
//@Builder
//@AllArgsConstructor
//@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class EmailVerificationEntity {
    private Long id;
    private String email;
    private String code;
    private LocalDateTime expiryDate;

    public boolean isExpired() {
        return LocalDateTime.now().isAfter(expiryDate);
    }
}
