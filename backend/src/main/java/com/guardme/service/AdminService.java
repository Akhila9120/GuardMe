package com.guardme.service;

import com.guardme.domain.Authority;
import com.guardme.domain.User;
import com.guardme.repository.AppUserRepository;
import com.guardme.repository.AuthorityRepository;
import com.guardme.repository.EmergencyAlertRepository;
import com.guardme.repository.TripRepository;
import com.guardme.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@Transactional
public class AdminService {

    private static final Logger log = LoggerFactory.getLogger(AdminService.class);

    private final UserRepository userRepository;
    private final AppUserRepository appUserRepository;
    private final TripRepository tripRepository;
    private final EmergencyAlertRepository emergencyAlertRepository;
    private final AuthorityRepository authorityRepository;

    public AdminService(UserRepository userRepository,
                        AppUserRepository appUserRepository,
                        TripRepository tripRepository,
                        EmergencyAlertRepository emergencyAlertRepository,
                        AuthorityRepository authorityRepository) {
        this.userRepository = userRepository;
        this.appUserRepository = appUserRepository;
        this.tripRepository = tripRepository;
        this.emergencyAlertRepository = emergencyAlertRepository;
        this.authorityRepository = authorityRepository;
    }

    @Transactional(readOnly = true)
    public Map<String, Long> getStats() {
        Map<String, Long> stats = new LinkedHashMap<>();
        stats.put("users", userRepository.count());
        stats.put("trips", tripRepository.count());
        stats.put("alerts", emergencyAlertRepository.count());
        stats.put("activeTrips", tripRepository.findAll().stream()
                .filter(t -> "ACTIVE".equals(t.getStatus()) || "EMERGENCY".equals(t.getStatus()))
                .count());
        stats.put("pendingAlerts", emergencyAlertRepository.findAll().stream()
                .filter(a -> !"RESOLVED".equals(a.getStatus()))
                .count());
        return stats;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getAllUsers() {
        List<User> users = userRepository.findAll();
        List<Map<String, Object>> result = new ArrayList<>();
        for (User user : users) {
            Map<String, Object> userMap = new LinkedHashMap<>();
            userMap.put("id", user.getId());
            userMap.put("login", user.getLogin());
            userMap.put("firstName", user.getFirstName());
            userMap.put("lastName", user.getLastName());
            userMap.put("email", user.getEmail());
            userMap.put("activated", user.isActivated());
            userMap.put("authorities", user.getAuthorities().stream()
                    .map(Authority::getName)
                    .toList());

            appUserRepository.findByUserId(user.getId()).ifPresent(appUser -> {
                userMap.put("phone", appUser.getPhone());
                userMap.put("address", appUser.getAddress());
                userMap.put("emergencyContact", appUser.getEmergencyContact());
                userMap.put("createdAt", appUser.getCreatedAt() != null
                        ? appUser.getCreatedAt().toString() : null);
            });

            result.add(userMap);
        }
        return result;
    }

    public Map<String, Object> toggleAdminRole(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        Authority adminRole = authorityRepository.findById("ROLE_ADMIN")
                .orElseGet(() -> {
                    Authority a = new Authority();
                    a.setName("ROLE_ADMIN");
                    return authorityRepository.save(a);
                });

        boolean hadAdmin = user.getAuthorities().removeIf(a -> "ROLE_ADMIN".equals(a.getName()));

        if (!hadAdmin) {
            user.getAuthorities().add(adminRole);
        }
        userRepository.save(user);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", user.getId());
        result.put("login", user.getLogin());
        result.put("isAdmin", !hadAdmin); // new state after toggle
        return result;
    }
}
