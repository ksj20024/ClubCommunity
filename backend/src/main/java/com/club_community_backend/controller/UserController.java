package com.club_community_backend.controller;

import com.club_community_backend.dto.ApiResponse;
import com.club_community_backend.dto.ClubDto;
import com.club_community_backend.dto.UserDto;
import com.club_community_backend.security.CustomUserDetails;
import com.club_community_backend.service.ClubMemberService;
import com.club_community_backend.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final ClubMemberService clubMemberService;

    // 회원가입 (인증 불필요 - 기존 유지)
    @PostMapping("/join")
    public ResponseEntity<ApiResponse<Void>> join(@Valid @RequestBody UserDto.JoinRequest request) {
        userService.join(request);
        return ResponseEntity.ok(ApiResponse.success("회원가입이 완료되었습니다."));
    }

    // 로그인 (인증 불필요 - 세션 생성 발급)
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<UserDto.InfoResponse>> login(
            @Valid @RequestBody UserDto.LoginRequest request,
            HttpServletRequest servletRequest,
            HttpServletResponse servletResponse) {

        UserDto.InfoResponse response = userService.login(request, servletRequest, servletResponse);
        return ResponseEntity.ok(ApiResponse.success("로그인에 성공했습니다.", response));
    }

    // 1. 일반 정보 업데이트
    @PutMapping("/general")
    public ResponseEntity<ApiResponse<UserDto.InfoResponse>> updateGeneralInfo(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody UserDto.GeneralUpdateRequest request,
            HttpServletRequest servletRequest,
            HttpServletResponse servletResponse) {

        Long currentUserId = userDetails.user().getId();
        UserDto.InfoResponse response = userService.updateGeneralInfo(currentUserId, request);
        userService.refreshSessionAuthentication(currentUserId, servletRequest, servletResponse);

        return ResponseEntity.ok(ApiResponse.success("일반 회원 정보가 수정되었습니다.", response));
    }

    // 2. 비밀번호 변경
    @PutMapping("/password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody UserDto.PasswordChangeRequest request,
            HttpServletRequest servletRequest,
            HttpServletResponse servletResponse) {

        Long currentUserId = userDetails.user().getId();
        userService.changePassword(currentUserId, request);
        userService.refreshSessionAuthentication(currentUserId, servletRequest, servletResponse);

        return ResponseEntity.ok(ApiResponse.success("비밀번호가 성공적으로 변경되었습니다."));
    }

    // 3. 이메일 인증용 메일 발송 (검증만 수행 후 발송 - 기존 유지)
    @PostMapping("/email-verification/send")
    public ResponseEntity<ApiResponse<Void>> sendVerificationEmail(
            @Valid @RequestBody UserDto.EmailVerifyRequest request) {

        userService.sendVerificationEmail(request);
        return ResponseEntity.ok(ApiResponse.success("인증 메일이 발송되었습니다."));
    }

    // 4. 이메일 업데이트
    @PutMapping("/email")
    public ResponseEntity<ApiResponse<UserDto.InfoResponse>> updateEmail(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody UserDto.EmailUpdateRequest request,
            HttpServletRequest servletRequest,
            HttpServletResponse servletResponse) {

        Long currentUserId = userDetails.user().getId();
        UserDto.InfoResponse response = userService.updateEmail(currentUserId, request);
        userService.refreshSessionAuthentication(currentUserId, servletRequest, servletResponse);

        return ResponseEntity.ok(ApiResponse.success("이메일 주소가 성공적으로 변경되었습니다.", response));
    }

    // 회원 탈퇴 (URL에서 {id} 제거)
    @DeleteMapping
    public ResponseEntity<ApiResponse<Void>> withdraw(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody UserDto.WithdrawalRequest request) {

        userService.withdraw(userDetails.user().getId(), request);
        return ResponseEntity.ok(ApiResponse.success("회원 탈퇴가 완료되었습니다."));
    }

    // 특정 유저가 가입한 동아리 목록 조회 API (마이페이지용 - URL에서 {userId} 제거)
    @GetMapping("/clubs")
    public ResponseEntity<ApiResponse<List<ClubDto.UserJoinedResponse>>> getJoinedClubs(
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        List<ClubDto.UserJoinedResponse> responseData = clubMemberService.getJoinedClubs(userDetails.user().getId());
        return ResponseEntity.ok(ApiResponse.success("가입된 동아리 목록 조회에 성공했습니다.", responseData));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserDto.InfoResponse>> getCurrentUser(
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        // 1. 위변조가 불가능한 세션에서 유저의 고유 식별자(ID)만 안전하게 꺼냅니다.
        Long currentUserId = userDetails.user().getId();

        // 2. 해당 ID로 DB를 다시 찔러서 '현재 가장 정확한 최신 데이터'를 가져옵니다.
        UserDto.InfoResponse response = userService.getCurrentUserInfo(currentUserId);

        return ResponseEntity.ok(ApiResponse.success("유효한 세션입니다. 최신 유저 정보를 반환합니다.", response));
    }
}