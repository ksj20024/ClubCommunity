package com.club_community_backend.service;

import com.club_community_backend.dto.ApplicationFormDto;
import com.club_community_backend.entity.ApplicationFormEntity;
import com.club_community_backend.repository.ApplicationFormRepository;
import com.club_community_backend.repository.ClubRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ApplicationFormService {
    private final ApplicationFormRepository applicationFormRepository;
    private final ClubRepository clubRepository;
    private final FileStorageService storageService; // 다형성을 위해 인터페이스 주입 권장 (혹은 LocalStorageService)


    // 회장이 가입 양식을 설정할 때 워드 템플릿 파일을 저장소에 업로드
    public String uploadTemplate(String fileName, byte[] content) {
        return storageService.uploadFile(fileName, content);
    }

    // 특정 동아리의 가입 질문 폼 템플릿(JSON) 조회
    @Transactional(readOnly = true)
    public ApplicationFormDto.FormTemplateResponse getClubFormTemplate(Long clubId) {
        // 동아리 존재 검증
        clubRepository.findById(clubId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 동아리입니다."));

        // 가입 양식 테이블 조회
        ApplicationFormEntity form = applicationFormRepository.findByClubId(clubId)
                .orElseThrow(() -> new IllegalStateException("해당 동아리는 아직 가입 신청 양식을 설정하지 않았습니다."));

        return ApplicationFormDto.FormTemplateResponse.builder()
                .clubId(clubId)
                .formSettings(form.getFormSettings()) // 설정된 JSON 텍스트 반환
                .build();
    }
}
