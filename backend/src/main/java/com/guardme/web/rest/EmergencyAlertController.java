package com.guardme.web.rest;

import com.guardme.domain.AppUser;
import com.guardme.domain.EmergencyAlert;
import com.guardme.repository.UserRepository;
import com.guardme.service.AppUserService;
import com.guardme.service.EmergencyAlertService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/emergency-alerts")
public class EmergencyAlertController {

    private final EmergencyAlertService emergencyAlertService;
    private final AppUserService appUserService;
    private final UserRepository userRepository;

    public EmergencyAlertController(EmergencyAlertService emergencyAlertService,
                                     AppUserService appUserService,
                                     UserRepository userRepository) {
        this.emergencyAlertService = emergencyAlertService;
        this.appUserService = appUserService;
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<List<EmergencyAlert>> getAlertsForCurrentUser() {
        AppUser appUser = getCurrentAppUser();
        return ResponseEntity.ok(emergencyAlertService.getAllByUser(appUser.getId()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<EmergencyAlert> getAlert(@PathVariable Long id) {
        return emergencyAlertService.getAlert(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<EmergencyAlert> createAlert(@RequestBody EmergencyAlert alert) {
        AppUser appUser = getCurrentAppUser();
        alert.setAppUser(appUser);
        return ResponseEntity.status(HttpStatus.CREATED).body(emergencyAlertService.createAlert(alert));
    }

    @PutMapping("/{id}/resolve")
    public ResponseEntity<EmergencyAlert> resolveAlert(@PathVariable Long id) {
        return ResponseEntity.ok(emergencyAlertService.resolveAlert(id));
    }

    private AppUser getCurrentAppUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String login = auth.getName();
        var user = userRepository.findByLogin(login)
                .orElseThrow(() -> new RuntimeException("User not found: " + login));
        return appUserService.getAppUserByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("AppUser not found for user: " + login));
    }
}
