package com.club_community_backend.entity;

import com.club_community_backend.constant.UserRole;
import com.club_community_backend.dto.UserDto;
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

    public void updateUser(UserDto.UpdateRequest dto) {
        this.email = dto.getEmail();

        // 비밀번호가 입력된 경우에만 수정 (수정 안 할 때 빈 값으로 올 수 있음)
        if (dto.getPassword() != null && !dto.getPassword().isBlank()) {
            this.password = dto.getPassword();
        }

        this.realName = dto.getRealName();
        this.phoneNumber = dto.getPhoneNumber();
    }

    public void updateRealName(String realName) {
        this.realName = realName;
    }

    public void updatePhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }
}
