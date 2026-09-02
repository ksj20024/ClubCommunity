package com.club_community_backend.service;

import com.club_community_backend.constant.ClubJoinStatusRole;
import com.club_community_backend.constant.ClubRole;
import com.club_community_backend.dto.ClubDto;
import com.club_community_backend.dto.ClubMemberDto;
import com.club_community_backend.entity.*;
import com.club_community_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ClubMemberService {
    private final ClubMemberRepository clubMemberRepository;
    private final UserRepository userRepository;
    private final ApplicationDocRepository applicationDocRepository;
    private final ApplicationFormRepository applicationFormRepository;
    private final ClubRepository clubRepository;

    private final ClubNotificationRepository notificationRepository;

    public boolean isAlreadyMember(ClubEntity club, UserEntity user) {
        return clubMemberRepository.existsByClubAndUser(club, user);
    }

    @Transactional
    public void joinClub(ClubEntity club, UserEntity user, ClubRole role, ClubJoinStatusRole status, String studentNo, String email) {
        ClubMemberEntity member = ClubMemberEntity.builder()
                .club(club)
                .user(user)
                .clubRole(role)
                .joinStatus(status)
                .email(email)
                .studentNo(studentNo)
                .build();
        clubMemberRepository.save(member);
    }

    public boolean isUserHasRole(ClubEntity club, Long userId, ClubRole role) {
        return clubMemberRepository.existsByClubAndUser_IdAndClubRoleAndJoinStatus(
                club, userId, role, ClubJoinStatusRole.APPROVED
        );
    }

    /**
     * 🔐 [보안 버그 수정] 직관적으로 운영진(회장 또는 관리자)이 맞다면 true를 반환하도록 전면 수정
     */
    public boolean isUserAdminOrPresident(ClubEntity club, Long userId) {
        boolean isPresident = clubMemberRepository.existsByClubAndUser_IdAndClubRoleAndJoinStatus(club, userId, ClubRole.CLUBPRESIDENT, ClubJoinStatusRole.APPROVED);
        boolean isClubAdmin = clubMemberRepository.existsByClubAndUser_IdAndClubRoleAndJoinStatus(club, userId, ClubRole.CLUBADMIN, ClubJoinStatusRole.APPROVED);
        return isPresident || isClubAdmin;
    }

    /**
     * 🎯 [신설] 내 텔레그램 ID 연동 및 알림 설정 업데이트
     */
    @Transactional
    public void updateTelegramSettings(Long clubId, Long userId, ClubMemberDto.UpdateTelegramRequest request) {
        ClubMemberEntity membership = clubMemberRepository.findByClubIdAndUserId(clubId, userId)
                .orElseThrow(() -> new IllegalArgumentException("해당 동아리의 멤버가 아닙니다."));

        // 덮어쓰기 위해 기존 데이터 조회, 없으면 새 엔티티 생성 (MapsId 구조 반영)
        ClubNotificationEntity notification = notificationRepository.findById(membership.getId())
                .orElseGet(() -> new ClubNotificationEntity(membership, request.getTelegramChatId(), request.isAlertEnabled()));

        // 값 업데이트 및 저장
        notification.updateSettings(request.getTelegramChatId(), request.isAlertEnabled());
        notificationRepository.save(notification);
    }

    /**
     * 동아리 내 유저 종합 컨텍스트 조회 (이름/전화번호는 유저 통합, 이메일은 동아리별 독립 적용)
     */
    public ClubMemberDto.UserContextResponse getClubUserContext(Long clubId, Long userId, boolean includeDoc) {
        // 1. 마스터 데이터(동아리, 유저) 뼈대 조회
        ClubEntity club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 동아리입니다."));

        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        // 2. 공통 동아리 메타 정보 조립
        ClubDto.UserJoinedResponse clubBriefDto = ClubDto.UserJoinedResponse.builder()
                .id(club.getId())
                .clubName(club.getClubName())
                .schoolName(club.getSchoolName())
                .clubType(club.getClubType())
                .build();

        // 3. 해당 동아리 가입 기록(멤버십) 확인
        Optional<ClubMemberEntity> membershipOpt = clubMemberRepository.findByClubIdAndUserId(clubId, userId);

        // [Case A] 가입 신청 안 한 순수 외부 방문자 (비회원 분기)
        if (membershipOpt.isEmpty()) {
            return ClubMemberDto.UserContextResponse.builder()
                    .clubInfo(clubBriefDto)
                    .uid(user.getId())
                    .clubMemberId(null)
                    .realName(user.getRealName())       // 마스터 테이블에서 공유
                    .phoneNumber(user.getPhoneNumber()) // 마스터 테이블에서 공유
                    .email(user.getEmail())             // 비회원이므로 계정 이메일을 임시 노출
                    .studentNo(null)
                    .clubRole("NONE")
                    .joinStatus("NONE")
                    .isManager(false)
                    .telegramChatId(null)
                    .isAlertEnabled(false)
                    .submittedDoc(null)
                    .formSettings(null)
                    .build();
        }

        // [Case B] 가입 신청 이력이 있는 유저 (대기자 및 정식 부원 분기)
        ClubMemberEntity membership = membershipOpt.get();
        ClubRole role = membership.getClubRole();
        boolean isManager = isUserAdminOrPresident(club, userId);

        // 🎯 [수정 파트] DB에서 해당 멤버의 텔레그램 연동 정보 실시간 조회
        ClubNotificationEntity notification = notificationRepository.findById(membership.getId()).orElse(null);
        String telegramChatId = (notification != null) ? notification.getTelegramChatId() : null;
        boolean isAlertEnabled = (notification != null) && notification.isAlertEnabled();

        String formSettings = applicationFormRepository.findByClubId(clubId)
                .map(ApplicationFormEntity::getFormSettings)
                .orElse(null);
        ClubMemberDto.SubmittedDocResponse submittedDocDto = null;
        if (includeDoc) {
            ApplicationDocEntity doc = applicationDocRepository.findByClubIdAndUserId(clubId, userId).orElse(null);

            if (doc != null) {
                submittedDocDto = ClubMemberDto.SubmittedDocResponse.builder()
                        .id(doc.getId()).formAnswers(doc.getFormRawData()).docPdfUrl(doc.getDocPdfUrl())
                        .build();
            }
        }



        return ClubMemberDto.UserContextResponse.builder()
                .clubInfo(clubBriefDto)
                .uid(user.getId())
                .clubMemberId(membership.getId())
                .realName(user.getRealName())
                .phoneNumber(user.getPhoneNumber())
                .email(membership.getEmail())
                .studentNo(membership.getStudentNo())
                .clubRole(role.name())
                .joinStatus(membership.getJoinStatus().name())
                .isManager(isManager)

                // 🎯 [수정 파트] 매핑 데이터 최종 DTO에 바인딩
                .telegramChatId(telegramChatId)
                .isAlertEnabled(isAlertEnabled)

                .submittedDoc(submittedDocDto)
                .formSettings(formSettings)
                .build();
    }

    public List<ClubDto.UserJoinedResponse> getJoinedClubs(Long userId) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        List<ClubMemberEntity> memberships = clubMemberRepository.findByUserAndJoinStatus(user, ClubJoinStatusRole.APPROVED);

        return memberships.stream()
                .map(ClubMemberEntity::getClub)
                .filter(club -> !club.getIsDelete())
                .map(club -> ClubDto.UserJoinedResponse.builder()
                        .id(club.getId())
                        .clubName(club.getClubName())
                        .schoolName(club.getSchoolName())
                        .clubType(club.getClubType())
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * 특정 동아리의 정식 승인된 회원 목록 조회 (N+1 최적화 적용)
     */
    public List<ClubMemberDto.MemberListResponse> getClubMemberList(Long clubId, Long requesterId) {
        // 1. 보안 검증: 요청을 보낸 유저가 이 동아리에 정식 가입된 멤버인지 체크 (외부인 열람 차단 필요 시)
        boolean isCurrentMember = clubMemberRepository.existsByClubIdAndUserIdAndJoinStatus(
                clubId, requesterId, ClubJoinStatusRole.APPROVED
        );
        if (!isCurrentMember) {
            throw new SecurityException("동아리 회원만 멤버 명단을 조회할 수 있습니다.");
        }

        // 2. FETCH JOIN 쿼리를 호출하여 APPROVED 상태인 멤버들을 최적화 조회
        List<ClubMemberEntity> members = clubMemberRepository.findApprovedMembersWithUser(clubId, ClubJoinStatusRole.APPROVED);

        // 3. 엔티티 리스트를 DTO 리스트로 변환하여 반환
        return members.stream()
                .map(member -> ClubMemberDto.MemberListResponse.builder()
                        .clubMemberId(member.getId())
                        .userId(member.getUser().getId())
                        .realName(member.getUser().getRealName())     // Fetch Join으로 인해 추가 쿼리 없음!
                        .studentNo(member.getStudentNo())
                        .email(member.getEmail())
                        .clubRole(member.getClubRole().name())
                        .joinedAt(member.getCreatedAt())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional
    public void updateMemberBasicInfo(Long clubId, Long userId, ClubMemberDto.UpdateBasicInfoRequest request) {
        ClubMemberEntity membership = clubMemberRepository.findByClubIdAndUserId(clubId, userId)
                .orElseThrow(() -> new IllegalArgumentException("해당 동아리의 멤버십 기록이 존재하지 않습니다."));

        // 엔티티 비즈니스 메서드 호출하여 변경 감지(Dirty Checking) 유도
        membership.updateBasicInfo(request.getStudentNo(), request.getEmail());
    }

    /**
     * 🎯 [신설] 내가 제출했던 가입 신청서 서류 데이터 수정
     */
    @Transactional
    public void updateSubmittedFormAnswers(Long clubId, Long userId, ClubMemberDto.UpdateFormAnswersRequest request) {
        // 서류가 제출된 적이 있어야 수정이 가능하므로 가입 신청 내역(ApplicationDoc) 검증
        ApplicationDocEntity doc = applicationDocRepository.findByClubIdAndUserId(clubId, userId)
                .orElseThrow(() -> new IllegalArgumentException("제출된 가입 신청서 내역을 찾을 수 없습니다."));

        // 엔티티 내부 메서드를 통해 제출된 JSON 통데이터 교체
        doc.updateFormRawData(request.getFormAnswers());
    }
}