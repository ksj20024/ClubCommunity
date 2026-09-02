package com.club_community_backend.dto;

import java.util.List;

public record PostAdminResponse(
        Long postId,
        Long clubId,
        String clubName,
        String title,
        String content,
        List<String> managerTelegramChatIds
) {}