package com.guardme.web.rest;

import com.guardme.domain.VoiceData;
import com.guardme.repository.VoiceDataRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/voice-data")
public class VoiceDataController {

    private final VoiceDataRepository voiceDataRepository;

    public VoiceDataController(VoiceDataRepository voiceDataRepository) {
        this.voiceDataRepository = voiceDataRepository;
    }

    @GetMapping
    public ResponseEntity<List<VoiceData>> getByTrip(@RequestParam Long tripId) {
        return ResponseEntity.ok(voiceDataRepository.findByTripId(tripId));
    }

    @PostMapping
    public ResponseEntity<VoiceData> create(@RequestBody VoiceData voiceData) {
        return ResponseEntity.status(HttpStatus.CREATED).body(voiceDataRepository.save(voiceData));
    }
}
