package com.club_community_backend.service;

import lombok.RequiredArgsConstructor;
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
    private final String rootPath = System.getProperty("user.dir") + "/storage/ApplicationDocs/";

    @Override
    public String uploadFile(String fileName, byte[] content) {
        try {
            // 스프링의 FileSystemResource를 활용하여 파일 객체 획득
            Resource resource = resourceLoader.getResource("file:" + rootPath + fileName);
            File file = resource.getFile();

            // 폴더 자동 생성 및 쓰기 (스프링이 관리하는 경로 기반)
            Files.createDirectories(file.getParentFile().toPath());
            Files.write(file.toPath(), content);

            return file.getAbsolutePath();
        } catch (IOException e) {
            throw new RuntimeException("로컬 파일 저장 실패", e);
        }
    }

    @Override
    public InputStream downloadFile(String fileUrl) {
        try {
            // 복잡한 FileInputStream 대신 스프링 리소스에서 스트림을 바로 뽑아옴
            Resource resource = resourceLoader.getResource("file:" + fileUrl);
            return resource.getInputStream();
        } catch (IOException e) {
            throw new RuntimeException("파일을 읽을 수 없습니다: " + fileUrl, e);
        }
    }
}
