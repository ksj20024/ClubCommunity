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

    boolean existsByClubAndUser_IdAndClubRoleAndJoinStatus(
            ClubEntity club,
            Long userId,
            ClubRole role,
            ClubJoinStatusRole joinStatus
    );

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
}
