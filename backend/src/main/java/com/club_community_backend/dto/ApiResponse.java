package com.club_community_backend.dto;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public class ApiResponse<T> {

    private final int status;       // HTTP 상태 코드 (200, 201 등)
    private final String message;   // 프론트엔드에 띄워줄 안내 메시지
    private final T data;           // 실제 전달할 핵심 데이터 (없으면 null)

    // 내부적으로만 사용하는 생성자 (아래의 정적 팩토리 메서드를 통해 생성 유도)
    private ApiResponse(int status, String message, T data) {
        this.status = status;
        this.message = message;
        this.data = data;
    }

    // 1. 데이터 없이 성공 메시지만 보낼 때 (예: 가입 신청 완료, 삭제 완료)
    public static <T> ApiResponse<T> success(String message) {
        return new ApiResponse<>(HttpStatus.OK.value(), message, null);
    }

    // 2. 데이터와 함께 성공 메시지를 보낼 때 (예: 명단 조회, 상세 조회)
    public static <T> ApiResponse<T> success(String message, T data) {
        return new ApiResponse<>(HttpStatus.OK.value(), message, data);
    }

    // 3. 201 Created (생성 완료) 같은 특정 상태 코드를 명시하고 싶을 때
    public static <T> ApiResponse<T> success(HttpStatus status, String message, T data) {
        return new ApiResponse<>(status.value(), message, data);
    }
}