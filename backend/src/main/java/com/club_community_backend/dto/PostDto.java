package com.club_community_backend.dto;

import com.club_community_backend.constant.ClubBoardType;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

public class PostDto {

    @Getter
    public static class CreateRequest {
        @NotBlank(message = "제목은 필수입니다.")
        private String title;
        @NotBlank(message = "내용은 필수입니다.")
        private String content;
        private ClubBoardType boardType;
    }

    @Getter
    public static class UpdateRequest {
        @NotBlank(message = "제목은 필수입니다.")
        private String title;
        @NotBlank(message = "내용은 필수입니다.")
        private String content;
    }

    @Getter
    @Builder
    public static class ListResponse {
        private Long id;
        private String title;
        private String writerName;
        private int viewCount;
        private int upvoteCount;
        private LocalDateTime createdAt;
        private String thumbnailResponse; // 활동사진첩용 썸네일 경로
    }

    @Getter
    @Builder
    public static class InfoResponse {
        private Long id;
        private String title;
        private String content;
        private String writerName;
        private Long writerId;
        private int viewCount;
        private int upvoteCount;
        private int downvoteCount;
        private LocalDateTime createdAt;
        private List<String> imageUrls;
        private List<CommentResponse> comments;
    }

    @Getter
    @Builder
    public static class CommentResponse {
        private Long id;
        private Long writerId;
        private String writerName;
        private String content;
        private LocalDateTime createdAt;
    }

    @Getter
    public static class CommentRequest {
        @NotBlank(message = "댓글 내용은 필수입니다.")
        private String content;
    }
}