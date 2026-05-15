package com.club_community_backend.controller;

import com.club_community_backend.dto.ClubDto;
import com.club_community_backend.service.ClubManagerService;
import com.club_community_backend.service.ClubService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/clubs")
@RequiredArgsConstructor
public class ClubController {

    private final ClubService clubService;
    private final ClubManagerService clubManagerService;

    @PostMapping("/{id}")
    public ResponseEntity<Long> create(@PathVariable Long id, @RequestBody ClubDto.CreateRequest request) {
        return ResponseEntity.ok(clubManagerService.createClubWithPresident(request, id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<String> update(@PathVariable Long id, @RequestBody ClubDto.UpdateRequest request) {
        clubService.updateClub(id, request);
        return ResponseEntity.ok("동아리 정보가 성공적으로 수정되었습니다.");
    }

    @GetMapping("/{id}")
    public ResponseEntity<ClubDto.InfoResponse> getClub(@PathVariable Long id) {
        return ResponseEntity.ok(clubService.getClub(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<String> delete(@PathVariable Long id) {
        clubService.deleteClub(id);
        return ResponseEntity.ok("동아리가 삭제되었습니다.");
    }
}
