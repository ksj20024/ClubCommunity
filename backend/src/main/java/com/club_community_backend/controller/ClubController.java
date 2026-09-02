package com.club_community_backend.controller;

import com.club_community_backend.dto.ApiResponse;
import com.club_community_backend.dto.ClubDashboardDto;
import com.club_community_backend.dto.ClubDto;
import com.club_community_backend.security.CustomUserDetails;
import com.club_community_backend.service.ClubManagerService;
import com.club_community_backend.service.ClubService;
import com.club_community_backend.service.PostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/clubs")
@RequiredArgsConstructor
public class ClubController {

    private final PostService postService;
    private final ClubService clubService;
    private final ClubManagerService clubManagerService;

    // [API 1] 동아리 생성 (URL에서 {id} 제거 -> 세션 유저를 회장으로 임명)
    @PostMapping
    public ResponseEntity<ApiResponse<Long>> create(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody ClubDto.CreateRequest request) {

        Long clubId = clubManagerService.createClubWithPresident(request, userDetails.user().getId());
        return ResponseEntity.ok(ApiResponse.success("동아리가 생성되었습니다.", clubId));
    }

    // [API 2] 동아리 정보 수정 (여기서 {id}는 동아리 ID이므로 유지)
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> update(@PathVariable Long id, @RequestBody ClubDto.UpdateRequest request) {
        clubService.updateClub(id, request);
        return ResponseEntity.ok(ApiResponse.success("동아리 정보가 성공적으로 수정되었습니다."));
    }

    // [API 3] 동아리 상세 조회 (여기서 {id}는 동아리 ID이므로 유지)
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ClubDto.InfoResponse>> getClub(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("동아리를 정상적으로 조회했습니다.", clubService.getClub(id)));
    }

    // [API 4] 동아리 삭제 (여기서 {id}는 동아리 ID이므로 유지)
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
        clubService.deleteClub(id);
        return ResponseEntity.ok(ApiResponse.success("동아리가 삭제되었습니다."));
    }

    // [API 5] 메인 홈 화면 등에서 사용할 전체 동아리 목록 조회 API (비로그인 허용 영역으로 빼도 좋습니다)
    @GetMapping
    public ResponseEntity<ApiResponse<List<ClubDto.ListResponse>>> getClubList() {
        List<ClubDto.ListResponse> response = clubService.getAllClubs();
        return ResponseEntity.ok(ApiResponse.success("동아리 목록 조회에 성공했습니다.", response));
    }

    // [API 6] 동아리 메인 화면에서 사용할 글, 유저수 등 조회목록
    @GetMapping("/{id}/dashboard")
    public ResponseEntity<ApiResponse<ClubDashboardDto.Response>> getClubMainDashboard(
            @PathVariable Long id,
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        // PostService에 만들어 둔 종합 처리기 호출
        ClubDashboardDto.Response response = postService.getClubDashboard(id);

        return ResponseEntity.ok(ApiResponse.success("동아리 메인 화면 데이터를 성공적으로 로드했습니다.", response));
    }
}