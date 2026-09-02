package com.club_community_backend.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "club_member_telegram_notifications")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ClubNotificationEntity {

    @Id
    @Column(name = "club_member_id")
    private Long id;

    // 주 테이블인 ClubMemberEntity의 PK를 본인 PK로 매핑 (@MapsId)
    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "club_member_id")
    private ClubMemberEntity clubMember;

    @Column(name = "telegram_chat_id", nullable = false)
    private String telegramChatId;

    @Column(name = "is_alert_enabled", nullable = false)
    private boolean isAlertEnabled;

    // 생성자 및 비즈니스 로직 메서드
    public ClubNotificationEntity(ClubMemberEntity clubMember, String telegramChatId, boolean isAlertEnabled) {
        this.clubMember = clubMember;
        this.telegramChatId = telegramChatId;
        this.isAlertEnabled = isAlertEnabled;
    }

    public void updateSettings(String telegramChatId, boolean isAlertEnabled) {
        this.telegramChatId = telegramChatId;
        this.isAlertEnabled = isAlertEnabled;
    }
}