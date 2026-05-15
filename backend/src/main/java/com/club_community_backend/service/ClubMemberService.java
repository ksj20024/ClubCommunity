package com.club_community_backend.service;

import com.club_community_backend.constant.ClubJoinStatusRole;
import com.club_community_backend.constant.ClubRole;
import com.club_community_backend.entity.ClubEntity;
import com.club_community_backend.entity.ClubMemberEntity;
import com.club_community_backend.entity.UserEntity;
import com.club_community_backend.repository.ClubMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ClubMemberService {
    private final ClubMemberRepository clubMemberRepository;

    // 중복 가입 체크는 여기서 제공 (공통 기능)
    public boolean isAlreadyMember(ClubEntity club, UserEntity user) {
        return clubMemberRepository.existsByClubAndUser(club, user);
    }

    @Transactional
    public void joinClub(ClubEntity club, UserEntity user, ClubRole role, ClubJoinStatusRole status, String studentNo) {
        ClubMemberEntity member = ClubMemberEntity.builder()
                .club(club)
                .user(user)
                .clubRole(role)
                .joinStatus(status)
                .studentNo(studentNo)
                .build();

        clubMemberRepository.save(member);
    }

    //특정 유저가 동아리 내에서 특정 역할을 가지고 있는지 확인 (승인된 멤버 기준)
    @Transactional(readOnly = true)
    public boolean isUserHasRole(ClubEntity club, Long userId, ClubRole role) {
        return clubMemberRepository.existsByClubAndUser_IdAndClubRoleAndJoinStatus(
                club,
                userId,
                role,
                ClubJoinStatusRole.APPROVED
        );
    }

    // 특정 유저가 해당 동아리의 운영진(회장 혹은 관리자)인지 확인
    @Transactional(readOnly = true)
    public boolean isUserAdminOrPresident(ClubEntity club, Long userId) {
        // 회장이거나 관리자 중 하나라도 해당하면 true
        return clubMemberRepository.existsByClubAndUser_IdAndClubRoleAndJoinStatus(club, userId, ClubRole.CLUBPRESIDENT, ClubJoinStatusRole.APPROVED) ||
                clubMemberRepository.existsByClubAndUser_IdAndClubRoleAndJoinStatus(club, userId, ClubRole.CLUBADMIN, ClubJoinStatusRole.APPROVED);
    }
}
