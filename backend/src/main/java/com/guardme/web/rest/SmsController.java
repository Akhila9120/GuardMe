package com.guardme.web.rest;

import com.guardme.repository.UserRepository;
import com.guardme.service.AppUserService;
import com.guardme.service.TwilioService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/sms")
public class SmsController {

    private final TwilioService twilioService;
    private final AppUserService appUserService;
    private final UserRepository userRepository;

    public SmsController(TwilioService twilioService, AppUserService appUserService,
                         UserRepository userRepository) {
        this.twilioService = twilioService;
        this.appUserService = appUserService;
        this.userRepository = userRepository;
    }

    @PostMapping("/sendtoone")
    public ResponseEntity<String> sendToOne(@RequestBody Map<String, Object> body) {
        Long contactId = Long.valueOf(body.get("contactId").toString());
        String message = body.get("message").toString();
        twilioService.sendSmsToOne(contactId, message);
        return ResponseEntity.ok("SMS sent");
    }

    @PostMapping("/sendtoall")
    public ResponseEntity<String> sendToAll(@RequestBody Map<String, String> body) {
        String message = body.get("message");
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        var user = userRepository.findByLogin(auth.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
        var appUser = appUserService.getAppUserByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("AppUser not found"));
        twilioService.sendSmsToAll(appUser.getId(), message);
        return ResponseEntity.ok("SMS sent to all contacts");
    }
}
