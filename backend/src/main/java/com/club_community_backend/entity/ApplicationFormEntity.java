package com.club_community_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ApplicationFormEntity extends BaseTimeEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id")
    private ClubEntity club;

    // 회장이 업로드한 원본 워드 템플릿 파일 경로 (S3)
    private String templateDocUrl;

    // 질문 리스트와 치환자 매핑 정보 (JSON 형태)
    // 예: [{"question": "이름", "key": "userName"}, {"question": "지원동기", "key": "reason"}]
    @Column(columnDefinition = "TEXT")
    private String formSettings;
}
