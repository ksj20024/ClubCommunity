package com.club_community_backend.service;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@Service
@Profile("local") // application.properties의 spring.profiles.active=local일 때 활성화
public class LocalStorageService implements FileStorageService {

    private final String rootPath = System.getProperty("user.dir") + "/storage/ApplicationDocs";

    @Override
    public String uploadFile(String fileName, byte[] content) {
        Path targetPath = Paths.get(rootPath, fileName);
        try {
            Files.createDirectories(targetPath.getParent()); // 폴더가 없으면 생성
            Files.write(targetPath, content);
            return targetPath.toAbsolutePath().toString(); // 로컬 경로 반환
        } catch (IOException e) {
            throw new RuntimeException("로컬 파일 저장 실패", e);
        }
    }

    @Override
    public InputStream downloadFile(String filePath) {
        try {
            return new FileInputStream(filePath);
        } catch (FileNotFoundException e) {
            throw new RuntimeException("파일을 찾을 수 없습니다: " + filePath);
        }
    }
}
