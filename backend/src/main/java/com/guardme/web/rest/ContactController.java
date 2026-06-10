package com.guardme.web.rest;

import com.guardme.domain.AppUser;
import com.guardme.domain.Contact;
import com.guardme.repository.UserRepository;
import com.guardme.service.AppUserService;
import com.guardme.service.ContactService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/contacts")
public class ContactController {

    private final ContactService contactService;
    private final AppUserService appUserService;
    private final UserRepository userRepository;

    public ContactController(ContactService contactService, AppUserService appUserService,
                             UserRepository userRepository) {
        this.contactService = contactService;
        this.appUserService = appUserService;
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<List<Contact>> getContactsForCurrentUser() {
        AppUser appUser = getCurrentAppUser();
        return ResponseEntity.ok(contactService.getContactsByUser(appUser.getId()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Contact> getContact(@PathVariable Long id) {
        return contactService.getContact(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Contact> createContact(@RequestBody Contact contact) {
        AppUser appUser = getCurrentAppUser();
        contact.setAppUser(appUser);
        return ResponseEntity.status(HttpStatus.CREATED).body(contactService.createContact(contact));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Contact> updateContact(@PathVariable Long id, @RequestBody Contact contact) {
        return ResponseEntity.ok(contactService.updateContact(id, contact));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteContact(@PathVariable Long id) {
        contactService.deleteContact(id);
        return ResponseEntity.noContent().build();
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
