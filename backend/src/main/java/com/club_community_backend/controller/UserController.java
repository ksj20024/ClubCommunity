package com.club_community_backend.controller;

import com.club_community_backend.dto.UserDto;
import com.club_community_backend.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;

    // 회원가입
    @PostMapping("/join")
    public ResponseEntity<String> join(@Valid @RequestBody UserDto.JoinRequest request) {
        userService.join(request);
        return ResponseEntity.ok("회원가입이 완료되었습니다.");
    }

    // 로그인
    @PostMapping("/login")
    public ResponseEntity<UserDto.InfoResponse> login(@Valid @RequestBody UserDto.LoginRequest request) {
        UserDto.InfoResponse response = userService.login(request);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<String> update(@PathVariable Long id, @Valid @RequestBody UserDto.UpdateRequest request) {
        userService.updateUser(id, request);
        return ResponseEntity.ok("회원 정보가 수정되었습니다.");
    }

    @DeleteMapping("/{id}") // /api/users/1 같은 형식으로 요청을 받음
    public ResponseEntity<String> withdraw(
            @PathVariable Long id,
            @Valid @RequestBody UserDto.WithdrawalRequest request) {

        userService.withdraw(id, request);
        return ResponseEntity.ok("회원 탈퇴가 완료되었습니다.");
    }
}
