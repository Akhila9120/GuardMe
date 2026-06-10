package com.guardme.service;

import com.guardme.domain.AppUser;
import com.guardme.repository.AppUserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class AppUserService {

    private static final Logger log = LoggerFactory.getLogger(AppUserService.class);

    private final AppUserRepository appUserRepository;

    public AppUserService(AppUserRepository appUserRepository) {
        this.appUserRepository = appUserRepository;
    }

    @Transactional(readOnly = true)
    public List<AppUser> getAllAppUsers() {
        return appUserRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Optional<AppUser> getAppUserById(Long id) {
        return appUserRepository.findById(id);
    }

    public AppUser createAppUser(AppUser appUser) {
        log.debug("Creating AppUser: {}", appUser);
        return appUserRepository.save(appUser);
    }

    public AppUser updateAppUser(Long id, AppUser details) {
        AppUser appUser = appUserRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("AppUser not found with id: " + id));
        appUser.setPhone(details.getPhone());
        appUser.setAddress(details.getAddress());
        appUser.setEmergencyContact(details.getEmergencyContact());
        return appUserRepository.save(appUser);
    }

    public void deleteAppUser(Long id) {
        appUserRepository.deleteById(id);
    }

    @Transactional(readOnly = true)
    public Optional<AppUser> getAppUserByUserId(Long userId) {
        return appUserRepository.findByUserId(userId);
    }
}
