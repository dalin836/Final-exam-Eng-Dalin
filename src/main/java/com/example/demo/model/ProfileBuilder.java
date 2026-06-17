package com.example.demo.model;

public class ProfileBuilder {

    private final Profile profile;

    public ProfileBuilder() {
        profile = new Profile();
        profile.setProfileType(ProfleType.USER);
    }

    public ProfileBuilder firstName(String firstName) {
        profile.setFullName(firstName);
        return this;
    }

    public ProfileBuilder lastName(String lastName) {
        profile.setLastName(lastName);
        return this;
    }

    public ProfileBuilder email(String email) {
        profile.setEmail(email);
        return this;
    }

    public ProfileBuilder department(String department) {
        profile.setDepartment(department);
        return this;
    }

    public ProfileBuilder phone(String phone) {
        profile.setPhone(phone);
        return this;
    }

    public ProfileBuilder type(ProfleType type) {
        profile.setProfileType(type);
        return this;
    }

    public Profile build() {
        return profile;
    }
}