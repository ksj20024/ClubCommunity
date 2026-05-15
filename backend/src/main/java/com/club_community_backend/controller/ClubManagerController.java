package com.club_community_backend.controller;

import com.club_community_backend.dto.ClubMemberDto;
import com.club_community_backend.service.ClubManagerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequestMapping("/api/club-members")
@RequiredArgsConstructor
public class ClubManagerController {
    private final ClubManagerService clubManagerService;

    @PostMapping("/{clubId}/join/{userId}")
    public ResponseEntity<String> join(@PathVariable Long clubId, @PathVariable Long userId, @RequestBody ClubMemberDto.JoinRequest request) {
        clubManagerService.applyToClub(clubId, userId, request);
        return ResponseEntity.ok("가입 신청 처리가 완료되었습니다.");
    }

//    @PostMapping("/{clubId}/setup-form")
//    public ResponseEntity<String> setupForm(
//            @PathVariable Long clubId,
//            @AuthenticationPrincipal UserPrincipal userPrincipal, // 세션/토큰 유저 정보
//            @RequestPart("file") MultipartFile file,
//            @RequestPart("settings") String settingsJson) throws IOException {
//
//        clubManagerService.setupApplicationForm(
//                clubId,
//                userPrincipal.getId(),
//                file.getBytes(),
//                file.getOriginalFilename(),
//                settingsJson
//        );
//
//        return ResponseEntity.ok("가입 양식 설정이 완료되었습니다.");
//    }

    @PostMapping("/{clubId}/setup-form")
    public ResponseEntity<String> setupForm(
            @PathVariable Long clubId,
            @RequestParam Long userId, // 세션 대신 파라미터로 직접 받음
            @RequestPart("file") MultipartFile file,
            @RequestPart("settings") String settingsJson) {

        try {
            clubManagerService.setupApplicationForm(
                    clubId,
                    userId,
                    file.getBytes(),
                    file.getOriginalFilename(),
                    settingsJson
            );
            return ResponseEntity.ok("가입 양식 설정이 완료되었습니다.");
        } catch (IOException e) {
            return ResponseEntity.internalServerError().body("파일 처리 중 오류 발생");
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        }
    }
}
