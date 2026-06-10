package com.guardme.service;

import com.guardme.domain.EmergencyAlert;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final SimpMessagingTemplate messagingTemplate;

    public NotificationService(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    public void sendEmergencyAlert(EmergencyAlert alert) {
        log.debug("Sending WebSocket notification for alert: {}", alert.getId());
        messagingTemplate.convertAndSend("/topic/notifications", alert);
    }
}
