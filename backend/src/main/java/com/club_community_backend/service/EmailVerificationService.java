package com.club_community_backend.service;

import com.club_community_backend.entity.EmailVerificationEntity;
import com.club_community_backend.repository.EmailVerificationRepository;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Random;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailVerificationService {

    private final JavaMailSender mailSender;
    private final EmailVerificationRepository verificationRepository; // 👈 DB 레포지토리 주입

    @Value("${spring.mail.username}")
    private String fromEmail;
    private static final long EXPIRATION_MINUTES = 5;

    /**
     * 1. 인증 코드 생성, DB 저장 및 이메일 발송
     */
    @Transactional
    public void createAndSendCode(String email) {
        String verificationCode = String.format("%06d", new Random().nextInt(900000) + 100000);

        // 이메일 발송
        sendEmail(email, verificationCode);

        // ⭐ [구조 변경] DB에 기존 인증 정보가 있으면 '수정', 없으면 '신규 삽입'
        EmailVerificationEntity verification = verificationRepository.findByEmail(email)
                .map(existing -> {
                    // 기존 데이터가 존재하면 값만 업데이트 (변경 감지 활용)
                    existing.updateVerification(verificationCode, LocalDateTime.now().plusMinutes(EXPIRATION_MINUTES));
                    return existing;
                })
                .orElseGet(() -> EmailVerificationEntity.builder()
                        .email(email)
                        .code(verificationCode)
                        .expiryDate(LocalDateTime.now().plusMinutes(EXPIRATION_MINUTES))
                        .build());

        // save()는 새로운 엔티티일 때는 INSERT를, 기존 엔티티일 때는 수정을 보장합니다.
        verificationRepository.save(verification);

        log.info("인증 코드 처리 완료 (Upsert) - Email: {}, Code: {}", email, verificationCode);
    }

    /**
     * 2. 인증 코드 검증 (UserService에서 호출됨)
     */
    @Transactional(readOnly = true)
    public boolean verifyCode(String email, String code) {
        return verificationRepository.findByEmail(email)
                .map(verification -> {
                    if (verification.isExpired()) {
                        log.warn("인증 실패 - 만료된 코드: {}", email);
                        return false;
                    }
                    return verification.getCode().equals(code);
                })
                .orElse(false);
    }

    /**
     * 3. 사용 완료된 인증 정보 삭제 (UserService에서 호출됨)
     */
    @Transactional
    public void deleteCode(String email) {
        verificationRepository.deleteByEmail(email);
        log.info("인증 코드 사용 완료로 인한 DB 데이터 삭제 - Email: {}", email);
    }

    /**
     * 내부 메서드: 실제 MimeMessage를 이용한 HTML 메일 발송
     */
    private void sendEmail(String toEmail, String code) {
        MimeMessage message = mailSender.createMimeMessage();

        try {
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            // ⭐ [필수 수정] 보내는 사람(From)을 명시해 줍니다!
            helper.setFrom(fromEmail);

            helper.setTo(toEmail);
            helper.setSubject("[동아리 커뮤니티] 이메일 인증 번호 안내");

            String htmlContent = String.format(
                    "<div style='margin:20px; padding:20px; border:1px solid #e2e8f0; border-radius:8px; font-family:Arial,sans-serif;'>" +
                            "   <h2 style='color:#4f46e5;'>이메일 주소 변경 인증 번호</h2>" +
                            "   <p>안녕하세요! 동아리 커뮤니티 플랫폼입니다.</p>" +
                            "   <p>회원님의 이메일 주소를 변경하기 위한 인증 번호입니다. 아래의 코드를 인증 창에 입력해 주세요.</p>" +
                            "   <div style='margin:20px 0; padding:15px; background-color:#f8fafc; border-radius:4px; text-align:center; font-size:24px; font-weight:bold; color:#1e293b; letter-spacing:5px;'>" +
                            "       %s" +
                            "   </div>" +
                            "   <p style='font-size:12px; color:#64748b;'>* 본 인증 번호는 <b>%d분</b>간 유효합니다.</p>" +
                            "</div>",
                    code, EXPIRATION_MINUTES
            );

            helper.setText(htmlContent, true);
            mailSender.send(message);

        } catch (MessagingException e) {
            log.error("이메일 발송 중 기술적 예외 발생: {}", e.getMessage());
            throw new RuntimeException("이메일 발송에 실패했습니다. 관리자에게 문의하세요.", e);
        }
    }
}