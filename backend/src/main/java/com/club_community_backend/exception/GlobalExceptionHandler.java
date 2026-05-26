package com.club_community_backend.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // 1. 잘못된 요청 및 상태 오류 (400 Bad Request)
    @ExceptionHandler({IllegalArgumentException.class, IllegalStateException.class})
    public ResponseEntity<ErrorResponse> handleBadRequest(RuntimeException e) {
        HttpStatus status = HttpStatus.BAD_REQUEST; // 400

        ErrorResponse response = new ErrorResponse(
                status.value(),             // 400
                status.getReasonPhrase(),   // "Bad Request"
                e.getMessage()              // 예외에 던진 실제 메시지
        );

        return ResponseEntity.status(status).body(response);
    }

    // 2. 권한 및 보안 오류 (403 Forbidden)
    @ExceptionHandler(SecurityException.class)
    public ResponseEntity<ErrorResponse> handleForbidden(SecurityException e) {
        HttpStatus status = HttpStatus.FORBIDDEN; // 403

        ErrorResponse response = new ErrorResponse(
                status.value(),             // 403
                status.getReasonPhrase(),   // "Forbidden"
                e.getMessage()
        );

        return ResponseEntity.status(status).body(response);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationException(MethodArgumentNotValidException e) {
        HttpStatus status = HttpStatus.BAD_REQUEST; // 400

        // 발생한 에러들 중 첫 번째 에러의 메시지를 가져옵니다.
        // 없을 경우 기본 에러 메시지를 세팅합니다.
        String errorMessage = e.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .findFirst()
                .orElse("올바르지 않은 입력값입니다.");

        ErrorResponse response = new ErrorResponse(
                status.value(),
                status.getReasonPhrase(),
                errorMessage // DTO에 적어둔 message가 여기에 쏙 들어갑니다.
        );

        return ResponseEntity.status(status).body(response);
    }

    // 3. 최후의 보루: 서버 내부에서 예상치 못한 에러가 터졌을 때 (500 Internal Server Error)
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleAllException(Exception e) {
        HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR; // 500

        ErrorResponse response = new ErrorResponse(
                status.value(),
                status.getReasonPhrase(),
                "서버 내부 오류가 발생했습니다. 관리자에게 문의하세요." // 보안을 위해 상세 에러 감춤
        );

        return ResponseEntity.status(status).body(response);
    }
}