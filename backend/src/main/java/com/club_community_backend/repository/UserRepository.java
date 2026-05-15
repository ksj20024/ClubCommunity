package com.club_community_backend.repository;

import com.club_community_backend.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<UserEntity, Long> {
/*
* 인터페이스만 있지만, Spring Data JPA가 실행시점에 구현체를 알아서 주입시켜줌
* save() 데이터 저장 및 수정 / findById() ID값으로 데이터 조회 / findAll() 테이블 모든 데이터 조회
* deleteById() 특정 ID 데이터 삭제 / count() 총 데이터 개수 반환
* 쿼리 메서드? -> JPA가 메서드 규칙만을 보고 자동으로 SQL 쿼리 생성
* findBy.... (SELECT문) / userId (WHERE문) / And (AND)등등*/

    // userId로 유저 찾기
    Optional<UserEntity> findByUserId(String userId);
    // email로 유저 찾기
    Optional<UserEntity> findByEmail(String email);
    // 이메일 중복 확인
    boolean existsByUserId(String userId);
    boolean existsByEmail(String email);
}
