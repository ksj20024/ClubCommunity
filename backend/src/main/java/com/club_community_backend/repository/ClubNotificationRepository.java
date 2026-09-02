package com.club_community_backend.repository;

import com.club_community_backend.entity.ClubNotificationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface ClubNotificationRepository extends JpaRepository<ClubNotificationEntity, Long> {

    /**
     * 여러 동아리 ID 목록을 기반으로 알림이 켜진 임원들의 엔티티를 한 번에 조회 (Fetch Join)
     * 실제 Enum 상수 사양(CLUBADMIN, CLUBPRESIDENT) 전면 동기화 완료
     */
    @Query("""
        SELECT cn
        FROM ClubNotificationEntity cn
        JOIN FETCH cn.clubMember cm
        JOIN FETCH cm.club c
        WHERE c.id IN (:clubIds)
          AND cn.isAlertEnabled = true
          AND cm.clubRole IN (com.club_community_backend.constant.ClubRole.CLUBADMIN, com.club_community_backend.constant.ClubRole.CLUBPRESIDENT)
    """)
    List<ClubNotificationEntity> findActiveChatIdsByClubIds(@Param("clubIds") List<Long> clubIds);
}