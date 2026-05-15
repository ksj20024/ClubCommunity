package com.club_community_backend.service;

import com.club_community_backend.constant.ClubJoinMethodRole;
import com.club_community_backend.constant.ClubTypeRole;
import com.club_community_backend.dto.ClubDto;
import com.club_community_backend.entity.ClubEntity;
import com.club_community_backend.repository.ClubRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ClubService {
    private final ClubRepository clubRepository;

    @Transactional
    public ClubEntity createClub(ClubDto.CreateRequest dto) {
        if (clubRepository.existsByClubName(dto.getClubName())) {
           throw new IllegalStateException("이미 존재하는 동아리 명입니다.");
        }

        validateClubConstraints(dto);

        ClubEntity club = ClubEntity.builder()
            .clubName(dto.getClubName())
            .schoolName(dto.getSchoolName())
            .domainRestriction(dto.getJoinType().contains(ClubJoinMethodRole.EMAIL) ? dto.getDomainRestriction() : null)
            .useAutoCreateApplicationDoc(dto.getUseAutoCreateApplicationDoc())
            .clubPassword(dto.getJoinType().contains(ClubJoinMethodRole.CODE) ? dto.getClubPassword() : null)
            .clubType(dto.getClubType())
            .joinType(dto.getJoinType())
            .build();

        return clubRepository.save(club);
    }

    private void validateClubConstraints(ClubDto.ClubValidatable dto) {

        if(dto.getJoinType() == null || dto.getJoinType().isEmpty()) {
            throw new IllegalArgumentException("가입 방식을 최소 1개 이상 선택해야 합니다.");
        }
        // joinType이 FREE인 경우 다른 타입 비활성화
        if(dto.getJoinType().contains(ClubJoinMethodRole.FREE) && dto.getJoinType().size() > 1) {
            throw  new IllegalArgumentException("자유 가입 선택시 다른 가입 방식을 사용할 수 없습니다.");
        }

        // 학교 동아리인 경우
        if (dto.getClubType() == ClubTypeRole.SCHOOL && (dto.getSchoolName() == null || dto.getSchoolName().isBlank())) {
            throw new IllegalArgumentException("학교 소속 동아리는 학교 이름이 필수입니다.");
        }

        // 가입 형식에 이메일
        if (dto.getJoinType().contains(ClubJoinMethodRole.EMAIL) && (dto.getDomainRestriction() == null || dto.getDomainRestriction().isBlank())) {
            throw new IllegalArgumentException("가입 허용하고자 하는 이메일 형식을 입력해주세요. ex)1234@SeoulUniv.ac.kr에서 @ 뒷부분만");
        }
        // 가입 형식에 비밀번호
        if (dto.getJoinType().contains(ClubJoinMethodRole.CODE) && (dto.getClubPassword() == null || dto.getClubPassword().isBlank())) {
            throw new IllegalArgumentException("동아리 비밀번호를 설정해주세요.");
        }
    }

    @Transactional
    public void deleteClub(Long id) {
        ClubEntity club = clubRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("해당 동아리를 찾을 수 없습니다."));
        // @SoftDelete 어노테이션에 의해 내부적으로 isDelete = true 로 업데이트됨
        clubRepository.delete(club);
    }

    public ClubDto.InfoResponse getClub(Long id) {
        ClubEntity club = clubRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않거나 삭제된 동아리입니다."));

        return ClubDto.InfoResponse.builder()
                .id(club.getId())
                .clubName(club.getClubName())
                .schoolName(club.getSchoolName())
                .domainRestriction(club.getDomainRestriction())
                .useAutoCreateApplicationDoc(club.getUseAutoCreateApplicationDoc())
                .joinType(club.getJoinType())
                .clubType(club.getClubType())
                .build();
    }

    @Transactional
    public void updateClub(Long id, ClubDto.UpdateRequest dto) {
        // 동아리 조회
        ClubEntity club = clubRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("해당 동아리를 찾을 수 없습니다."));

        if (!club.getClubName().equals(dto.getClubName()) && clubRepository.existsByClubName(dto.getClubName())) {
            throw new IllegalStateException("이미 사용 중인 동아리 이름입니다.");
        }

        // 가입 방식 / 타입 필수 값 검증
        validateClubConstraints(dto);

        // 데이터 업데이트
        club.updateClub(dto);
    }
}
