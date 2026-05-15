package com.club_community_backend.converter;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Map;

import com.fasterxml.jackson.core.type.TypeReference;
import java.util.HashMap;

@Converter
public class JsonMapConverter implements AttributeConverter<Map<String, Object>, String> {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public String convertToDatabaseColumn(Map<String, Object> attribute) {
        if (attribute == null) return null; // 방어 코드
        try {
            return objectMapper.writeValueAsString(attribute);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("JSON writing error", e);
        }
    }

    @Override
    public Map<String, Object> convertToEntityAttribute(String dbData) {
        // 데이터가 없거나 빈 문자열일 경우 빈 맵 반환
        if (dbData == null || dbData.isBlank()) {
            return new HashMap<>();
        }

        try {
            // TypeReference를 사용하여 정확한 제네릭 타입을 명시
            return objectMapper.readValue(dbData, new TypeReference<Map<String, Object>>() {});
        } catch (JsonProcessingException e) {
            throw new RuntimeException("JSON reading error", e);
        }
    }
}
