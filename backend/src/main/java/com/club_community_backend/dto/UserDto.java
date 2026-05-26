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

    // 일반 정보 수정 요청 DTO
    @Getter
    public static class GeneralUpdateRequest {
        private String realName;
        @NotBlank(message = "전화번호 입력은 필수입니다.")
        @Pattern(regexp = "^01(?:0|1|[6-9])-\\d{3,4}-\\d{4}$", message = "올바른 전화번호 형식이 아닙니다.")
        private String phoneNumber;
    }

    // 비밀번호 변경 요청 DTO
    @Getter
    public static class PasswordChangeRequest {
        @NotBlank(message = "현재 비밀번호를 입력해주세요.")
        private String currentPassword;

        @NotBlank(message = "새로운 비밀번호를 입력해주세요.")
        @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,20}$",
                message = "비밀번호는 영문, 숫자, 특수문자를 포함하여 8자 이상 20자 이하여야 합니다.")
        private String newPassword;
    }

    // 3. 이메일 중복 검증 및 발송 요청 DTO
    @Getter
    public static class EmailVerifyRequest {
        @NotBlank(message = "이메일은 필수 입력 항목입니다.")
        @Email(message = "올바른 이메일 형식이 아닙니다.")
        private String email;
    }

    // 4. 이메일 최종 업데이트 요청 DTO (인증코드 포함)
    @Getter
    public static class EmailUpdateRequest {
        @NotBlank(message = "변경할 이메일을 입력해주세요.")
        @Email(message = "올바른 이메일 형식이 아닙니다.")
        private String email;

        @NotBlank(message = "인증번호를 입력해주세요.")
        private String verificationCode;
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
