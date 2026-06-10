package com.guardme.repository;

import com.guardme.domain.GovAuthority;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GovAuthorityRepository extends JpaRepository<GovAuthority, Long> {
}
