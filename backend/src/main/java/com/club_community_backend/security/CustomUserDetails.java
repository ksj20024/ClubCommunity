package com.club_community_backend.security;

import com.club_community_backend.entity.UserEntity;
import org.jspecify.annotations.NonNull;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;

public record CustomUserDetails(UserEntity user) implements UserDetails {

    // 1. 권한 반환 메서드에 @NonNull 추가
    @Override
    @NonNull
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Collections.singletonList(
                new SimpleGrantedAuthority("ROLE_" + user.getGlobalRole().name())
        );
    }

    // 2. 비밀번호 반환 메서드에 @NonNull 추가
    @Override
    public String getPassword() {
        return user.getPassword();
    }

    // 3. 아이디 반환 메서드에 @NonNull 추가
    @Override
    @NonNull
    public String getUsername() {
        return user.getUserId();
    }
}