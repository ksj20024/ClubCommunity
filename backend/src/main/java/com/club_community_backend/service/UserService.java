package com.club_community_backend.service;

import com.club_community_backend.constant.UserRole;
import com.club_community_backend.dto.UserDto;
import com.club_community_backend.entity.UserEntity;
import com.club_community_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {
    private final UserRepository userRepository;

    // 회원가입 로직
    @Transactional
    public void join(UserDto.JoinRequest dto) {
        if (userRepository.existsByUserId(dto.getUserId())) {
            throw new IllegalStateException("이미 존재하는 아이디입니다.");
        }
        if (userRepository.existsByEmail(dto.getEmail())) {
            throw new IllegalStateException("이미 존재하는 이메일입니다.");
        }

        UserEntity user = UserEntity.builder()
                .userId(dto.getUserId())
                .email(dto.getEmail())
                .password(dto.getPassword())
                .realName(dto.getRealName())
                .phoneNumber(dto.getPhoneNumber())
                .globalRole(UserRole.USER)
                .build();
        userRepository.save(user);
    }

    // 로그인 로직
    public UserDto.InfoResponse login(UserDto.LoginRequest dto) {
        UserEntity user = userRepository.findByUserId(dto.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 아이디입니다."));

        if(!user.getPassword().equals(dto.getPassword())){
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

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
    public void updateUser(Long id, UserDto.UpdateRequest dto) {
        // 1. 기존 유저 조회
        UserEntity user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 2. 이메일 중복 체크 (이메일을 변경하려는 경우에만)
        if (!user.getEmail().equals(dto.getEmail()) && userRepository.existsByEmail(dto.getEmail())) {
            throw new IllegalStateException("이미 사용 중인 이메일입니다.");
        }

        // 3. 데이터 업데이트 (변경 감지 활용)
        user.updateUser(dto);

        // 트랜잭션 종료 시 자동으로 DB에 반영됨
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
}
