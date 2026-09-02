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
    private final FileStorageService storageService;

    /**
     * 일반 유저 가입 시 템플릿을 읽어와 가입 원서(.docx)를 자동 생성하고 업로드
     */
    @Transactional
    public String generateAndUploadDoc(UserEntity user, ClubEntity club, ApplicationFormEntity form, Map<String, Object> answers) {

        // 복잡한 File 객체 조립 대신, 이미 구현해 둔 storageService의 downloadFile을 호출합니다.
        // 내부적으로 "/storage/"를 자동으로 걷어내고 실제 바탕화면 스토리지의 물리 파일 스트림을 완벽하게 열어줍니다.
        try (InputStream templateStream = storageService.downloadFile(form.getTemplateDocUrl());
             XWPFTemplate template = XWPFTemplate.compile(templateStream).render(answers)) {

            // 메모리 내에서 문서 렌더링
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            template.write(out);

            // 생성될 유저별 가입 신청서 파일명 설계 (storage/generated/ 폴더 하위에 생성됨)
            String fileName = String.format("generated/%d_%d_%d.docx",
                    club.getId(), user.getId(), System.currentTimeMillis());

            // 파일 저장소에 물리적 저장 실행 및 웹 가상 상대 경로 반환 (/storage/generated/...)
            return storageService.uploadFile(fileName, out.toByteArray());

        } catch (IOException e) {
            throw new RuntimeException("가입 신청서 문서 생성 중 오류가 발생했습니다.", e);
        }
    }

    /**
     * 관리자가 신청서 다운로드 버튼을 눌렀을 때, DB에서 경로를 찾아 스프링 리소스로 반환
     */
    @Transactional(readOnly = true)
    public Resource downloadApplicationFile(Long docId) {
        ApplicationDocEntity doc = applicationDocRepository.findById(docId)
                .orElseThrow(() -> new IllegalArgumentException("문서를 찾을 수 없습니다."));

        InputStream fileStream = storageService.downloadFile(doc.getDocPdfUrl());

        return new InputStreamResource(fileStream);
    }
}