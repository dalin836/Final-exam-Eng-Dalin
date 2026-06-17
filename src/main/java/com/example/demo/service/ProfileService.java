package com.example.demo.service;

import com.example.demo.model.Profile;
import com.example.demo.repository.ProfileRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ProfileService {

    private final ProfileRepository repository;

    public ProfileService(ProfileRepository repository) {
        this.repository = repository;
    }

    public List<Profile> findAll() {
        return repository.findAll();
    }

    public Optional<Profile> findById(Long id) {
        return repository.findById(id);
    }

    public Profile save(Profile profile) {
        return repository.save(profile);
    }

    public void delete(Long id) {
        repository.deleteById(id);
    }
}