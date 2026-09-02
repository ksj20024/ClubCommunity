package com.club_community_backend.controller;

import com.club_community_backend.constant.ClubBoardType;
import com.club_community_backend.constant.VoteType;
import com.club_community_backend.dto.ApiResponse;
import com.club_community_backend.dto.PostDto;
import com.club_community_backend.security.CustomUserDetails;
import com.club_community_backend.service.PostService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/clubs/{clubId}/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;

    // 1. 게시글 작성 (ACTIVITY 앨범 업로드를 고려하여 Multipart 수용)
    @PostMapping
    public ResponseEntity<ApiResponse<Long>> createPost(
            @PathVariable Long clubId,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestPart("post") PostDto.CreateRequest request,
            @RequestPart(value = "files", required = false) List<MultipartFile> files) throws IOException {

        Long postId = postService.createPost(clubId, userDetails.user().getId(), request, files);
        return ResponseEntity.ok(ApiResponse.success("게시글이 등록되었습니다.", postId));
    }

    // 2. 특정 게시판 페이징 목록 조회 (예: /posts?type=FREE&page=0&size=10)
    @GetMapping
    public ResponseEntity<ApiResponse<Page<PostDto.ListResponse>>> getPosts(
            @PathVariable Long clubId,
            @RequestParam("type") ClubBoardType boardType,
            @PageableDefault(size = 10) Pageable pageable) {

        Page<PostDto.ListResponse> postList = postService.getPostList(clubId, boardType, pageable);
        return ResponseEntity.ok(ApiResponse.success("게시글 목록 조회에 성공했습니다.", postList));
    }

    // 3. 게시글 단건 상세 조회
    @GetMapping("/{postId}")
    public ResponseEntity<ApiResponse<PostDto.InfoResponse>> getPostDetail(@PathVariable Long postId) {
        PostDto.InfoResponse detail = postService.getPostDetail(postId);
        return ResponseEntity.ok(ApiResponse.success("게시글 상세 조회에 성공했습니다.", detail));
    }

    // 4. 게시글 수정
    @PutMapping("/{postId}")
    public ResponseEntity<ApiResponse<Void>> updatePost(
            @PathVariable Long postId,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody PostDto.UpdateRequest request) {

        postService.updatePost(postId, userDetails.user().getId(), request);
        return ResponseEntity.ok(ApiResponse.success("게시글이 성공적으로 수정되었습니다."));
    }

    // 5. 게시글 삭제
    @DeleteMapping("/{postId}")
    public ResponseEntity<ApiResponse<Void>> deletePost(
            @PathVariable Long clubId,
            @PathVariable Long postId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        postService.deletePost(clubId, postId, userDetails.user().getId());
        return ResponseEntity.ok(ApiResponse.success("게시글이 삭제되었습니다."));
    }

    // 6. 댓글 작성
    @PostMapping("/{postId}/comments")
    public ResponseEntity<ApiResponse<Void>> createComment(
            @PathVariable Long postId,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody PostDto.CommentRequest request) {

        postService.createComment(postId, userDetails.user().getId(), request);
        return ResponseEntity.ok(ApiResponse.success("댓글이 등록되었습니다."));
    }

    // 7. 댓글 삭제
    @DeleteMapping("/comments/{commentId}")
    public ResponseEntity<ApiResponse<Void>> deleteComment(
            @PathVariable Long commentId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        postService.deleteComment(commentId, userDetails.user().getId());
        return ResponseEntity.ok(ApiResponse.success("댓글이 삭제되었습니다."));
    }

    // 8. 게시글 추천 / 비추천 투표 토글
    @PostMapping("/{postId}/vote")
    public ResponseEntity<ApiResponse<Void>> votePost(
            @PathVariable Long postId,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestParam("type") VoteType voteType) {

        postService.votePost(postId, userDetails.user().getId(), voteType);
        return ResponseEntity.ok(ApiResponse.success("투표 처리가 완료되었습니다."));
    }
}