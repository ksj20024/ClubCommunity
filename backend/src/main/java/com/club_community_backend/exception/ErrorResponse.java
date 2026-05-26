package com.club_community_backend.exception;

// 프론트엔드와 통신할 간단한 에러 DTO (Record 사용)
    public record ErrorResponse(int status, String error, String message) {}
