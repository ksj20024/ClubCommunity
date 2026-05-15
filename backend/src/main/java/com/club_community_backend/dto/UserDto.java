package com.club_community_backend.dto;

import com.club_community_backend.constant.UserRole;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

public class UserDto {

    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class JoinRequest {
        @NotBlank(message = "아이디를 입력해주세요.")
        @Pattern(regexp = "^[a-zA-Z0-9]{6,}$", message = "아이디는 영문과 숫자 6자 이상이어야 합니다.")
        private String userId;
        @NotBlank(message = "비밀번호는 필수입니다.")
        @Pattern(
            regexp = "^(?=.*[a-zA-Z])(?=.*\\d)(?=.*[@$!%*?&#])[A-Za-z\\d@$!%*?&#]{8,}$",
            message = "비밀번호 형식이 올바르지 않습니다. 8자 이상, 영문 포함, 숫자 및 특수문자(@$!%*?&#) 포함"
        )
        private String password;
        @Email
        @Pattern(
            regexp = "^[\\w!#$%&'*+/=?`{|}~^.-]+@[\\w.-]+\\.[a-zA-Z]{2,6}$",
            message = "이메일 형식이 올바르지 않습니다."
        )
        private String email;
        private String realName;
        @Pattern(
            regexp = "^\\d{2,3}-\\d{3,4}-\\d{4}$",
            message = "전화번호 형식이 올바르지 않습니다."
        )
        private String phoneNumber;
    }

    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LoginRequest {
        @NotBlank(message = "아이디를 입력해주세요.")
        @Pattern(regexp = "^[a-zA-Z0-9]{6,}$", message = "아이디는 영문과 숫자 6자 이상이어야 합니다.")
        private String userId;
        @NotBlank(message = "비밀번호는 필수입니다.")
        @Pattern(
                regexp = "^(?=.*[a-zA-Z])(?=.*\\d)(?=.*[@$!%*?&#])[A-Za-z\\d@$!%*?&#]{8,}$",
                message = "비밀번호 형식이 올바르지 않습니다. 8자 이상, 영문 포함, 숫자 및 특수문자(@$!%*?&#) 포함"
        )
        private String password;
    }

    @Getter @Builder
    @AllArgsConstructor @NoArgsConstructor
    public static class UpdateRequest {
        @Email
        @Pattern(
                regexp = "^[\\w!#$%&'*+/=?`{|}~^.-]+@[\\w.-]+\\.[a-zA-Z]{2,6}$",
                message = "이메일 형식이 올바르지 않습니다."
        )
        private String email;
        @NotBlank(message = "비밀번호는 필수입니다.")
        @Pattern(
                regexp = "^(?=.*[a-zA-Z])(?=.*\\d)(?=.*[@$!%*?&#])[A-Za-z\\d@$!%*?&#]{8,}$",
                message = "비밀번호 형식이 올바르지 않습니다. 8자 이상, 영문 포함, 숫자 및 특수문자(@$!%*?&#) 포함"
        )
        private String password; // 암호화 필요
        private String realName;
        @Pattern(
                regexp = "^\\d{2,3}-\\d{3,4}-\\d{4}$",
                message = "전화번호 형식이 올바르지 않습니다."
        )
        private String phoneNumber;
        // globalRole은 일반 유저가 스스로 수정하면 안 되므로 제외 또는 관리자용을 따로 만듦
    }

    @Getter
    @Builder
    public static class InfoResponse {
        private Long id;
        private String userId;
        private String email;
        private String realName;
        private String phoneNumber;
        private UserRole role;
    }

    @Getter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WithdrawalRequest {
        private Long id;
        @NotBlank
        private String password;
    }
}
