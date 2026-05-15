package com.club_community_backend.service;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import java.io.ByteArrayInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import io.awspring.cloud.s3.S3Template;

@Service
@Profile("s3")
@RequiredArgsConstructor
public class S3StorageService implements FileStorageService {

    private final S3Template s3Template;
    private final String bucketName = "my-club-bucket";

    @Override
    public String uploadFile(String fileName, byte[] content) {
        try {
            // S3Template.upload는 내부적으로 S3Exception(Runtime)을 던질 수 있음
            var resource = s3Template.upload(bucketName, fileName, new ByteArrayInputStream(content));
            return resource.getURL().toString();
        } catch (Exception e) {
            // 업로드 중 발생하는 모든 예외를 커스텀 혹은 런타임 예외로 전환
            throw new RuntimeException("S3 파일 업로드에 실패했습니다: " + fileName, e);
        }
    }

    @Override
    public InputStream downloadFile(String fileUrl) {
        try {
            // 1. URL에서 Key 추출 (안전한 추출 로직)
            String key = extractKey(fileUrl);

            // 2. 파일 리소스 가져오기
            var resource = s3Template.download(bucketName, key);

            // 3. 파일 존재 여부 확인 (Optional)
            if (!resource.exists()) {
                throw new FileNotFoundException("S3에 해당 파일이 존재하지 않습니다: " + key);
            }

            // 4. getInputStream()의 IOException을 잡기 위해 try-catch 내에서 실행
            return resource.getInputStream();

        } catch (IOException e) {
            throw new RuntimeException("S3 파일 스트림을 읽는 중 오류가 발생했습니다.", e);
        } catch (Exception e) {
            throw new RuntimeException("S3 파일 다운로드 중 알 수 없는 오류가 발생했습니다.", e);
        }
    }

    private String extractKey(String fileUrl) {
        if (fileUrl == null || !fileUrl.contains("/")) {
            throw new IllegalArgumentException("잘못된 파일 URL 형식입니다.");
        }
        return fileUrl.substring(fileUrl.lastIndexOf("/") + 1);
    }
}