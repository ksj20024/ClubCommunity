package com.club_community_backend.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Service;

import java.io.*;
import java.nio.file.Files;

@Service
@Profile("local")
@RequiredArgsConstructor
public class LocalStorageService implements FileStorageService {

    private final ResourceLoader resourceLoader;

    // 🎯 application.properties에 등록한 컴퓨터 물리 루트 디렉토리를 안전하게 주입받습니다.
    @Value("${file.upload-dir}")
    private String uploadDir;

    @Override
    public String uploadFile(String fileName, byte[] content) {
        try {
            // 🎯 하드디스크의 실제 물리 경로 조립
            // 예: C:/Users/.../backend/storage/ + posts/동아리ID_시간_파일명.png
            Resource resource = resourceLoader.getResource("file:" + uploadDir + fileName);
            File file = resource.getFile();

            // 상위 부모 폴더(storage/posts/) 자동 생성 및 바이너리 쓰기
            Files.createDirectories(file.getParentFile().toPath());
            Files.write(file.toPath(), content);

            // 🚨 [핵심 수정] DB에는 절대 경로(C:/...)가 아니라, 플러터가 다운로드할 수 있는 웹 상대 경로를 반환합니다.
            // 반환 포맷: /storage/posts/동아리ID_시간_파일명.png
            return "/storage/" + fileName;
        } catch (IOException e) {
            throw new RuntimeException("로컬 파일 저장 실패", e);
        }
    }

    @Override
    public InputStream downloadFile(String fileUrl) {
        try {
            // DB에 가상 웹 경로(/storage/posts/...)로 저장되어 있으므로,
            // 백엔드 내부에서 읽어 들일 때는 다시 하드디스크 물리 경로로 치환하여 추적합니다.
            String relativePath = fileUrl.replace("/storage/", "");
            Resource resource = resourceLoader.getResource("file:" + uploadDir + relativePath);
            return resource.getInputStream();
        } catch (IOException e) {
            throw new RuntimeException("파일을 읽을 수 없습니다: " + fileUrl, e);
        }
    }
}