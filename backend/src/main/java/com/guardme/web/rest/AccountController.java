package com.guardme.web.rest;

import com.guardme.domain.User;
import com.guardme.service.UserService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class AccountController {

    private static final Logger log = LoggerFactory.getLogger(AccountController.class);

    private final UserService userService;

    public AccountController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/account")
    public ResponseEntity<User> getAccount() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String login = authentication.getName();
        log.debug("REST request to get account for user: {}", login);
        return userService.getUserByLogin(login)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/account")
    public ResponseEntity<User> updateAccount(@Valid @RequestBody UpdateProfileRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String login = authentication.getName();
        log.debug("REST request to update account for user: {}", login);
        return userService.getUserByLogin(login)
                .map(user -> {
                    User updated = userService.updateProfile(
                            user.getId(),
                            request.firstName(),
                            request.lastName(),
                            request.email()
                    );
                    return ResponseEntity.ok(updated);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/account/change-password")
    public ResponseEntity<Void> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String login = authentication.getName();
        log.debug("REST request to change password for user: {}", login);
        return userService.getUserByLogin(login)
                .map(user -> {
                    try {
                        userService.changePassword(user.getId(), request.currentPassword(), request.newPassword());
                        return ResponseEntity.ok().<Void>build();
                    } catch (IllegalArgumentException e) {
                        return ResponseEntity.badRequest().<Void>build();
                    }
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/register")
    public ResponseEntity<User> registerAccount(@Valid @RequestBody RegisterRequest registerRequest) {
        log.debug("REST request to register user: {}", registerRequest.login());
        if (userService.getUserByLogin(registerRequest.login()).isPresent()) {
            return ResponseEntity.badRequest().build();
        }
        User user = userService.registerUser(
                registerRequest.login(),
                registerRequest.password(),
                registerRequest.firstName(),
                registerRequest.lastName(),
                registerRequest.email()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(user);
    }

    public record UpdateProfileRequest(
            @Size(max = 50) String firstName,
            @Size(max = 50) String lastName,
            @Email @Size(max = 254) String email) {}

    public record ChangePasswordRequest(
            @NotBlank String currentPassword,
            @NotBlank @Size(min = 4, max = 60) String newPassword) {}

    public record RegisterRequest(
            @NotBlank @Size(min = 1, max = 50) String login,
            @NotBlank @Size(min = 4, max = 60) String password,
            @Size(max = 50) String firstName,
            @Size(max = 50) String lastName,
            @Email @Size(max = 254) String email) {}
}
