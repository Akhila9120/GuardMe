package com.guardme.repository;

import com.guardme.domain.Contact;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ContactRepository extends JpaRepository<Contact, Long> {

    List<Contact> findByAppUserId(Long appUserId);
}
