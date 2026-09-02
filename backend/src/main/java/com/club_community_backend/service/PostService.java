package com.club_community_backend.service;

import com.club_community_backend.constant.ClubBoardType;
import com.club_community_backend.constant.VoteType;
import com.club_community_backend.dto.ClubDashboardDto;
import com.club_community_backend.dto.PostDto;
import com.club_community_backend.entity.*;
import com.club_community_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PostService {

    private final PostRepository postRepository;
    private final ClubRepository clubRepository;
    private final UserRepository userRepository;
    private final CommentRepository commentRepository;
    private final PostVoteRepository postVoteRepository;
    private final ClubMemberService clubMemberService;
    private final FileStorageService storageService;
    private final ClubMemberRepository clubMemberRepository;

    /**
     * 🎯 동아리 메인 대시보드 종합 데이터 조회
     */
    public ClubDashboardDto.Response getClubDashboard(Long clubId) {
        clubRepository.findById(clubId).orElseThrow(() -> new IllegalArgumentException("동아리를 찾을 수 없습니다."));

        long memberCount = clubMemberRepository.countByClubIdAndJoinStatus(clubId, com.club_community_backend.constant.ClubJoinStatusRole.APPROVED);

        LocalDateTime startOfToday = LocalDateTime.now().with(java.time.LocalTime.MIN);
        long todayPostCount = postRepository.countByClubIdAndCreatedAtAfter(clubId, startOfToday);

        Pageable topThree = PageRequest.of(0, 3);

        List<ClubDashboardDto.NoticeSummary> noticeList = postRepository.findTopPostsByBoardType(clubId, ClubBoardType.NOTICE, topThree)
                .stream().map(p -> ClubDashboardDto.NoticeSummary.builder()
                        .postId(p.getId()).title(p.getTitle()).writerName(p.getUser().getRealName()).createdAt(p.getCreatedAt()).build())
                .toList();

        List<ClubDashboardDto.ActivitySummary> activityList = postRepository.findTopPostsByBoardType(clubId, ClubBoardType.ACTIVITY, topThree)
                .stream().map(p -> ClubDashboardDto.ActivitySummary.builder()
                        .postId(p.getId())
                        .title(p.getTitle())
                        .writerName(p.getUser().getRealName())
                        .thumbnailUrl(p.getImages().isEmpty() ? null : p.getImages().getFirst().getImageUrl())
                        .createdAt(p.getCreatedAt())
                        .build())
                .toList();

        List<ClubDashboardDto.FreeSummary> freeList = postRepository.findTopPostsByBoardType(clubId, ClubBoardType.FREE, topThree)
                .stream().map(p -> ClubDashboardDto.FreeSummary.builder()
                        .postId(p.getId())
                        .title(p.getTitle())
                        .writerName(p.getUser().getRealName())
                        .upvoteCount(p.getUpvoteCount())
                        .downvoteCount(p.getDownvoteCount())
                        .createdAt(p.getCreatedAt())
                        .build())
                .toList();

        return ClubDashboardDto.Response.builder()
                .memberCount(memberCount)
                .todayPostCount(todayPostCount)
                .notices(noticeList)
                .activities(activityList)
                .frees(freeList)
                .build();
    }

    /**
     * 🎯 게시글 작성 (이미지 연관관계 편의 메서드 버그 수정 완료)
     */
    @Transactional
    public Long createPost(Long clubId, Long userId, PostDto.CreateRequest dto, List<MultipartFile> files) throws IOException {
        ClubEntity club = clubRepository.findById(clubId).orElseThrow(() -> new IllegalArgumentException("동아리를 찾을 수 없습니다."));
        UserEntity user = userRepository.findById(userId).orElseThrow(() -> new IllegalArgumentException("유저를 찾을 수 없습니다."));

        if (dto.getBoardType() == ClubBoardType.NOTICE && !clubMemberService.isUserAdminOrPresident(club, userId)) {
            throw new SecurityException("공지사항은 동아리 운영진만 작성할 수 있습니다.");
        }

        PostEntity post = PostEntity.builder()
                .club(club)
                .user(user)
                .boardType(dto.getBoardType())
                .title(dto.getTitle())
                .content(dto.getContent())
                .build();

        if (files != null && !files.isEmpty()) {
            for (MultipartFile file : files) {
                if (!file.isEmpty()) {
                    String fileName = String.format("posts/%d_%d_%s", clubId, System.currentTimeMillis(), file.getOriginalFilename());
                    String imageUrl = storageService.uploadFile(fileName, file.getBytes());

                    PostImageEntity postImage = PostImageEntity.builder()
                            .post(post)
                            .imageUrl(imageUrl)
                            .build();

                    // 🎯 중요: 부모 엔티티에 명시적으로 자식을 연결하여 Cascade 저장 쿼리가 전파되도록 수정
                    post.addPostImage(postImage);
                }
            }
        }

        return postRepository.save(post).getId();
    }

    /**
     * 🎯 게시글 리스트 페이징 조회 (Fetch Join 적용 및 게시판별 사진 차단 숏서킷 적용 완료)
     */
    public Page<PostDto.ListResponse> getPostList(Long clubId, ClubBoardType boardType, Pageable pageable) {
        // 성능 개선: N+1 방지를 위해 작성자(User) 정보까지 Fetch Join으로 묶은 새 쿼리 메서드 호출
        Page<PostEntity> posts = postRepository.findByClubIdAndBoardTypeWithUser(clubId, boardType, pageable);

        return posts.map(post -> {
            // 🎯 최적화 숏서킷: 오직 활동형 앨범(ACTIVITY) 게시판일 때만 이미지 세션에 접근하도록 차단
            // 자유/공지 게시판 조회 시에는 이미지 DB 조회 쿼리가 절대 나가지 않습니다.
            String thumbnail = (boardType == ClubBoardType.ACTIVITY && !post.getImages().isEmpty())
                    ? post.getImages().getFirst().getImageUrl()
                    : null;

            return PostDto.ListResponse.builder()
                    .id(post.getId())
                    .title(post.getTitle())
                    .writerName(post.getUser().getRealName())
                    .viewCount(post.getViewCount())
                    .upvoteCount(post.getUpvoteCount())
                    .createdAt(post.getCreatedAt())
                    .thumbnailResponse(thumbnail)
                    .build();
        });
    }

    /**
     * 🎯 게시글 상세 조회 (조회수 +1 및 단방향 복합 최적화 쿼리 반영 완료)
     */
    @Transactional
    public PostDto.InfoResponse getPostDetail(Long postId) {
        // 성능 개선: 단 건 조회 시 한 번의 쿼리로 글 + 유저 + 이미지첩을 묶어 퍼오는 고속 검색 쿼리 사용
        PostEntity post = postRepository.findDetailWithUserAndImages(postId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));
        post.increaseViewCount();

        return PostDto.InfoResponse.builder()
                .id(post.getId())
                .title(post.getTitle())
                .content(post.getContent())
                .writerId(post.getUser().getId())
                .writerName(post.getUser().getRealName())
                .viewCount(post.getViewCount())
                .upvoteCount(post.getUpvoteCount())
                .downvoteCount(post.getDownvoteCount())
                .createdAt(post.getCreatedAt())
                .imageUrls(post.getImages().stream().map(PostImageEntity::getImageUrl).collect(Collectors.toList()))
                // 댓글 컬렉션은 properties에 정의된 default_batch_fetch_size 전략에 맞춰 일괄 IN 쿼리로 최적화 처리됨
                .comments(post.getComments().stream().map(comment -> PostDto.CommentResponse.builder()
                        .id(comment.getId())
                        .writerId(comment.getUser().getId())
                        .writerName(comment.getUser().getRealName())
                        .content(comment.getContent())
                        .createdAt(comment.getCreatedAt())
                        .build()).collect(Collectors.toList()))
                .build();
    }

    /**
     * 게시글 수정 (본인 검증)
     */
    @Transactional
    public void updatePost(Long postId, Long userId, PostDto.UpdateRequest dto) {
        PostEntity post = postRepository.findById(postId).orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));
        if (!post.getUser().getId().equals(userId)) {
            throw new SecurityException("본인이 작성한 글만 수정할 수 있습니다.");
        }
        post.updatePost(dto.getTitle(), dto.getContent());
    }

    /**
     * 게시글 삭제 (본인 혹은 동아리 운영진 가능)
     */
    @Transactional
    public void deletePost(Long clubId, Long postId, Long userId) {
        PostEntity post = postRepository.findById(postId).orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));
        ClubEntity club = clubRepository.findById(clubId).orElseThrow(() -> new IllegalArgumentException("동아리를 찾을 수 없습니다."));

        boolean isWriter = post.getUser().getId().equals(userId);
        boolean isManager = clubMemberService.isUserAdminOrPresident(club, userId);

        if (!isWriter && !isManager) {
            throw new SecurityException("게시글 삭제 권한이 없습니다.");
        }
        postRepository.delete(post);
    }

    /**
     * 댓글 작성
     */
    @Transactional
    public void createComment(Long postId, Long userId, PostDto.CommentRequest dto) {
        PostEntity post = postRepository.findById(postId).orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));
        UserEntity user = userRepository.findById(userId).orElseThrow(() -> new IllegalArgumentException("유저를 찾을 수 없습니다."));

        CommentEntity comment = CommentEntity.builder()
                .post(post)
                .user(user)
                .content(dto.getContent())
                .build();
        commentRepository.save(comment);
    }

    /**
     * 댓글 삭제
     */
    @Transactional
    public void deleteComment(Long commentId, Long userId) {
        CommentEntity comment = commentRepository.findById(commentId).orElseThrow(() -> new IllegalArgumentException("댓글을 찾을 수 없습니다."));
        if (!comment.getUser().getId().equals(userId)) {
            throw new SecurityException("본인의 댓글만 삭제할 수 있습니다.");
        }
        commentRepository.delete(comment);
    }

    /**
     * 추천 / 비추천 투표 토글 연산 로직
     */
    @Transactional
    public void votePost(Long postId, Long userId, VoteType targetType) {
        PostEntity post = postRepository.findById(postId).orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));
        UserEntity user = userRepository.findById(userId).orElseThrow(() -> new IllegalArgumentException("유저를 찾을 수 없습니다."));

        Optional<PostVoteEntity> existingVote = postVoteRepository.findByPostAndUser(post, user);

        if (existingVote.isPresent()) {
            PostVoteEntity vote = existingVote.get();
            if (vote.getVoteType() == targetType) {
                if (targetType == VoteType.UPVOTE) post.decreaseUpvote();
                else post.decreaseDownvote();
                postVoteRepository.delete(vote);
            } else {
                if (targetType == VoteType.UPVOTE) {
                    post.decreaseDownvote();
                    post.increaseUpvote();
                } else {
                    post.decreaseUpvote();
                    post.increaseDownvote();
                }
                vote.changeVoteType(targetType);
            }
        } else {
            if (targetType == VoteType.UPVOTE) post.increaseUpvote();
            else post.increaseDownvote();

            postVoteRepository.save(PostVoteEntity.builder()
                    .post(post)
                    .user(user)
                    .voteType(targetType)
                    .build());
        }
    }
}