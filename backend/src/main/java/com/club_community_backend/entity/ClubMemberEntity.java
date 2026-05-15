package com.club_community_backend.entity;

import com.club_community_backend.constant.ClubJoinStatusRole;
import com.club_community_backend.constant.ClubRole;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;


@Entity
@Builder
@Getter
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ClubMemberEntity extends BaseTimeEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY) // 숫자가 아닌 객체로 연결
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id", nullable = false)
    private ClubEntity club;
    private String studentNo;
    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ClubRole clubRole;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ClubJoinStatusRole joinStatus;

    public void updateJoinStatus(ClubJoinStatusRole newStatus) {
        this.joinStatus = newStatus;
    }

    public void updateRole(ClubRole clubRole) {
        this.clubRole = clubRole;
    }
}
