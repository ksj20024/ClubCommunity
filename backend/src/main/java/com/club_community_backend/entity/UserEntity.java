package com.club_community_backend.entity;

import com.club_community_backend.constant.UserRole;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SoftDelete;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;


@Entity
@Getter
@Builder
@EntityListeners(AuditingEntityListener.class)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
public class UserEntity extends BaseTimeEntity {
    // 사용자 식별 PK - 자동생성
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 사용자 아이디
    @NonNull
    @Column(nullable = false, unique = true)
    private String userId;

    // 사용자 이메일
    @NonNull
    @Column(nullable = false)
    private String email;

    // 사용자 비밀번호
    @NonNull
    @Column(nullable = false)
    private String password;

    // 사용자 이름
    private String realName;

    // 사용자 전화번호 형식)010-xxxx-xxxx
    private String phoneNumber;

    @NonNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    // 관리자 여부 (USER / SYSADMIN)
    private UserRole globalRole;

    @SoftDelete
    @Builder.Default
    private Boolean isDelete = false;
    //private boolean isEmailVerified = false;


    public void updateRealName(String realName) {
        this.realName = realName;
    }

    public void updatePhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public void updateGeneral(String realName, String phoneNumber) {
        updateRealName(realName);
        updatePhoneNumber(phoneNumber);
    }

    public void updatePassword(String newPassword) {
        // 💡 팁: 지금은 평문(Plain Text)으로 저장되지만,
        // 추후 Spring Security가 도입되면 외부에서 암호화된(BCrypt) 비밀번호를 받아 그대로 매핑하게 됩니다.
        this.password = newPassword;
    }

    public void updateEmail(String email) {
        this.email = email;
    }
}
