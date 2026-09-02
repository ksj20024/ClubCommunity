package com.club_community_backend.dto;

import lombok.Builder;
import lombok.Getter;

public class ApplicationFormDto {

    @Getter @Builder
    public static class FormTemplateResponse {
        private Long clubId;
        private String formSettings; // 📝 회장이 설정한 JSON 질문 폼 데이터
    }
}
