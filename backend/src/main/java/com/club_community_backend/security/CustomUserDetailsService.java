package com.club_community_backend.security;

import com.club_community_backend.entity.UserEntity;
import com.club_community_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NonNull;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    // 시큐리티가 내부적으로 로그인을 처리할 때 유저 아이디를 이 메서드로 던집니다.
    @Override
    @NonNull
    public UserDetails loadUserByUsername(@NonNull String username) throws UsernameNotFoundException {

        // 1. DB에서 userId로 유저 조회
        UserEntity user = userRepository.findByUserId(username)
                .orElseThrow(() -> new UsernameNotFoundException("존재하지 않는 사용자 아이디입니다: " + username));

        // 2. 찾아온 유저 엔티티를 시큐리티 상자(CustomUserDetails)에 담아서 반환
        return new CustomUserDetails(user);
    }
}