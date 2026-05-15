package com.club_community_backend.repository;

import com.club_community_backend.entity.ApplicationFormEntity;
import com.club_community_backend.entity.ClubEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;


public interface ApplicationFormRepository extends JpaRepository<ApplicationFormEntity, Long> {
    Optional<ApplicationFormEntity> findByClub(ClubEntity club);
}
