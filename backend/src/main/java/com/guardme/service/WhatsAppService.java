package com.guardme.service;

import com.guardme.domain.Contact;
import com.guardme.repository.ContactRepository;
import com.twilio.Twilio;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class WhatsAppService {

    private static final Logger log = LoggerFactory.getLogger(WhatsAppService.class);

    private final String accountSid;
    private final String authToken;
    private final String fromNumber;
    private final ContactRepository contactRepository;
    private boolean initialized = false;

    public WhatsAppService(@Value("${twilio.account-sid:}") String accountSid,
                           @Value("${twilio.auth-token:}") String authToken,
                           @Value("${twilio.from-number:}") String fromNumber,
                           ContactRepository contactRepository) {
        this.accountSid = accountSid;
        this.authToken = authToken;
        this.fromNumber = fromNumber;
        this.contactRepository = contactRepository;
    }

    @PostConstruct
    public void init() {
        if (!accountSid.isEmpty() && !authToken.isEmpty()) {
            Twilio.init(accountSid, authToken);
            initialized = true;
            log.info("WhatsApp (Twilio) initialized successfully");
        } else {
            log.warn("Twilio not configured - WhatsApp functionality will be disabled");
        }
    }

    public void sendWhatsApp(String to, String message) {
        if (!initialized) {
            log.warn("Twilio not initialized, cannot send WhatsApp to {}", to);
            return;
        }
        try {
            Message.creator(
                    new PhoneNumber("whatsapp:" + to),
                    new PhoneNumber("whatsapp:" + fromNumber),
                    message
            ).create();
            log.info("WhatsApp sent to {}", to);
        } catch (Exception e) {
            log.error("Failed to send WhatsApp to {}: {}", to, e.getMessage());
            throw e;
        }
    }

    public void sendToOne(Long contactId, String message) {
        Contact contact = contactRepository.findById(contactId)
                .orElseThrow(() -> new RuntimeException("Contact not found with id: " + contactId));
        if (contact.getPhone() != null) {
            sendWhatsApp(contact.getPhone(), message);
        } else {
            log.warn("Contact {} has no phone number", contactId);
        }
    }

    public void sendToAll(Long appUserId, String message) {
        List<Contact> contacts = contactRepository.findByAppUserId(appUserId);
        for (Contact contact : contacts) {
            if (contact.getPhone() != null) {
                try {
                    sendWhatsApp(contact.getPhone(), message);
                } catch (Exception e) {
                    log.error("Failed to send WhatsApp to contact {}: {}", contact.getId(), e.getMessage());
                }
            }
        }
    }
}
