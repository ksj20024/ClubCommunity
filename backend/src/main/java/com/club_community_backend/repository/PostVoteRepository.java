package com.club_community_backend.repository;

import com.club_community_backend.entity.PostEntity;
import com.club_community_backend.entity.PostVoteEntity;
import com.club_community_backend.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PostVoteRepository extends JpaRepository<PostVoteEntity, Long> {
    Optional<PostVoteEntity> findByPostAndUser(PostEntity post, UserEntity user);
}