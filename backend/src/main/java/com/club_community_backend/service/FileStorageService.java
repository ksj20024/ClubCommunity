package com.club_community_backend.service;

import java.io.InputStream;

public interface FileStorageService {
    String uploadFile(String fileName, byte[] content);
    InputStream downloadFile(String fileUrl);
}