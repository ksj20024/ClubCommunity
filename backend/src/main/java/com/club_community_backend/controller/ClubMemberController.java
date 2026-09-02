package com.club_community_backend.controller;

import com.club_community_backend.dto.ApiResponse;
import com.club_community_backend.dto.ApplicationFormDto;
import com.club_community_backend.dto.ClubMemberDto;
import com.club_community_backend.security.CustomUserDetails;
import com.club_community_backend.service.ApplicationFormService;
import com.club_community_backend.service.ClubManagerService;
import com.club_community_backend.service.ClubMemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/club-members")
@RequiredArgsConstructor
public class ClubMemberController {

    private final ClubManagerService clubManagerService;
    private final ClubMemberService clubMemberService;
    private final ApplicationFormService applicationFormService;

    // 🎯 [추가] 내 동아리 전용 텔레그램 알림 정보 등록 및 수정 API
    @PutMapping("/{clubId}/telegram")
    public ResponseEntity<ApiResponse<Void>> updateTelegram(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody ClubMemberDto.UpdateTelegramRequest request) {

        clubMemberService.updateTelegramSettings(clubId, userDetails.user().getId(), request);
        return ResponseEntity.ok(ApiResponse.success("텔레그램 연동 설정이 성공적으로 저장되었습니다."));
    }

    // 1. 일반 유저 동아리 가입 신청 API
    @PostMapping("/{clubId}/join")
    public ResponseEntity<ApiResponse<Void>> join(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody ClubMemberDto.JoinRequest request) {

        clubManagerService.applyToClub(clubId, userDetails.user().getId(), request);
        return ResponseEntity.ok(ApiResponse.success("가입 신청 처리가 완료되었습니다."));
    }

    // 글쓰기 / 페이지 접근 제어용 권한 조회 (서류 미포함 -> 가볍게 작동)
    @GetMapping("/{clubId}/my-auth")
    public ResponseEntity<ApiResponse<ClubMemberDto.UserContextResponse>> getMyMembershipAuth(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        // 마지막 인자를 false로 주어 무거운 서류 데이터 조회를 생략합니다.
        ClubMemberDto.UserContextResponse response =
                clubMemberService.getClubUserContext(clubId, userDetails.user().getId(), false);

        return ResponseEntity.ok(ApiResponse.success("동아리 내 권한 확인에 성공했습니다.", response));
    }

    // [API 2] 내 동아리 가입 정보 상세 조회 (서류 포함 -> 상세하게 작동)
    @GetMapping("/{clubId}/my-membership")
    public ResponseEntity<ApiResponse<ClubMemberDto.UserContextResponse>> getMyMembershipDetail(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        // 마지막 인자를 true로 주어 과거 제출했던 폼 답변까지 꽉 채워서 가져옵니다.
        ClubMemberDto.UserContextResponse response =
                clubMemberService.getClubUserContext(clubId, userDetails.user().getId(), true);

        return ResponseEntity.ok(ApiResponse.success("내 동아리 상세 정보 및 서류 조회가 완료되었습니다.", response));
    }

    // [API 4] 동아리 정식 회원 목록 명부 조회 API
    @GetMapping("/{clubId}/members")
    public ResponseEntity<ApiResponse<List<ClubMemberDto.MemberListResponse>>> getClubMembers(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        List<ClubMemberDto.MemberListResponse> response =
                clubMemberService.getClubMemberList(clubId, userDetails.user().getId());

        return ResponseEntity.ok(ApiResponse.success("동아리 정식 회원 목록 조회에 성공했습니다.", response));
    }

    // [API 5] 유저가 [가입 신청하기] 버튼을 누를 때, 동적 질문 항목들을 받아오기 위한 API
    @GetMapping("/{clubId}/application-form")
    public ResponseEntity<ApiResponse<ApplicationFormDto.FormTemplateResponse>> getClubFormTemplate(
            @PathVariable Long clubId) {

        ApplicationFormDto.FormTemplateResponse response = applicationFormService.getClubFormTemplate(clubId);
        return ResponseEntity.ok(ApiResponse.success("동아리 가입 양식 템플릿 조회에 성공했습니다.", response));
    }

    // 🎯 [추가] 내 동아리 가입 기본 정보(학번, 이메일) 수정 API
    @PutMapping("/{clubId}/basic-info")
    public ResponseEntity<ApiResponse<Void>> updateMemberBasicInfo(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody ClubMemberDto.UpdateBasicInfoRequest request) {

        clubMemberService.updateMemberBasicInfo(clubId, userDetails.user().getId(), request);
        return ResponseEntity.ok(ApiResponse.success("동아리 가입 기본 정보가 수정되었습니다."));
    }

    // 🎯 [추가] 내가 제출했던 동아리 가입 신청서 서류(질문 답변) 수정 API
    @PutMapping("/{clubId}/application-doc")
    public ResponseEntity<ApiResponse<Void>> updateFormAnswers(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody ClubMemberDto.UpdateFormAnswersRequest request) {

        clubMemberService.updateSubmittedFormAnswers(clubId, userDetails.user().getId(), request);
        return ResponseEntity.ok(ApiResponse.success("제출한 가입 신청서 서류가 성공적으로 수정되었습니다."));
    }
}