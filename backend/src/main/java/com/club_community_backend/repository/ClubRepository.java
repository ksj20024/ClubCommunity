package com.club_community_backend.repository;

import com.club_community_backend.entity.ClubEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ClubRepository extends JpaRepository<ClubEntity, Long> {
    // 특정 학교에 속한 동아리 찾기
    List<ClubEntity> findBySchoolName(String schoolName);
    // 클럽 이름으로 동아리 찾기
    Optional<ClubEntity> findByClubName(String clubName);
    // 동아리 이름 중복 확인
    boolean existsByClubName(String clubName);
    List<ClubEntity> findByIsDeleteFalseOrderByIdDesc();
}
