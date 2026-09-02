package com.club_community_backend.entity;

import com.club_community_backend.constant.ClubBoardType;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "posts")
public class PostEntity extends BaseTimeEntity {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id", nullable = false)
    private ClubEntity club;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ClubBoardType boardType;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Builder.Default
    private int viewCount = 0;

    @Builder.Default
    private int upvoteCount = 0;

    @Builder.Default
    private int downvoteCount = 0;

    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<PostImageEntity> images = new ArrayList<>();

    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<CommentEntity> comments = new ArrayList<>();

    // == 비즈니스 도메리 메서드 ==
    public void updatePost(String title, String content) {
        this.title = title;
        this.content = content;
    }

    public void increaseViewCount() { this.viewCount++; }
    public void increaseUpvote() { this.upvoteCount++; }
    public void decreaseUpvote() { this.upvoteCount = Math.max(0, this.upvoteCount - 1); }
    public void increaseDownvote() { this.downvoteCount++; }
    public void decreaseDownvote() { this.downvoteCount = Math.max(0, this.downvoteCount - 1); }

    public void addPostImage(PostImageEntity image) {
        this.images.add(image);
    }
}