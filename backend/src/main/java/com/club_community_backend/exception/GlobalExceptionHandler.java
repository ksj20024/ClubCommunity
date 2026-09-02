package com.club_community_backend.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.util.StringUtils;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;


@RestControllerAdvice
public class GlobalExceptionHandler {

    // 1. 잘못된 요청 및 상태 오류 (400 Bad Request)
    @ExceptionHandler({IllegalArgumentException.class, IllegalStateException.class})
    public ResponseEntity<ErrorResponse> handleBadRequest(RuntimeException e) {
        HttpStatus status = HttpStatus.BAD_REQUEST;
        ErrorResponse response = new ErrorResponse(status.value(), status.getReasonPhrase(), e.getMessage());
        return ResponseEntity.status(status).body(response);
    }

    // 🎯 [신설] 2. 인증 및 자격 증명 오류 (401 Unauthorized)
    // 비밀번호가 틀리거나 아이디가 없을 때 발생하는 시큐리티 에러를 여기서 가로챕니다.
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ErrorResponse> handleUnauthorized(BadCredentialsException e) {
        HttpStatus status = HttpStatus.UNAUTHORIZED; // 401 Unauthorized

        ErrorResponse response = new ErrorResponse(
                status.value(),
                status.getReasonPhrase(),
                "아이디 또는 비밀번호가 올바르지 않습니다." // 보안상 통합 메시지 노출
        );

        return ResponseEntity.status(status).body(response);
    }

    // 3. 권한 및 보안 오류 (403 Forbidden)
    @ExceptionHandler(SecurityException.class)
    public ResponseEntity<ErrorResponse> handleForbidden(SecurityException e) {
        HttpStatus status = HttpStatus.FORBIDDEN;
        ErrorResponse response = new ErrorResponse(status.value(), status.getReasonPhrase(), e.getMessage());
        return ResponseEntity.status(status).body(response);
    }

    // DTO Validation 예외 처리 (400)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationException(MethodArgumentNotValidException e) {
        HttpStatus status = HttpStatus.BAD_REQUEST;

        String errorMessage = e.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .filter(StringUtils::hasText) // 🎯 [추천] null, 빈 문자열, 공백 문자열을 전부 싹 다 걸러냅니다.
                .findFirst()
                .orElse("올바르지 않은 입력값입니다.");

        ErrorResponse response = new ErrorResponse(status.value(), status.getReasonPhrase(), errorMessage);
        return ResponseEntity.status(status).body(response);
    }

    // 4. 최후의 보루: 서버 내부에서 예상치 못한 에러가 터졌을 때 (500 Internal Server Error)
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleAllException(Exception e) {
        HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR;
        ErrorResponse response = new ErrorResponse(status.value(), status.getReasonPhrase(), "서버 내부 오류가 발생했습니다. 관리자에게 문의하세요.");
        return ResponseEntity.status(status).body(response);
    }
}