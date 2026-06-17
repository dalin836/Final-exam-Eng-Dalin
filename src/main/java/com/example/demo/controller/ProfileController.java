package com.example.demo.controller;

import com.example.demo.model.Profile;
import com.example.demo.model.ProfleType;
import com.example.demo.service.ProfileService;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/profiles")
public class ProfileController {

    private final ProfileService service;
    private final Path photoDir = Paths.get("uploads/photos");

    public ProfileController(ProfileService service) {
        this.service = service;
        try {
            Files.createDirectories(photoDir);
        } catch (IOException e) {
            throw new RuntimeException("Could not create upload directory", e);
        }
    }

    @GetMapping
    public List<Profile> getAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public Profile getById(@PathVariable Long id) {
        return service.findById(id).orElse(null);
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public Profile createFromJson(@RequestBody Profile profile) {
        if (profile.getUuid() == null || profile.getUuid().isBlank()) {
            profile.setUuid(UUID.randomUUID().toString());
        }
        if (profile.getRegistrationNumber() == null || profile.getRegistrationNumber().isBlank()) {
            String type = profile.getType() != null ? profile.getType().name() : "USER";
            profile.setRegistrationNumber(generateRegistrationNumber(type));
        }
        if (profile.getIssueDate() == null) {
            profile.setIssueDate(LocalDate.now());
        }
        return service.save(profile);
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Profile createWithPhoto(
            @RequestParam("fullName") String fullName,
            @RequestParam("type") String type,
            @RequestParam(value = "department", required = false) String department,
            @RequestParam(value = "title", required = false) String title,
            @RequestParam(value = "email", required = false) String email,
            @RequestParam(value = "phone", required = false) String phone,
            @RequestParam(value = "bloodGroup", required = false) String bloodGroup,
            @RequestParam(value = "dateOfBirth", required = false) String dateOfBirth,
            @RequestParam(value = "photo", required = false) MultipartFile photo) throws IOException {

        Profile profile = new Profile();
        profile.setUuid(UUID.randomUUID().toString());
        profile.setFullName(fullName);
        profile.setType(ProfleType.valueOf(type));
        profile.setDepartment(department);
        profile.setTitle(title);
        profile.setEmail(email);
        profile.setPhone(phone);
        profile.setBloodGroup(bloodGroup);
        if (dateOfBirth != null && !dateOfBirth.isBlank()) {
            profile.setDateOfBirth(LocalDate.parse(dateOfBirth));
        }
        profile.setIssueDate(LocalDate.now());

        // Generate registration number
        String regNumber = generateRegistrationNumber(type);
        profile.setRegistrationNumber(regNumber);

        // Handle photo upload
        if (photo != null && !photo.isEmpty()) {
            String fileName = UUID.randomUUID() + "_" + photo.getOriginalFilename();
            Path targetPath = photoDir.resolve(fileName);
            Files.copy(photo.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);
            profile.setPhotoFileName(fileName);
            profile.setPhotoContentType(photo.getContentType());
        }

        return service.save(profile);
    }

    @PutMapping(value = "/{id}")
    public Profile updateProfile(
            @PathVariable Long id,
            @RequestParam(value = "fullName", required = false) String fullName,
            @RequestParam(value = "type", required = false) String type,
            @RequestParam(value = "department", required = false) String department,
            @RequestParam(value = "title", required = false) String title,
            @RequestParam(value = "email", required = false) String email,
            @RequestParam(value = "phone", required = false) String phone,
            @RequestParam(value = "bloodGroup", required = false) String bloodGroup,
            @RequestParam(value = "dateOfBirth", required = false) String dateOfBirth,
            @RequestParam(value = "photo", required = false) MultipartFile photo,
            @RequestHeader("Content-Type") String contentType) throws IOException {

        Profile existing = service.findById(id).orElse(null);
        if (existing == null)
            return null;

        // Handle JSON body
        if (contentType != null && contentType.contains("application/json")) {
            // JSON data was sent as multipart or raw JSON
            return existing;
        }

        // Handle multipart form data
        if (fullName != null)
            existing.setFullName(fullName);
        if (type != null)
            existing.setType(ProfleType.valueOf(type));
        if (department != null)
            existing.setDepartment(department);
        if (title != null)
            existing.setTitle(title);
        if (email != null)
            existing.setEmail(email);
        if (phone != null)
            existing.setPhone(phone);
        if (bloodGroup != null)
            existing.setBloodGroup(bloodGroup);
        if (dateOfBirth != null && !dateOfBirth.isBlank()) {
            existing.setDateOfBirth(LocalDate.parse(dateOfBirth));
        }

        if (photo != null && !photo.isEmpty()) {
            // Delete old photo if exists
            if (existing.getPhotoFileName() != null) {
                Path oldFile = photoDir.resolve(existing.getPhotoFileName());
                try {
                    Files.deleteIfExists(oldFile);
                } catch (IOException ignored) {
                }
            }
            String fileName = UUID.randomUUID() + "_" + photo.getOriginalFilename();
            Path targetPath = photoDir.resolve(fileName);
            Files.copy(photo.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);
            existing.setPhotoFileName(fileName);
            existing.setPhotoContentType(photo.getContentType());
        }

        return service.save(existing);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        Profile existing = service.findById(id).orElse(null);
        if (existing != null && existing.getPhotoFileName() != null) {
            Path oldFile = photoDir.resolve(existing.getPhotoFileName());
            try {
                Files.deleteIfExists(oldFile);
            } catch (IOException ignored) {
            }
        }
        service.delete(id);
    }

    @GetMapping("/photos/{fileName}")
    public ResponseEntity<byte[]> getPhoto(@PathVariable String fileName) {
        try {
            Path filePath = photoDir.resolve(fileName);
            if (!Files.exists(filePath)) {
                return ResponseEntity.notFound().build();
            }
            byte[] bytes = Files.readAllBytes(filePath);
            String contentType = Files.probeContentType(filePath);
            if (contentType == null)
                contentType = "image/png";
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .body(bytes);
        } catch (IOException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/{id}/pdf")
    public ResponseEntity<String> downloadPdf(@PathVariable Long id) {
        Profile profile = service.findById(id).orElse(null);
        if (profile == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok("PDF generation not yet implemented");
    }

    private String generateRegistrationNumber(String type) {
        int year = LocalDate.now().getYear();
        String dept = type.equals("STUDENT") ? "STU" : "EMP";
        long count = service.findAll().stream()
                .filter(p -> p.getRegistrationNumber() != null &&
                        p.getRegistrationNumber().startsWith(year + "-" + dept))
                .count() + 1;
        return String.format("%d-%s-%03d", year, dept, count);
    }
}