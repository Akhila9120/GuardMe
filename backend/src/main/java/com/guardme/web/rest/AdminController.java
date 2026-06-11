package com.guardme.web.rest;

import com.guardme.domain.EmergencyAlert;
import com.guardme.domain.Trip;
import com.guardme.service.AdminService;
import com.guardme.service.EmergencyAlertService;
import com.guardme.service.TripService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AdminService adminService;
    private final EmergencyAlertService emergencyAlertService;
    private final TripService tripService;

    public AdminController(AdminService adminService,
                           EmergencyAlertService emergencyAlertService,
                           TripService tripService) {
        this.adminService = adminService;
        this.emergencyAlertService = emergencyAlertService;
        this.tripService = tripService;
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Long>> getStats() {
        return ResponseEntity.ok(adminService.getStats());
    }

    @GetMapping("/users")
    public ResponseEntity<List<Map<String, Object>>> getAllUsers() {
        return ResponseEntity.ok(adminService.getAllUsers());
    }

    @PutMapping("/users/{id}/role")
    public ResponseEntity<Map<String, Object>> toggleRole(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.toggleAdminRole(id));
    }

    @GetMapping("/alerts")
    public ResponseEntity<List<EmergencyAlert>> getAllAlerts() {
        return ResponseEntity.ok(emergencyAlertService.getAllAlerts());
    }

    @PutMapping("/alerts/{id}/resolve")
    public ResponseEntity<EmergencyAlert> resolveAlert(@PathVariable Long id) {
        return ResponseEntity.ok(emergencyAlertService.resolveAlert(id));
    }

    @GetMapping("/trips")
    public ResponseEntity<List<Trip>> getAllTrips() {
        return ResponseEntity.ok(tripService.getAllTrips());
    }
}
