package com.club_community_backend.entity;

import com.club_community_backend.converter.JsonMapConverter;
import jakarta.persistence.*;
import lombok.*;

import java.util.Map;

@Entity
@Builder
@Getter
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ApplicationDocEntity extends BaseTimeEntity {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id", nullable = false)
    private ClubEntity club;

    // 타입을 Map으로 변경하고 컨버터 적용
    @Convert(converter = JsonMapConverter.class)
    @Column(columnDefinition = "TEXT", nullable = false)
    private Map<String, Object> formRawData;

    @Column(nullable = false)
    private String docPdfUrl;
}
