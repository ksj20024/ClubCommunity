package com.club_community_backend.controller;

import com.club_community_backend.dto.PostAdminResponse;
import com.club_community_backend.entity.ClubNotificationEntity;
import com.club_community_backend.entity.PostEntity;
import com.club_community_backend.repository.ClubNotificationRepository;
import com.club_community_backend.repository.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/internal/agent")
@RequiredArgsConstructor
public class InternalAgentController {

    private final PostRepository postRepository;
    private final ClubNotificationRepository notificationRepository;

    // application.properties를 거쳐 .env의 HERMES_AGENT_SECRET 값을 동적으로 읽어옵니다.
    @Value("${agent.secret-key}")
    private String agentSecretKey;

    @GetMapping("/posts")
    public ResponseEntity<?> getRecentPostsForAgent(
            @RequestHeader("X-Agent-Secret") String secretHeader,
            @RequestParam(value = "lastPostId", defaultValue = "0") Long lastPostId,
            @RequestParam(value = "limit", defaultValue = "20") int limit) {

        // 1. .env 기반 보안 토큰 검증
        if (!agentSecretKey.equals(secretHeader)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Unauthorized Agent Access.");
        }

        // 2. 대상 게시글 조회
        List<PostEntity> posts = postRepository.findPostsForModeration(lastPostId, PageRequest.of(0, limit));
        if (posts.isEmpty()) {
            return ResponseEntity.ok(List.of());
        }

        // 3. 조회된 게시글들의 고유 동아리 ID 목록 추출
        List<Long> clubIds = posts.stream()
                .map(p -> p.getClub().getId())
                .distinct()
                .toList();

        // 4. 동아리별 텔레그램 매핑 그룹핑 (문법 오류 수정 완)
        Map<Long, List<String>> clubTelegramMap = notificationRepository.findActiveChatIdsByClubIds(clubIds)
                .stream()
                .collect(Collectors.groupingBy(
                        tn -> tn.getClubMember().getClub().getId(),
                        Collectors.mapping(ClubNotificationEntity::getTelegramChatId, Collectors.toList())
                ));

        // 5. 최종 DTO 조립
        List<PostAdminResponse> response = posts.stream().map(post -> {
            Long clubId = post.getClub().getId();
            List<String> chatIds = clubTelegramMap.getOrDefault(clubId, new ArrayList<>());

            return new PostAdminResponse(
                    post.getId(),
                    clubId,
                    post.getClub().getClubName(),
                    post.getTitle(),
                    post.getContent(),
                    chatIds
            );
        }).toList();

        return ResponseEntity.ok(response);
    }
}