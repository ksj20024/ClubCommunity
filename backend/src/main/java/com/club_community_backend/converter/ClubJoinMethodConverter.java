package com.club_community_backend.converter;

import com.club_community_backend.constant.ClubJoinMethodRole;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.util.Arrays;
import java.util.EnumSet;
import java.util.stream.Collectors;

@Converter
public class ClubJoinMethodConverter implements AttributeConverter<EnumSet<ClubJoinMethodRole>, String> {
    @Override
    public String convertToDatabaseColumn(EnumSet<ClubJoinMethodRole> attribute) {
        if (attribute == null || attribute.isEmpty()) return null;
        return attribute.stream().map(Enum::name).collect(Collectors.joining(","));
    }

    @Override
    public EnumSet<ClubJoinMethodRole> convertToEntityAttribute(String dbData) {
        if(dbData == null || dbData.isEmpty()) return EnumSet.noneOf(ClubJoinMethodRole.class);
        return Arrays.stream(dbData.split(","))
                .map(ClubJoinMethodRole::valueOf)
                .collect(Collectors.toCollection(() -> EnumSet.noneOf(ClubJoinMethodRole.class)));
    }
}
