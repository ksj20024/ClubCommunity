package com.club_community_backend.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity // 스프링 시큐리티 필터 체인을 활성화합니다.
@RequiredArgsConstructor
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                // 1. CORS 설정 연결
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

                // 2. CSRF 비활성화 (REST API 환경이므로 잠시 꺼둡니다)
                .csrf(AbstractHttpConfigurer::disable)

                // 3. API 접근 권한 제어 (정적 리소스 프리패스 추가)
                .authorizeHttpRequests(auth -> auth
                        // ⭕ [순서 1 - 최우선 허용 경로] 회원가입, 로그인, 이메일 인증 발송
                        .requestMatchers("/api/users/join", "/api/users/login", "/api/users/email-verification/send").permitAll()

                        // 🎯 [추가] 업로드된 이미지 조회 경로는 세션 인증 없이 누구나 접근할 수 있도록 허용 (401 에러 해결)
                        .requestMatchers("/api/storage/**", "/storage/**").permitAll()

                        // ⭕ [순서 2 - 에이전트 허용 경로] 파이썬 에이전트 내부 경로는 인증(세션) 없이 통과 (컨트롤러 헤더에서 2차 검증)
                        .requestMatchers("/api/internal/agent/**").permitAll()

                        // ⭕ [순서 3 - 조건부 인증 경로] 동아리 관련 모든 API는 로그인한 유저만 허용
                        .requestMatchers("/api/clubs/**").authenticated()

                        // ⭕ [순서 4 - 최종 관문] 그 외 나머지 모든 API 요청은 무조건 인증(로그인) 필요! (맨 마지막에 딱 한번만 배치)
                        .anyRequest().authenticated()
                )

                // 4. 예외 처리: 인증되지 않은 유저가 접근 시 폼 로그인창으로 리다이렉트하지 않고, 401 에러와 깔끔한 JSON 응답 반환
                .exceptionHandling(exception -> exception
                        .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED))
                )

                // 5. 로그아웃 설정
                .logout(logout -> logout
                        .logoutUrl("/api/users/logout")
                        .logoutSuccessHandler((request, response, authentication) -> response.setStatus(HttpStatus.OK.value()))
                        .deleteCookies("JSESSIONID") // 로그아웃 시 쿠키 삭제
                        .invalidateHttpSession(true) // 세션 무효화
                );

        return http.build();
    }

    // 비밀번호 암호화를 위한 Bean 등록
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // 시큐리티 전용 CORS 설정
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of("http://localhost:55555"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true); // 쿠키/세션 연동을 위해 필수
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authenticationConfiguration) throws Exception {
        return authenticationConfiguration.getAuthenticationManager();
    }
}