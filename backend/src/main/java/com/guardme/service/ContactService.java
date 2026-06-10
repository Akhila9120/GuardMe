package com.guardme.service;

import com.guardme.domain.Contact;
import com.guardme.repository.ContactRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class ContactService {

    private static final Logger log = LoggerFactory.getLogger(ContactService.class);

    private final ContactRepository contactRepository;

    public ContactService(ContactRepository contactRepository) {
        this.contactRepository = contactRepository;
    }

    public Contact createContact(Contact contact) {
        log.debug("Creating contact: {}", contact);
        return contactRepository.save(contact);
    }

    public Contact updateContact(Long id, Contact details) {
        Contact contact = contactRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Contact not found with id: " + id));
        contact.setName(details.getName());
        contact.setPhone(details.getPhone());
        contact.setEmail(details.getEmail());
        contact.setRelationship(details.getRelationship());
        return contactRepository.save(contact);
    }

    public void deleteContact(Long id) {
        contactRepository.deleteById(id);
    }

    @Transactional(readOnly = true)
    public Optional<Contact> getContact(Long id) {
        return contactRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public List<Contact> getAllContacts() {
        return contactRepository.findAll();
    }

    @Transactional(readOnly = true)
    public List<Contact> getContactsByUser(Long appUserId) {
        return contactRepository.findByAppUserId(appUserId);
    }
}
