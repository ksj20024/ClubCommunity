package com.club_community_backend.repository;

import com.club_community_backend.constant.ClubJoinStatusRole;
import com.club_community_backend.entity.ApplicationDocEntity;
import com.club_community_backend.entity.ClubMemberEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ApplicationDocRepository extends JpaRepository<ApplicationDocEntity, Long> {
    // 특정 동아리 신청서 중 대기중만 찾기

}
