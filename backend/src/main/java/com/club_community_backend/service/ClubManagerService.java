package com.club_community_backend.service;

import com.club_community_backend.constant.ClubJoinMethodRole;
import com.club_community_backend.constant.ClubJoinStatusRole;
import com.club_community_backend.constant.ClubRole;
import com.club_community_backend.constant.ClubTypeRole;
import com.club_community_backend.dto.ClubDto;
import com.club_community_backend.dto.ClubMemberDto;
import com.club_community_backend.entity.ApplicationDocEntity;
import com.club_community_backend.entity.ApplicationFormEntity;
import com.club_community_backend.entity.ClubEntity;
import com.club_community_backend.entity.UserEntity;
import com.club_community_backend.repository.ApplicationDocRepository;
import com.club_community_backend.repository.ApplicationFormRepository;
import com.club_community_backend.repository.ClubRepository;
import com.club_community_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ClubManagerService {

    private final ClubService clubService;
    private final ClubMemberService clubMemberService;
    private final UserRepository userRepository;
    private final ClubRepository clubRepository;
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

    @Transactional
    public void setupApplicationForm(Long clubId, Long userId, byte[] fileContent, String originalFileName, String settingsJson) {
        // 1. 동아리 존재 확인
        ClubEntity club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 동아리입니다."));

        // 2. 권한 확인: 요청한 유저가 이 동아리의 회장(CLUBPRESIDENT)인지 확인
        // ClubMemberService에 해당 로직이 있다고 가정하거나 여기서 직접 체크합니다.
        boolean isPresident = clubMemberService.isUserHasRole(club, userId, ClubRole.CLUBPRESIDENT);
        if (!isPresident) {
            throw new SecurityException("동아리 가입 양식 설정 권한이 없습니다.");
        }

        // 3. 템플릿 파일 업로드 (FileStorageService 활용)
        // 파일명 중복 방지를 위해 UUID나 타임스탬프를 섞는 것이 좋습니다.
        String extension = originalFileName.substring(originalFileName.lastIndexOf("."));
        String fileName = String.format("templates/%d_template_%d%s",
                clubId, System.currentTimeMillis(), extension);

        // 로컬 혹은 S3로 자동 업로드 후 URL 반환
        String templateFileUrl = applicationDocService.uploadTemplate(fileName, fileContent);

        // 4. 가입 양식 엔티티 생성 및 저장
        ApplicationFormEntity form = ApplicationFormEntity.builder()
                .club(club)
                .templateDocUrl(templateFileUrl)
                .formSettings(settingsJson)
                .build();

        applicationFormRepository.save(form);
    }

    // 일반 유저 가입
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

        // 2. 가입 조건 및 이메일 도메인 대조 로직
        validateJoinPolicy(club, joinDto);

        // 3. 상태 결정 (APPROVAL이 있으면 PENDING, 아니면 APPROVED)
        ClubJoinStatusRole status = club.getJoinType().contains(ClubJoinMethodRole.APPROVAL)
                ? ClubJoinStatusRole.PENDING : ClubJoinStatusRole.APPROVED;

        // 4. 멤버 저장
        String studentNo = (club.getClubType() == ClubTypeRole.SCHOOL) ? joinDto.getStudentNo() : null;
        clubMemberService.joinClub(club, user, ClubRole.MEMBER, status, studentNo);

        if (club.getUseAutoCreateApplicationDoc()) {
            ApplicationFormEntity form = applicationFormRepository.findByClub(club)
                    .orElseThrow(() -> new IllegalStateException("가입 양식 설정이 완료되지 않았습니다."));

            // joinDto나 별도 전달받은 답변 리스트를 Map으로 변환
            Map<String, Object> answers = extractAnswers(joinDto);

            String docUrl = applicationDocService.generateAndUploadDoc(user, club, form, answers);

            // 6. 생성된 문서 엔티티 저장
            applicationDocRepository.save(ApplicationDocEntity.builder()
                    .user(user)
                    .club(club)
                    .formRawData(answers) // JSON 형태 답변 원본
                    .docPdfUrl(docUrl) // 실제로는 docx 경로
                    .build());
        }
    }

    private Map<String, Object> extractAnswers(ClubMemberDto.JoinRequest joinDto) {
        // 1. 유저가 보낸 답변 Map (e.g., {"reason": "열심히 하겠습니다", "studentNum": "20240101" ...})
        Map<String, Object> answers = joinDto.getAnswers();

        if (answers == null || answers.isEmpty()) {
            throw new IllegalArgumentException("가입 질문에 대한 답변이 누락되었습니다.");
        }

        // 2. 시스템에서 자동으로 넣어줄 공통 변수들 (선택 사항)
        // 템플릿에 {{applyDate}}라고 적어두면 오늘 날짜가 찍힙니다.
        answers.put("applyDate", java.time.LocalDate.now().toString());


        return answers;
    }

    private void validateJoinPolicy(ClubEntity club, ClubMemberDto.JoinRequest dto) {
        EnumSet<ClubJoinMethodRole> joinTypes = club.getJoinType();

        // FREE 방식이면 검증 통과
        if (club.getJoinType().contains(ClubJoinMethodRole.FREE)) return;

        // 이메일 도메인 체크: EMAIL 방식이 포함되어 있다면 반드시 대조
        if (joinTypes.contains(ClubJoinMethodRole.EMAIL)) {
            if (dto.getEmail() == null || dto.getEmail().isBlank()) {
                throw new IllegalArgumentException("이메일 입력이 필요합니다.");
            }
            if (!dto.getEmail().endsWith(club.getDomainRestriction())) {
                throw new IllegalArgumentException("해당 동아리는 " + club.getDomainRestriction() + " 도메인 이메일만 가입 가능합니다.");
            }
        }

        // CODE 방식: 동아리 비밀번호 대조
        if (joinTypes.contains(ClubJoinMethodRole.CODE)) {
            if (dto.getClubPassword() == null || dto.getClubPassword().isBlank()) {
                throw new IllegalArgumentException("가입 코드를 입력해주세요.");
            }
            if (!club.getClubPassword().equals(dto.getClubPassword())) {
                throw new IllegalArgumentException("가입 코드가 일치하지 않습니다.");
            }
        }
    }
}