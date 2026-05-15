package com.club_community_backend.repository;

import com.club_community_backend.entity.*;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ApplicationDocRepository extends JpaRepository<ApplicationDocEntity, Long> {
    Optional<ApplicationDocEntity> findByClubAndUser(ClubEntity club, UserEntity user);
    // 특정 동아리 신청서 중 대기중만 찾기
    

}
