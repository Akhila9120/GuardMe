package com.guardme.repository;

import com.guardme.domain.EmergencyAlert;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EmergencyAlertRepository extends JpaRepository<EmergencyAlert, Long> {

    List<EmergencyAlert> findByAppUserId(Long appUserId);
}
