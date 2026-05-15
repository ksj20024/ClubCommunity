package com.club_community_backend.controller;

import com.club_community_backend.constant.ClubJoinStatusRole;
import com.club_community_backend.dto.ClubMemberDto;
import com.club_community_backend.service.ApplicationDocService;
import com.club_community_backend.service.ClubManagerService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/club-members")
@RequiredArgsConstructor
public class ClubManagerController {

    private final ClubManagerService clubManagerService;
    private final ApplicationDocService applicationDocService;

    // 일반 유저 가입 신청 API
    @PostMapping("/{clubId}/join/{userId}")
    public ResponseEntity<String> join(@PathVariable Long clubId,
                                       @PathVariable Long userId,
                                       @RequestBody ClubMemberDto.JoinRequest request) {
        clubManagerService.applyToClub(clubId, userId, request);
        return ResponseEntity.ok("가입 신청 처리가 완료되었습니다.");
    }

    // 회장의 가입 원서 질문 항목(JSON) 및 워드 템플릿 파일 지정 API
    @PostMapping("/{clubId}/setup-form")
    public ResponseEntity<String> setupForm(
            @PathVariable Long clubId,
            @RequestParam Long userId,
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

    // 승인 대기 상태의 유저 명단 조회 API
    @GetMapping("/{clubId}/pending")
    public ResponseEntity<List<ClubMemberDto.PendingResponse>> getPendingList(
            @PathVariable Long clubId,
            @RequestParam Long userId) {
        return ResponseEntity.ok(clubManagerService.getPendingApplicants(clubId, userId));
    }

    // 운영진의 승인 / 반려 결정 처리 API
    @PostMapping("/{clubId}/decision")
    public ResponseEntity<String> decideStatus(
            @PathVariable Long clubId,
            @RequestParam Long managerId,
            @RequestParam Long applicantId,
            @RequestParam ClubJoinStatusRole status) {
        clubManagerService.updateApplicantStatus(clubId, applicantId, managerId, status);
        return ResponseEntity.ok("성공적으로 처리되었습니다.");
    }

    // 표에서 [내용 확인] 버튼 클릭 시 정돈된 폼 답변 데이터를 넘겨주는 API
    @GetMapping("/docs/{docId}/detail")
    public ResponseEntity<Map<String, Object>> getDocDetail(@PathVariable Long docId) {
        return ResponseEntity.ok(clubManagerService.getDocDetail(docId));
    }

    // 표에서 [문서 다운로드] 버튼 클릭 시 워드 원본 파일을 내보내는 API - 추후 pdf 변환 다운로드 추가 예정
    @GetMapping("/docs/{docId}/download")
    public ResponseEntity<Resource> downloadDoc(@PathVariable Long docId) {
        Resource resource = applicationDocService.downloadApplicationFile(docId);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"application.docx\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
                .body(resource);
    }
}