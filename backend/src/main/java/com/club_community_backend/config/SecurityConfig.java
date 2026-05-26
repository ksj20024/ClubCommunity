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

                // 3. API 접근 권한 제어
                .authorizeHttpRequests(auth -> auth
                        // 회원가입, 로그인, 이메일 인증 발송은 로그인 없이 접근 허용
                        .requestMatchers("/api/users/join", "/api/users/login", "/api/users/email-verification/send").permitAll()
                        // 그 외 모든 API 요청은 인증(로그인) 필요
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

    // 비밀번호 암호화를 위한 Bean 등록 (추후 로그인/회원가입 시 유저 비밀번호를 가공할 때 사용)
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // 시큐리티 전용 CORS 설정 (기존 WebConfig 설정을 대체함)
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of("http://localhost:55555"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true); // 👈 쿠키/세션 연동을 위해 필수
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    // SecurityConfig.java 내부에 추가

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authenticationConfiguration) throws Exception {
        return authenticationConfiguration.getAuthenticationManager();
    }
}