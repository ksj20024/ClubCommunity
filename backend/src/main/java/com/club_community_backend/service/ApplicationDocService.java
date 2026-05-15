package com.club_community_backend.service;

import com.club_community_backend.entity.ApplicationFormEntity;
import com.club_community_backend.entity.ClubEntity;
import com.club_community_backend.entity.UserEntity;
import com.club_community_backend.repository.ApplicationDocRepository;
import com.deepoove.poi.XWPFTemplate;
import lombok.RequiredArgsConstructor;
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
    private final FileStorageService storageService; // 인터페이스 주입

    @Transactional
    public String generateAndUploadDoc(UserEntity user, ClubEntity club, ApplicationFormEntity form, Map<String, Object> answers) {

        // 1. 저장소에서 템플릿 파일 가져오기 (로컬 혹은 S3)
        InputStream templateStream = storageService.downloadFile(form.getTemplateDocUrl());

        try (XWPFTemplate template = XWPFTemplate.compile(templateStream).render(answers)) {
            // 2. 문서 렌더링
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            template.write(out);

            // 3. 파일명 생성
            String fileName = String.format("%d_%d_%d.docx",
                    club.getId(), user.getId(), System.currentTimeMillis());

            // 4. 업로드 실행 (로컬 프로파일이면 로컬에, s3면 s3에 저장됨)
            return storageService.uploadFile(fileName, out.toByteArray());

        } catch (IOException e) {
            throw new RuntimeException("문서 생성 중 오류 발생", e);
        }
    }

    public String uploadTemplate(String fileName, byte[] content) {
        // FileStorageService를 통해 실제 물리적 저장을 수행
        return storageService.uploadFile(fileName, content);
    }
}