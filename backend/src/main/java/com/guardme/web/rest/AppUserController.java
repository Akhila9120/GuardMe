package com.guardme.web.rest;

import com.guardme.domain.AppUser;
import com.guardme.service.AppUserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/app-users")
public class AppUserController {

    private final AppUserService appUserService;

    public AppUserController(AppUserService appUserService) {
        this.appUserService = appUserService;
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<AppUser>> getAllAppUsers() {
        return ResponseEntity.ok(appUserService.getAllAppUsers());
    }

    @GetMapping("/{id}")
    public ResponseEntity<AppUser> getAppUser(@PathVariable Long id) {
        return appUserService.getAppUserById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<AppUser> createAppUser(@RequestBody AppUser appUser) {
        return ResponseEntity.status(HttpStatus.CREATED).body(appUserService.createAppUser(appUser));
    }

    @PutMapping("/{id}")
    public ResponseEntity<AppUser> updateAppUser(@PathVariable Long id, @RequestBody AppUser appUser) {
        return ResponseEntity.ok(appUserService.updateAppUser(id, appUser));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAppUser(@PathVariable Long id) {
        appUserService.deleteAppUser(id);
        return ResponseEntity.noContent().build();
    }
}
