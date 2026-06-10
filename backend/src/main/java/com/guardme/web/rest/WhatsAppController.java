package com.guardme.web.rest;

import com.guardme.repository.UserRepository;
import com.guardme.service.AppUserService;
import com.guardme.service.WhatsAppService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/whatsapp")
public class WhatsAppController {

    private final WhatsAppService whatsAppService;
    private final AppUserService appUserService;
    private final UserRepository userRepository;

    public WhatsAppController(WhatsAppService whatsAppService, AppUserService appUserService,
                              UserRepository userRepository) {
        this.whatsAppService = whatsAppService;
        this.appUserService = appUserService;
        this.userRepository = userRepository;
    }

    @PostMapping("/sendtoone")
    public ResponseEntity<String> sendToOne(@RequestBody Map<String, Object> body) {
        Long contactId = Long.valueOf(body.get("contactId").toString());
        String message = body.get("message").toString();
        whatsAppService.sendToOne(contactId, message);
        return ResponseEntity.ok("WhatsApp sent");
    }

    @PostMapping("/sendtoall")
    public ResponseEntity<String> sendToAll(@RequestBody Map<String, String> body) {
        String message = body.get("message");
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        var user = userRepository.findByLogin(auth.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
        var appUser = appUserService.getAppUserByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("AppUser not found"));
        whatsAppService.sendToAll(appUser.getId(), message);
        return ResponseEntity.ok("WhatsApp sent to all contacts");
    }
}
