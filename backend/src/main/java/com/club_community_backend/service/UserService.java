package com.club_community_backend.service;

import com.club_community_backend.constant.UserRole;
import com.club_community_backend.dto.UserDto;
import com.club_community_backend.entity.UserEntity;
import com.club_community_backend.repository.UserRepository;
import com.club_community_backend.security.CustomUserDetails;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Objects;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder; // 👈 비밀번호 암호화 부품 주입
    private final AuthenticationManager authenticationManager; // 👈 시큐리티 인증 매니저 주입
    private final EmailVerificationService emailVerificationService;
    // 스프링 시큐리티 6에서 세션을 안전하게 저장하기 위한 리포지토리
    private final SecurityContextRepository securityContextRepository = new HttpSessionSecurityContextRepository();

    /**
     * 회원가입 (비밀번호 암호화 적용)
     */
    @Transactional
    public void join(UserDto.JoinRequest dto) {
        if (userRepository.existsByUserId(dto.getUserId())) {
            throw new IllegalArgumentException("이미 존재하는 아이디입니다.");
        }
        if (userRepository.existsByEmail(dto.getEmail())) {
            throw new IllegalArgumentException("이미 존재하는 이메일입니다.");
        }

        // 🛠️ 오류 1 해결: 비밀번호 변수를 분리하고 확실하게 Null 체크를 하여 IDE 경고 방어
        String rawPassword = dto.getPassword();
        if (rawPassword == null) {
            throw new IllegalArgumentException("비밀번호는 필수 입력 항목입니다.");
        }

        UserEntity user = UserEntity.builder()
                .userId(dto.getUserId())
                .password(Objects.requireNonNull(passwordEncoder.encode(rawPassword)))
                .email(dto.getEmail())
                .realName(dto.getRealName())
                .phoneNumber(dto.getPhoneNumber())
                // 🛠️ 오류 3 해결: 외부 가입 요청에 의존하지 않고, 보안상 정해진 기본 회원 권한(USER)을 주입
                .globalRole(UserRole.USER)
                .build();

        userRepository.save(user);
    }

    /**
     * 로그인 (세션 쿠키 발급)
     */
    public UserDto.InfoResponse login(UserDto.LoginRequest dto, HttpServletRequest request, HttpServletResponse response) {

        UsernamePasswordAuthenticationToken authenticationToken =
                new UsernamePasswordAuthenticationToken(dto.getUserId(), dto.getPassword());

        Authentication authentication = authenticationManager.authenticate(authenticationToken);

        SecurityContext context = SecurityContextHolder.createEmptyContext();
        context.setAuthentication(authentication);
        SecurityContextHolder.setContext(context);

        securityContextRepository.saveContext(context, request, response);

        // 🛠️ 오류 2 해결: 객체 검증을 거쳐 내부 엔티티가 확실히 존재함을 보장 (NPE 경고 완벽 방어)
        CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
        if (userDetails == null || userDetails.user() == null) {
            throw new IllegalStateException("인증된 사용자 정보를 불러올 수 없습니다.");
        }

        UserEntity user = userDetails.user();

        return UserDto.InfoResponse.builder()
                .id(user.getId())
                .userId(user.getUserId())
                .email(user.getEmail())
                .realName(user.getRealName())
                .phoneNumber(user.getPhoneNumber())
                // 🛠️ 오류 4 해결: .name()을 제거하고 DTO 요구 규격에 맞춰 Enum 타입(UserRole) 자체를 전달
                .role(user.getGlobalRole())
                .build();
    }

    public UserDto.InfoResponse getCurrentUserInfo(Long id) {
        // DB에서 가장 최근에 업데이트된 실시간 데이터를 조회합니다.
        UserEntity user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        return UserDto.InfoResponse.builder()
                .id(user.getId())
                .userId(user.getUserId())
                .email(user.getEmail())
                .realName(user.getRealName())
                .phoneNumber(user.getPhoneNumber())
                .role(user.getGlobalRole())
                .build();
    }

    // 1. 일반 정보 업데이트
    @Transactional
    public UserDto.InfoResponse updateGeneralInfo(Long id, UserDto.GeneralUpdateRequest dto) {
        UserEntity user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // Entity 내부의 갱신 메서드 호출 (예: user.updateGeneral(dto.getRealName(), dto.getPhoneNumber()))
        user.updateGeneral(dto.getRealName(), dto.getPhoneNumber());

        return convertToInfoResponse(user);
    }

    // 2. 비밀번호 변경
    @Transactional
    public void changePassword(Long id, UserDto.PasswordChangeRequest dto) {
        UserEntity user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 현재 비밀번호 일치 여부 검증 (추후 암호화 적용 시 encoder.matches()로 변경 필요)
        if (!user.getPassword().equals(dto.getCurrentPassword())) {
            throw new IllegalArgumentException("현재 비밀번호가 일치하지 않습니다.");
        }

        // 새 비밀번호 반영
        user.updatePassword(dto.getNewPassword());
    }

    // 3. 이메일 인증 메일 발송 전 단계 (검증 전용)
    @Transactional
    public void sendVerificationEmail(UserDto.EmailVerifyRequest dto) {
        // 중복 이메일 철저히 검증
        if (userRepository.existsByEmail(dto.getEmail())) {
            throw new IllegalStateException("이미 가입된 이메일 주소입니다.");
        }

        // 이메일 발송 및 인증 번호 임시 저장 로직 실행 생성
        emailVerificationService.createAndSendCode(dto.getEmail());
    }

    // 4. 이메일 최종 업데이트 (★ 단일 트랜잭션 보장)
    @Transactional
    public UserDto.InfoResponse updateEmail(Long id, UserDto.EmailUpdateRequest dto) {
        // 4-1. 유저 존재 검증
        UserEntity user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 4-2. 이메일 중복 재차 검증 (인증 메일 발송 사이에 다른 유저가 선점했을 수도 있으므로 필수)
        if (!user.getEmail().equals(dto.getEmail()) && userRepository.existsByEmail(dto.getEmail())) {
            throw new IllegalStateException("이미 사용 중인 이메일입니다.");
        }

        // 4-3. 한 트랜잭션 내에서 인증코드 매칭 검증 수행
        boolean isValid = emailVerificationService.verifyCode(dto.getEmail(), dto.getVerificationCode());
        if (!isValid) {
            throw new IllegalArgumentException("인증번호가 일치하지 않거나 만료되었습니다.");
        }

        // 4-4. 완벽히 통과 시 이메일 데이터 최종 변경 (변경 감지)
        user.updateEmail(dto.getEmail());

        // 4-5. 사용 완료된 인증 정보 파기
        emailVerificationService.deleteCode(dto.getEmail());

        return convertToInfoResponse(user);
    }

    // 내부 공통 변환 메서드
    private UserDto.InfoResponse convertToInfoResponse(UserEntity user) {
        return UserDto.InfoResponse.builder()
                .id(user.getId())
                .userId(user.getUserId())
                .email(user.getEmail())
                .realName(user.getRealName())
                .phoneNumber(user.getPhoneNumber())
                .role(user.getGlobalRole())
                .build();
    }

    @Transactional
    public void withdraw(Long id, UserDto.WithdrawalRequest dto) {
        UserEntity user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않거나 이미 탈퇴한 회원입니다."));

        // 비밀번호 확인
        if (!user.getPassword().equals(dto.getPassword())) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        // 삭제 호출 (엔티티에 @SoftDelete가 붙어있으므로 내부적으로는 update가 실행됨)
        userRepository.delete(user);
    }

    public void refreshSessionAuthentication(Long userId, HttpServletRequest request, HttpServletResponse response) {
        // 1. DB에서 가장 최근에 업데이트된 유저 엔티티를 새로 읽어옵니다.
        UserEntity updatedUser = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        // 2. 최신 엔티티로 새로운 시큐리티 포장 상자(CustomUserDetails)를 만듭니다.
        CustomUserDetails newDetails = new CustomUserDetails(updatedUser);

        // 3. 새로운 인증 토큰을 생성합니다. (이미 인증된 유저이므로 비밀번호 credentials 자리는 null 처리해도 무방합니다)
        Authentication newAuth = new UsernamePasswordAuthenticationToken(
                newDetails,
                null,
                newDetails.getAuthorities()
        );

        // 4. 현재 스레드의 시큐리티 컨텍스트에 새 토큰을 꽂아줍니다.
        SecurityContext context = SecurityContextHolder.getContext();
        context.setAuthentication(newAuth);

        // 5. ★ 핵심: 스프링 시큐리티 6 규격에 맞춰 HttpSession 저장소에 변경된 컨텍스트를 확실하게 저장합니다.
        securityContextRepository.saveContext(context, request, response);
    }
}
