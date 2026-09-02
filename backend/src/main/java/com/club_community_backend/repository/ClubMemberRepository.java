package com.club_community_backend.repository;

import com.club_community_backend.constant.ClubJoinStatusRole;
import com.club_community_backend.constant.ClubRole;
import com.club_community_backend.entity.ClubEntity;
import com.club_community_backend.entity.ClubMemberEntity;
import com.club_community_backend.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ClubMemberRepository extends JpaRepository<ClubMemberEntity, Long> {
    // 특정 동아리의 모든 멤버 찾기
    List<ClubMemberEntity> findByClub(ClubEntity club);
    // 특정 멤버가 가입한 모든 동아리 찾기
    List<ClubMemberEntity> findByUser(UserEntity user);

    Optional<ClubMemberEntity> findByClubIdAndUserId(Long clubId, Long userId);

    boolean existsByClubAndUser_IdAndClubRoleAndJoinStatus(
            ClubEntity club,
            Long userId,
            ClubRole role,
            ClubJoinStatusRole joinStatus
    );

    // 🌟 [성능 최적화] FETCH JOIN을 통해 UserEntity를 한 번에 묶어서 긁어옵니다.
    @Query("SELECT cm FROM ClubMemberEntity cm " +
            "JOIN FETCH cm.user " +
            "WHERE cm.club.id = :clubId AND cm.joinStatus = :joinStatus " +
            "ORDER BY cm.clubRole DESC, cm.user.realName ASC") // 회장/운영진 우선 정렬 후 이름순 정렬
    List<ClubMemberEntity> findApprovedMembersWithUser(
            @Param("clubId") Long clubId,
            @Param("joinStatus") ClubJoinStatusRole joinStatus
    );

    // 유저가 해당 동아리의 정식 멤버인지 확인하는 방어 로직용
    boolean existsByClubIdAndUserIdAndJoinStatus(Long clubId, Long userId, ClubJoinStatusRole joinStatus);

    // 역할에 상관없이 특정 동아리의 멤버인지(승인된 상태인지) 체크할 때
    boolean existsByClubAndUser_IdAndJoinStatus(
            ClubEntity club,
            Long userId,
            ClubJoinStatusRole joinStatus
    );
    boolean existsByClubAndUser(ClubEntity club, UserEntity user);

    @Query("SELECT cm FROM ClubMemberEntity cm " +
            "JOIN FETCH cm.user " +
            "LEFT JOIN ApplicationDocEntity ad ON ad.user = cm.user AND ad.club = cm.club " +
            "WHERE cm.club.id = :clubId AND cm.joinStatus = 'PENDING'")
    List<ClubMemberEntity> findPendingMembersWithDoc(@Param("clubId") Long clubId);

    Optional<ClubMemberEntity> findByClubAndUser_Id(ClubEntity club, Long applicantId);

    long countByClubIdAndJoinStatus(Long clubId, com.club_community_backend.constant.ClubJoinStatusRole joinStatus);

    List<ClubMemberEntity> findByUserAndJoinStatus(UserEntity user, ClubJoinStatusRole clubJoinStatusRole);
}
