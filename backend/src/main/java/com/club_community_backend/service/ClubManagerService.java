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
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
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
    private final ApplicationFormService applicationFormService;

    // 동아리 생성 및 회장 등록
    @Transactional
    public Long createClubWithPresident(ClubDto.CreateRequest clubDto, Long userId) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        if (clubDto.getClubType() == ClubTypeRole.SCHOOL && (clubDto.getStudentNo() == null || clubDto.getStudentNo().isBlank())) {
            throw new IllegalArgumentException("학교 소속 동아리는 대표의 학번 입력이 필수입니다.");
        }

        // 동아리 생성 및 저장
        ClubEntity savedClub = clubService.createClub(clubDto);

        // 회장 등록
        String studentNo = (clubDto.getClubType() == ClubTypeRole.SCHOOL) ? clubDto.getStudentNo() : null;
        String email = (clubDto.getJoinType().contains(ClubJoinMethodRole.EMAIL)) ? clubDto.getEmail() : null;
        clubMemberService.joinClub(savedClub, user, ClubRole.CLUBPRESIDENT, ClubJoinStatusRole.APPROVED, studentNo, email);

        // 동아리 최초 생성 시, 질문/템플릿이 비어있는 공백 양식 엔티티를 미리 생성
        // 질문 설정이나 템플릿 등록 함수가 아무런 순서 제약 없이 '독립적'실행
        ApplicationFormEntity initialForm = ApplicationFormEntity.builder()
                .club(savedClub)
                .formSettings(null)     // 초기값 없음
                .templateDocUrl(null)   // 초기값 없음
                .build();
        applicationFormRepository.save(initialForm);

        return savedClub.getId();
    }

    /**
     * 2. 순수 가입 질문 폼 설정 (생성 및 수정 공용)
     */
    @Transactional
    public void setupFormQuestions(Long clubId, Long userId, String settingsJson) {
        ClubEntity club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 동아리입니다."));

        if (!clubMemberService.isUserHasRole(club, userId, ClubRole.CLUBPRESIDENT)) {
            throw new SecurityException("동아리 가입 질문 설정 권한이 없습니다.");
        }

        // 데이터가 유실되어 폼이 없을 때는 새로 생성하여 방어
        ApplicationFormEntity form = applicationFormRepository.findByClub(club)
                .orElseGet(() -> ApplicationFormEntity.builder().club(club).build());

        form.updateSettings(settingsJson);
        applicationFormRepository.save(form);
    }

    /**
     * 3. 순수 입부 원서 문서 템플릿 파일 설정 (생성 및 수정 공용)
     */
    @Transactional
    public void setupFormTemplate(Long clubId, Long userId, MultipartFile file) throws IOException {
        ClubEntity club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 동아리입니다."));

        if (!clubMemberService.isUserHasRole(club, userId, ClubRole.CLUBPRESIDENT)) {
            throw new SecurityException("동아리 문서 템플릿 설정 권한이 없습니다.");
        }

        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("업로드할 템플릿 파일이 비어있습니다.");
        }

        ApplicationFormEntity form = applicationFormRepository.findByClub(club)
                .orElseGet(() -> ApplicationFormEntity.builder().club(club).build());

        String originalFileName = file.getOriginalFilename();
        if (originalFileName == null || !originalFileName.endsWith(".docx")) {
            throw new IllegalArgumentException("워드 파일(.docx) 형식만 업로드 가능합니다.");
        }

        String extension = originalFileName.substring(originalFileName.lastIndexOf("."));
        String fileName = String.format("ApplicationDocs/templates/%d_template_%d%s", clubId, System.currentTimeMillis(), extension);

        String templateFileUrl = applicationFormService.uploadTemplate(fileName, file.getBytes());
        form.updateTemplateDocUrl(templateFileUrl);

        applicationFormRepository.save(form);
    }

    /**
     * ✅ [로직 분리 3] 일반 유저 가입 신청 (문서 자동생성은 옵션에 따라 '선택적' 분기 처리)
     */
    @Transactional
    public void applyToClub(Long clubId, Long userId, ClubMemberDto.JoinRequest joinDto) {
        ClubEntity club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 동아리입니다."));
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        if (clubMemberService.isAlreadyMember(club, user)) {
            throw new IllegalStateException("이미 가입되어 있거나 승인 대기 중입니다.");
        }

        validateJoinPolicy(club, joinDto);

        ClubJoinStatusRole status = club.getJoinType().contains(ClubJoinMethodRole.APPROVAL)
                ? ClubJoinStatusRole.PENDING : ClubJoinStatusRole.APPROVED;

        String studentNo = (club.getClubType() == ClubTypeRole.SCHOOL) ? joinDto.getStudentNo() : null;
        String email = (club.getJoinType().contains(ClubJoinMethodRole.EMAIL)) ? joinDto.getEmail() : null;
        clubMemberService.joinClub(club, user, ClubRole.MEMBER, status, studentNo, email);

        // 📝 웹 질문 답변 폼 데이터 가공 (항상 공통 수행)
        Map<String, Object> answers = extractAnswers(joinDto);
        String docUrl = null;

        // ⚙️ [선택적 요청 분기] 동아리 옵션이 활성화된 경우에만 워드 가입 원서 파일 실제 생성
        if (club.getUseAutoCreateApplicationDoc()) {
            ApplicationFormEntity form = applicationFormRepository.findByClub(club)
                    .orElseThrow(() -> new IllegalStateException("동아리의 가입 원서 양식 설정이 완료되지 않았습니다."));

            if (form.getTemplateDocUrl() != null) {
                docUrl = applicationDocService.generateAndUploadDoc(user, club, form, answers);
            }
        }

        // DB에 기록 연동 (자동생성이 꺼져있다면 docPdfUrl은 자연스럽게 null로 기록됨)
        applicationDocRepository.save(ApplicationDocEntity.builder()
                .user(user)
                .club(club)
                .formRawData(answers)
                .docPdfUrl(docUrl)
                .build());
    }

    /**
     * ✅ [요구사항 3 해결] 자동생성 기능을 사후 활성화 시, 과거 가입 유저의 누락된 워드 문서를 추적 및 소급 빌드
     */
    @Transactional
    public Map<String, Object> syncMissingApplicationDocs(Long clubId, Long managerId) {
        ClubEntity club = clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 동아리입니다."));

        if (!clubMemberService.isUserAdminOrPresident(club, managerId)) {
            throw new SecurityException("동아리 데이터 관리 권한이 없습니다.");
        }

        // 현재 자동 생성 옵션이 켜져 있는지 최종 확인 검증
        if (!club.getUseAutoCreateApplicationDoc()) {
            throw new IllegalStateException("해당 동아리는 현재 입부원서 자동 생성 옵션이 비활성화 상태입니다.");
        }

        ApplicationFormEntity form = applicationFormRepository.findByClub(club)
                .orElseThrow(() -> new IllegalStateException("동아리에 등록된 양식 설정 정보가 없습니다."));

        if (form.getTemplateDocUrl() == null) {
            throw new IllegalStateException("동아리에 등록된 워드 문서 템플릿 파일(.docx)이 없어 소급 생성이 불가능합니다.");
        }

        // 🔍 데이터 마이그레이션 대상 추적: 해당 동아리 문서 중 파일 경로(docPdfUrl)가 비어있는 내역 전원 색출
        List<ApplicationDocEntity> allDocs = applicationDocRepository.findByClub(club);
        List<ApplicationDocEntity> targets = allDocs.stream()
                .filter(doc -> doc.getDocPdfUrl() == null || doc.getDocPdfUrl().isBlank())
                .toList();

        int successCount = 0;
        for (ApplicationDocEntity doc : targets) {
            try {
                // 과거 수집해 둔 JSON 답변 데이터 획득
                Map<String, Object> answers = doc.getFormRawData();

                // 뼈대 파일 구조에 맞춰 새로운 파일 연동 및 파일 스토리지 업로드
                String generatedUrl = applicationDocService.generateAndUploadDoc(doc.getUser(), club, form, answers);

                // 엔티티 필드 최신 업데이트 반영 (Dirty Checking 활용 또는 명시적 save)
                doc.updateDocPdfUrl(generatedUrl); // 💡 엔티티 내부에 세터 대신 수동 업데이트 메서드 추가 필요
                applicationDocRepository.save(doc);
                successCount++;
            } catch (Exception e) {
                log.error("과거 유저(ID: {})의 누락 원서 소급 생성 중 예외 발생: {}", doc.getUser().getId(), e.getMessage());
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("totalMissingTargets", targets.size());
        result.put("successfullySyncedCount", successCount);
        return result;
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
                    .id(member.getUser().getId())
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
            throw new SecurityException("동아리 처리 권한이 없습니다.");
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

    // 특정 개별 가입 신청 원서의 답변 내용 조회
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