package com.club_community_backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${file.upload-dir}")
    private String uploadDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 프론트엔드에서 http://IP주소:포트/storage/** 로 요청하면
        // 실제 컴퓨터의 file:C:/Users/.../backend/storage/ 경로로 매핑합니다.
        registry.addResourceHandler("/storage/**")
                .addResourceLocations("file:" + uploadDir);
        registry.addResourceHandler("/api/storage/**")
                .addResourceLocations("file:" + uploadDir);
    }
}