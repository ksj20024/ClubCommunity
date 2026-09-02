package com.club_community_backend.repository;

import com.club_community_backend.constant.ClubBoardType;
import com.club_community_backend.entity.PostEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface PostRepository extends JpaRepository<PostEntity, Long> {

    /**
     * 🤖 [기존 유지] AI 에이전트(Hermes) 자율 탐지용
     * 특정 ID 이후의 게시글들을 동아리 정보와 함께 최신순(ID 오름차순)으로 조회
     */
    @Query("""
        SELECT p
        FROM PostEntity p
        JOIN FETCH p.club
        WHERE p.id > :lastPostId
        ORDER BY p.id ASC
    """)
    List<PostEntity> findPostsForModeration(@Param("lastPostId") Long lastPostId, Pageable pageable);

    /**
     * 📊 [기존 유지] 오늘 특정 동아리에 작성된 글 총합 카운트 (대시보드용)
     */
    long countByClubIdAndCreatedAtAfter(Long clubId, LocalDateTime dateTime);

    /**
     * 📌 [기존 유지] 대시보드 전용 상위 3개 최신글 슬라이싱 조회 (N+1 최적화 적용)
     */
    @Query("""
        SELECT p
        FROM PostEntity p
        JOIN FETCH p.user
        WHERE p.club.id = :clubId AND p.boardType = :boardType
        ORDER BY p.createdAt DESC
    """)
    List<PostEntity> findTopPostsByBoardType(
            @Param("clubId") Long clubId,
            @Param("boardType") ClubBoardType boardType,
            Pageable pageable
    );

    /**
     * 🎯 [신설 최적화] 범용 게시판 페이징 목록 조회 (일반/공지/활동 통합)
     * 작성자(User)를 Fetch Join으로 묶어 목록을 뿌릴 때 발생하는 N+1 문제를 원천 차단합니다.
     */
    @Query(value = "SELECT p FROM PostEntity p JOIN FETCH p.user WHERE p.club.id = :clubId AND p.boardType = :boardType ORDER BY p.createdAt DESC",
            countQuery = "SELECT count(p) FROM PostEntity p WHERE p.club.id = :clubId AND p.boardType = :boardType")
    Page<PostEntity> findByClubIdAndBoardTypeWithUser(
            @Param("clubId") Long clubId,
            @Param("boardType") ClubBoardType boardType,
            Pageable pageable
    );

    /**
     * 🎯 [신설 최적화] 게시글 단건 상세 조회
     * 단 한 번의 쿼리로 게시글 본문 + 작성자 정보 + 다중 이미지첩(LEFT JOIN FETCH)을 동시 수급합니다.
     */
    @Query("SELECT p FROM PostEntity p JOIN FETCH p.user LEFT JOIN FETCH p.images WHERE p.id = :postId")
    Optional<PostEntity> findDetailWithUserAndImages(@Param("postId") Long postId);
}