package com.example.demo.repository;

import com.example.demo.model.Profile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ProfileRepository extends JpaRepository<Profile, Long> {

    Optional<Profile> findByRegistrationNumber(String registrationNumber);

    Optional<Profile> findByEmail(String email);

    boolean existsByEmail(String email);

    boolean existsByRegistrationNumber(String registrationNumber);
}