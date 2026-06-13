package com.guardme.service;

import com.guardme.domain.*;
import com.guardme.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

@Service
@Transactional
public class UserService {

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    private final UserRepository userRepository;
    private final AppUserRepository appUserRepository;
    private final ProfileRepository profileRepository;
    private final AuthorityRepository authorityRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, AppUserRepository appUserRepository,
                       ProfileRepository profileRepository, AuthorityRepository authorityRepository,
                       PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.appUserRepository = appUserRepository;
        this.profileRepository = profileRepository;
        this.authorityRepository = authorityRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public User registerUser(String login, String password, String firstName, String lastName, String email) {
        log.debug("Registering user: {}", login);
        User user = new User();
        user.setLogin(login);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setEmail(email);
        user.setActivated(true);
        user.setLangKey("en");

        Set<Authority> authorities = new HashSet<>();
        Authority userAuth = authorityRepository.findById("ROLE_USER")
                .orElseThrow(() -> new RuntimeException("ROLE_USER not found"));
        authorities.add(userAuth);
        user.setAuthorities(authorities);

        userRepository.save(user);

        AppUser appUser = new AppUser();
        appUser.setUser(user);
        appUserRepository.save(appUser);

        Profile profile = new Profile();
        profile.setAppUser(appUser);
        profileRepository.save(profile);

        return user;
    }

    @Transactional(readOnly = true)
    public Optional<User> getUserByLogin(String login) {
        return userRepository.findOneWithAuthoritiesByLogin(login);
    }

    public User updateProfile(Long userId, String firstName, String lastName, String email) {
        log.debug("Updating profile for user id: {}", userId);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setEmail(email);
        return userRepository.save(user);
    }

    public void changePassword(Long userId, String currentPassword, String newPassword) {
        log.debug("Changing password for user id: {}", userId);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw new IllegalArgumentException("Current password is incorrect");
        }
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }
}
