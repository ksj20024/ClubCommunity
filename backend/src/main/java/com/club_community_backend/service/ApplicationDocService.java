package com.club_community_backend.service;

import com.club_community_backend.entity.ApplicationDocEntity;
import com.club_community_backend.entity.ApplicationFormEntity;
import com.club_community_backend.entity.ClubEntity;
import com.club_community_backend.entity.UserEntity;
import com.club_community_backend.repository.ApplicationDocRepository;
import com.deepoove.poi.XWPFTemplate;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ApplicationDocService {

    private final ApplicationDocRepository applicationDocRepository;
    private final ResourceLoader resourceLoader;
    private final FileStorageService storageService; // 다형성을 위해 인터페이스 주입 권장 (혹은 LocalStorageService)

    /**
     * 1. 일반 유저 가입 시 템플릿을 읽어와 가입 원서(.docx)를 자동 생성하고 업로드
     */
    @Transactional
    public String generateAndUploadDoc(UserEntity user, ClubEntity club, ApplicationFormEntity form, Map<String, Object> answers) {
        // ResourceLoader를 활용해 회장이 올린 템플릿 파일 로드
        Resource templateResource = resourceLoader.getResource("file:" + form.getTemplateDocUrl());

        try (InputStream templateStream = templateResource.getInputStream();
             XWPFTemplate template = XWPFTemplate.compile(templateStream).render(answers)) {

            // 메모리 내에서 문서 렌더링
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            template.write(out);

            // 생성될 유저별 가입 신청서 파일명 설계
            String fileName = String.format("%d_%d_%d.docx",
                    club.getId(), user.getId(), System.currentTimeMillis());

            // 파일 저장소에 물리적 저장 실행
            return storageService.uploadFile(fileName, out.toByteArray());

        } catch (IOException e) {
            throw new RuntimeException("가입 신청서 문서 생성 중 오류가 발생했습니다.", e);
        }
    }

    /**
     * 2. [기존 함수 복구] 회장이 가입 양식을 설정할 때 워드 템플릿 파일을 저장소에 업로드
     */
    public String uploadTemplate(String fileName, byte[] content) {
        return storageService.uploadFile(fileName, content);
    }

    /**
     * 3. [신규 추가] 관리자가 신청서 다운로드 버튼을 눌렀을 때, DB에서 경로를 찾아 스프링 리소스로 반환
     */
    @Transactional(readOnly = true)
    public Resource downloadApplicationFile(Long docId) {
        // DB에서 문서 엔티티 조회
        ApplicationDocEntity doc = applicationDocRepository.findById(docId)
                .orElseThrow(() -> new IllegalArgumentException("문서를 찾을 수 없습니다."));

        // storageService가 반환하는 InputStream을 가져옴
        InputStream fileStream = storageService.downloadFile(doc.getDocPdfUrl());

        // 컨트롤러가 ResponseEntity<Resource>로 리턴할 수 있도록 스프링의 InputStreamResource로 감싸서 반환
        return new InputStreamResource(fileStream);
    }
}