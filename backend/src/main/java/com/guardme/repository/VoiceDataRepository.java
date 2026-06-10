package com.guardme.repository;

import com.guardme.domain.VoiceData;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface VoiceDataRepository extends JpaRepository<VoiceData, Long> {

    List<VoiceData> findByTripId(Long tripId);
}
