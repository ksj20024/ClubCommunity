package com.club_community_backend.service;

import com.club_community_backend.constant.ClubJoinMethodRole;
import com.club_community_backend.constant.ClubJoinStatusRole;
import com.club_community_backend.constant.ClubRole;
import com.club_community_backend.constant.ClubTypeRole;
import com.club_community_backend.dto.ClubDto;
import com.club_community_backend.dto.ClubMemberDto;
import com.club_community_backend.entity.*;
import com.club_community_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ClubManagerService {

    private final ClubService clubService;
    private final ClubMemberService clubMemberService;
    private final UserRepository userRepository;
    private final ClubRepository clubRepository;
    private final ClubMemberRepository clubMemberRepository;
    private final ApplicationDocRepository applicationDocRepository;
    private final ApplicationDocService applicationDocService;
    private final ApplicationFormRepository applicationFormRepository;

    // 동아리 생성 및 회장 등록
    @Transactional
    public Long createClubWithPresident(ClubDto.CreateRequest clubDto, Long userId) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 학번 검증 (SCHOOL 타입일 때)
        if (clubDto.getClubType() == ClubTypeRole.SCHOOL && (clubDto.getStudentNo() == null || clubDto.getStudentNo().isBlank())) {
            throw new IllegalArgumentException("학교 소속 동아리는 대표의 학번 입력이 필수입니다.");
        }

        // 동아리 생성 (ClubService 활용)
        ClubEntity savedClub = clubService.createClub(clubDto);

        // 회장 등록 (ClubMemberService 활용)
        String studentNo = (clubDto.getClubType() == ClubTypeRole.SCHOOL) ? clubDto.getStudentNo() : null;
        clubMemberService.joinClub(savedClub, user, ClubRole.CLUBPRESIDENT, ClubJoinStatusRole.APPROVED, studentNo);

        return savedClub.getId();
    }

    // 입부 원서 양식 및 템플릿 파일 설정
    @Transactional
    public void setupApplicationForm(Long clubId, Long userId, byte[] fileContent, String originalFileName, String settingsJson) {
        ClubEntity club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 동아리입니다."));

        // 회장 권한 확인
        boolean isPresident = clubMemberService.isUserHasRole(club, userId, ClubRole.CLUBPRESIDENT);
        if (!isPresident) {
            throw new SecurityException("동아리 가입 양식 설정 권한이 없습니다.");
        }

        // 확장자 추출 및 고유 파일명 설계
        String extension = originalFileName.substring(originalFileName.lastIndexOf("."));
        String fileName = String.format("templates/%d_template_%d%s", clubId, System.currentTimeMillis(), extension);

        // 스토리지 업로드 연동
        String templateFileUrl = applicationDocService.uploadTemplate(fileName, fileContent);

        // 엔티티 빌드 및 영속화
        ApplicationFormEntity form = ApplicationFormEntity.builder()
                .club(club)
                .templateDocUrl(templateFileUrl)
                .formSettings(settingsJson)
                .build();

        applicationFormRepository.save(form);
    }

    // 일반 유저 가입 신청 및 가입 원서 문서 자동 생성
    @Transactional
    public void applyToClub(Long clubId, Long userId, ClubMemberDto.JoinRequest joinDto) {
        ClubEntity club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 동아리입니다."));
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 1. 중복 가입 체크
        if (clubMemberService.isAlreadyMember(club, user)) {
            throw new IllegalStateException("이미 가입되어 있거나 승인 대기 중입니다.");
        }

        // 2. 가입 조건 분기 검증
        validateJoinPolicy(club, joinDto);

        // 3. 결격 승인제 여부에 따른 초기 상태 결정
        ClubJoinStatusRole status = club.getJoinType().contains(ClubJoinMethodRole.APPROVAL)
                ? ClubJoinStatusRole.PENDING : ClubJoinStatusRole.APPROVED;

        // 4. 동아리 멤버십 관계 저장
        String studentNo = (club.getClubType() == ClubTypeRole.SCHOOL) ? joinDto.getStudentNo() : null;
        clubMemberService.joinClub(club, user, ClubRole.MEMBER, status, studentNo);

        // 5. 자동 문서 생성 옵션 켜져있을 시 동작
        if (club.getUseAutoCreateApplicationDoc()) {
            ApplicationFormEntity form = applicationFormRepository.findByClub(club)
                    .orElseThrow(() -> new IllegalStateException("가입 양식 설정이 완료되지 않았습니다."));

            Map<String, Object> answers = extractAnswers(joinDto);
            String docUrl = applicationDocService.generateAndUploadDoc(user, club, form, answers);

            // AttributeConverter 덕분에 Map을 그대로 밀어 넣어도 DB에는 JSON 텍스트로 보관됨
            applicationDocRepository.save(ApplicationDocEntity.builder()
                    .user(user)
                    .club(club)
                    .formRawData(answers)
                    .docPdfUrl(docUrl)
                    .build());
        }
    }

    // 승인 대기 중인 신청자 전체 목록 조회
    @Transactional(readOnly = true)
    public List<ClubMemberDto.PendingResponse> getPendingApplicants(Long clubId, Long managerId) {
        ClubEntity club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 동아리입니다."));

        if (!clubMemberService.isUserAdminOrPresident(club, managerId)) {
            throw new SecurityException("신청자 명단을 조회할 권한이 없습니다.");
        }

        List<ClubMemberEntity> pendingMembers = clubMemberRepository.findPendingMembersWithDoc(clubId);

        return pendingMembers.stream().map(member -> {
            ApplicationDocEntity doc = applicationDocRepository.findByClubAndUser(club, member.getUser())
                    .orElse(null);

            return ClubMemberDto.PendingResponse.builder()
                    .userId(member.getUser().getId())
                    .userName(member.getUser().getRealName())
                    .studentNo(member.getStudentNo())
                    .email(member.getUser().getEmail())
                    .appliedAt(member.getCreatedAt())
                    .formAnswers(doc != null ? doc.getFormRawData() : null)
                    .applicationDocId(doc != null ? doc.getId() : null)
                    .build();
        }).collect(Collectors.toList());
    }

    // 신청자 승인 혹은 반려 상태 업데이트
    @Transactional
    public void updateApplicantStatus(Long clubId, Long applicantId, Long managerId, ClubJoinStatusRole newStatus) {
        ClubEntity club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 동아리입니다."));

        if (!clubMemberService.isUserAdminOrPresident(club, managerId)) {
            throw new SecurityException("권한이 없습니다.");
        }

        ClubMemberEntity applicant = clubMemberRepository.findByClubAndUser_Id(club, applicantId)
                .orElseThrow(() -> new IllegalArgumentException("신청 정보를 찾을 수 없습니다."));

        if (applicant.getJoinStatus() != ClubJoinStatusRole.PENDING) {
            throw new IllegalStateException("이미 처리된 신청 건입니다.");
        }

        applicant.updateJoinStatus(newStatus);

        if (newStatus == ClubJoinStatusRole.APPROVED) {
            applicant.updateRole(ClubRole.MEMBER);
        }
    }

    // 특정 개별 가입 신청 원서의 답변 내용 조회 (화면 가공용)
    @Transactional(readOnly = true)
    public Map<String, Object> getDocDetail(Long docId) {
        ApplicationDocEntity doc = applicationDocRepository.findById(docId)
                .orElseThrow(() -> new IllegalArgumentException("문서를 찾을 수 없습니다."));
        return doc.getFormRawData();
    }

    private void validateJoinPolicy(ClubEntity club, ClubMemberDto.JoinRequest dto) {
        EnumSet<ClubJoinMethodRole> joinTypes = club.getJoinType();

        if (joinTypes.contains(ClubJoinMethodRole.FREE)) return;

        if (joinTypes.contains(ClubJoinMethodRole.EMAIL)) {
            if (dto.getEmail() == null || dto.getEmail().isBlank()) {
                throw new IllegalArgumentException("이메일 입력이 필요합니다.");
            }
            if (!dto.getEmail().endsWith(club.getDomainRestriction())) {
                throw new IllegalArgumentException("해당 동아리는 " + club.getDomainRestriction() + " 도메인 이메일만 가입 가능합니다.");
            }
        }

        if (joinTypes.contains(ClubJoinMethodRole.CODE)) {
            if (dto.getClubPassword() == null || dto.getClubPassword().isBlank()) {
                throw new IllegalArgumentException("가입 코드를 입력해주세요.");
            }
            if (!club.getClubPassword().equals(dto.getClubPassword())) {
                throw new IllegalArgumentException("가입 코드가 일치하지 않습니다.");
            }
        }
    }

    private Map<String, Object> extractAnswers(ClubMemberDto.JoinRequest joinDto) {
        Map<String, Object> answers = joinDto.getAnswers();
        if (answers == null || answers.isEmpty()) {
            throw new IllegalArgumentException("가입 질문에 대한 답변이 누락되었습니다.");
        }
        answers.put("applyDate", java.time.LocalDate.now().toString());
        return answers;
    }
}