package com.club_community_backend.dto;

import java.util.List;

public record PostAdminTargetDto(
        Long postId,
        Long clubId,
        String clubName,
        String title,
        String content,
        List<String> managerTelegramChatIds // 알림을 수신할 이 동아리의 임원 chat_id 목록
) {}
