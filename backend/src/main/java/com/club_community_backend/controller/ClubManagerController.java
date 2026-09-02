package com.club_community_backend.controller;

import com.club_community_backend.constant.ClubJoinStatusRole;
import com.club_community_backend.dto.ApiResponse;
import com.club_community_backend.dto.ClubMemberDto;
import com.club_community_backend.security.CustomUserDetails;
import com.club_community_backend.service.ApplicationDocService;
import com.club_community_backend.service.ClubManagerService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/club-management") // 👈 /club-managed에서 더 직관적인 management로 변경
@RequiredArgsConstructor
public class ClubManagerController {

    private final ClubManagerService clubManagerService;
    private final ApplicationDocService applicationDocService;

    // 회장의 가입 질문 항목(JSON 폼) 설정 API
    @PutMapping("/{clubId}/setup-questions")
    public ResponseEntity<ApiResponse<Void>> setupQuestions(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody String settingsJson) {

        clubManagerService.setupFormQuestions(clubId, userDetails.user().getId(), settingsJson);
        return ResponseEntity.ok(ApiResponse.success("동아리 가입 질문 폼 설정이 완료되었습니다."));
    }

    // 회장의 입부 원서 워드 템플릿 파일(.docx) 등록 API
    @PostMapping("/{clubId}/setup-template")
    public ResponseEntity<ApiResponse<Void>> setupTemplate(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestParam("file") MultipartFile file) throws IOException {

        clubManagerService.setupFormTemplate(clubId, userDetails.user().getId(), file);
        return ResponseEntity.ok(ApiResponse.success("입부 원서 문서 템플릿 등록이 완료되었습니다."));
    }

    // 사후 문서 소급 적용 동기화 API
    @PostMapping("/{clubId}/sync-docs")
    public ResponseEntity<ApiResponse<Map<String, Object>>> syncMissingDocs(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        Map<String, Object> result = clubManagerService.syncMissingApplicationDocs(clubId, userDetails.user().getId());
        return ResponseEntity.ok(ApiResponse.success("과거 누락된 입부원서 파일 동기화가 완료되었습니다.", result));
    }

    // 승인 대기 상태의 유저 명단 조회 API
    @GetMapping("/{clubId}/pending")
    public ResponseEntity<ApiResponse<List<ClubMemberDto.PendingResponse>>> getPendingList(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        List<ClubMemberDto.PendingResponse> pendingApplicants =
                clubManagerService.getPendingApplicants(clubId, userDetails.user().getId());

        return ResponseEntity.ok(ApiResponse.success("대기 명단 조회에 성공했습니다.", pendingApplicants));
    }

    // 신청자 가입 승인 API
    @PostMapping("/{clubId}/join/{joinId}/approve")
    public ResponseEntity<ApiResponse<Void>> approveApplicant(
            @PathVariable Long clubId,
            @PathVariable Long joinId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        // 🔒 백엔드가 직접 APPROVED 상태를 고정하여 서비스 호출
        clubManagerService.updateApplicantStatus(clubId, joinId, userDetails.user().getId(), ClubJoinStatusRole.APPROVED);
        return ResponseEntity.ok(ApiResponse.success("동아리 가입이 승인되었습니다."));
    }

    // 신청자 가입 반려(거절) API
    @PostMapping("/{clubId}/join/{joinId}/reject")
    public ResponseEntity<ApiResponse<Void>> rejectApplicant(
            @PathVariable Long clubId,
            @PathVariable Long joinId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        // 🔒 백엔드가 직접 REJECTED 상태를 고정하여 서비스 호출
        clubManagerService.updateApplicantStatus(clubId, joinId, userDetails.user().getId(), ClubJoinStatusRole.REJECTED);
        return ResponseEntity.ok(ApiResponse.success("동아리 가입이 반려되었습니다."));
    }

    // [명단 관리] 유저가 제출한 폼 답변 상세 내용 확인 API
    @GetMapping("/docs/{docId}/detail")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDocDetail(@PathVariable Long docId) {
        Map<String, Object> docDetail = clubManagerService.getDocDetail(docId);
        return ResponseEntity.ok(ApiResponse.success("문서 내용 조회에 성공했습니다.", docDetail));
    }

    // [명단 관리] 유저의 가입 원서 워드 파일 다운로드 API
    @GetMapping("/docs/{docId}/download")
    public ResponseEntity<Resource> downloadDoc(@PathVariable Long docId) {
        Resource resource = applicationDocService.downloadApplicationFile(docId);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"application.docx\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
                .body(resource);
    }
}