package com.club_community_backend.entity;

import com.club_community_backend.constant.ClubJoinMethodRole;
import com.club_community_backend.constant.ClubTypeRole;
import com.club_community_backend.converter.ClubJoinMethodConverter;
import com.club_community_backend.dto.ClubDto;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SoftDelete;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.util.EnumSet;

@Entity
@Builder
@Getter
@EntityListeners(AuditingEntityListener.class)
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ClubEntity extends BaseTimeEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(nullable = false)
    private String clubName;

    // clubType이 SCHOOL일 때만
    private String schoolName;

    // joinType에 EMAIL이 포함되어 있을 때만
    private String domainRestriction;

    // 문서 자동 생성 사용 할지 말지
    private Boolean useAutoCreateApplicationDoc;

    // joinType에 CODE가 포함되어 있을 때만
    private String clubPassword;

    // 동아리 가입시 보안 설정 (자유 / 이메일 / 코드 / 관리자 확인) -> 자유 선택시 나머지 비활성화
    @NonNull
    @Column(nullable = false)
    @Convert(converter = ClubJoinMethodConverter.class)
    private EnumSet<ClubJoinMethodRole> joinType;

    // 동아리 성격 선택 (일반 / 학교 / 연합)
    @NonNull
    private ClubTypeRole clubType;

    // 동아리 삭제시 사용
    @SoftDelete
    @Builder.Default
    private Boolean isDelete = false;

    public void updateClub(ClubDto.UpdateRequest dto) {
        this.clubName = dto.getClubName();
        this.schoolName = dto.getSchoolName();
        this.domainRestriction = dto.getDomainRestriction();
        this.useAutoCreateApplicationDoc = dto.getUseAutoCreateApplicationDoc();
        this.clubPassword = dto.getClubPassword();
        this.joinType = dto.getJoinType();
        this.clubType = dto.getClubType();
    }
}
