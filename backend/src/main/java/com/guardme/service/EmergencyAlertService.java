package com.guardme.service;

import com.guardme.domain.EmergencyAlert;
import com.guardme.domain.Trip;
import com.guardme.repository.EmergencyAlertRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class EmergencyAlertService {

    private static final Logger log = LoggerFactory.getLogger(EmergencyAlertService.class);

    private final EmergencyAlertRepository emergencyAlertRepository;
    private final TwilioService twilioService;
    private final WhatsAppService whatsAppService;
    private final NotificationService notificationService;

    public EmergencyAlertService(EmergencyAlertRepository emergencyAlertRepository,
                                  TwilioService twilioService,
                                  WhatsAppService whatsAppService,
                                  NotificationService notificationService) {
        this.emergencyAlertRepository = emergencyAlertRepository;
        this.twilioService = twilioService;
        this.whatsAppService = whatsAppService;
        this.notificationService = notificationService;
    }

    public EmergencyAlert createAlert(EmergencyAlert alert) {
        log.debug("Creating emergency alert: {}", alert);
        if (alert.getAlertTime() == null) {
            alert.setAlertTime(LocalDateTime.now());
        }
        if (alert.getStatus() == null) {
            alert.setStatus("SENT");
        }
        EmergencyAlert saved = emergencyAlertRepository.save(alert);

        try {
            twilioService.sendSmsToAll(alert.getAppUser().getId(), "EMERGENCY: " + alert.getMessage());
        } catch (Exception e) {
            log.warn("Failed to send SMS: {}", e.getMessage());
        }
        try {
            whatsAppService.sendToAll(alert.getAppUser().getId(), "EMERGENCY: " + alert.getMessage());
        } catch (Exception e) {
            log.warn("Failed to send WhatsApp: {}", e.getMessage());
        }
        try {
            notificationService.sendEmergencyAlert(saved);
        } catch (Exception e) {
            log.warn("Failed to send WebSocket notification: {}", e.getMessage());
        }

        return saved;
    }

    public void createAlertForTrip(Trip trip) {
        EmergencyAlert alert = new EmergencyAlert();
        alert.setAlertTime(LocalDateTime.now());
        alert.setStatus("SENT");
        alert.setMessage("Emergency triggered for trip #" + trip.getId());
        alert.setLatitude(trip.getStartLatitude());
        alert.setLongitude(trip.getStartLongitude());
        alert.setAppUser(trip.getAppUser());
        alert.setTrip(trip);
        createAlert(alert);
    }

    public EmergencyAlert resolveAlert(Long id) {
        EmergencyAlert alert = emergencyAlertRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("EmergencyAlert not found with id: " + id));
        alert.setStatus("RESOLVED");
        return emergencyAlertRepository.save(alert);
    }

    @Transactional(readOnly = true)
    public List<EmergencyAlert> getAllAlerts() {
        return emergencyAlertRepository.findAll();
    }

    @Transactional(readOnly = true)
    public List<EmergencyAlert> getAllByUser(Long appUserId) {
        return emergencyAlertRepository.findByAppUserId(appUserId);
    }

    @Transactional(readOnly = true)
    public Optional<EmergencyAlert> getAlert(Long id) {
        return emergencyAlertRepository.findById(id);
    }
}
