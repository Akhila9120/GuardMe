package com.guardme.service;

import com.guardme.domain.Trip;
import com.guardme.repository.TripRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class TripService {

    private static final Logger log = LoggerFactory.getLogger(TripService.class);

    private final TripRepository tripRepository;
    private final EmergencyAlertService emergencyAlertService;

    public TripService(TripRepository tripRepository, EmergencyAlertService emergencyAlertService) {
        this.tripRepository = tripRepository;
        this.emergencyAlertService = emergencyAlertService;
    }

    public Trip createTrip(Trip trip) {
        log.debug("Creating trip: {}", trip);
        if (trip.getStatus() == null) {
            trip.setStatus("ACTIVE");
        }
        if (trip.getStartTime() == null) {
            trip.setStartTime(LocalDateTime.now());
        }
        return tripRepository.save(trip);
    }

    public Trip updateTrip(Long id, Trip details) {
        Trip trip = tripRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Trip not found with id: " + id));
        trip.setEndTime(details.getEndTime());
        trip.setStartLatitude(details.getStartLatitude());
        trip.setStartLongitude(details.getStartLongitude());
        trip.setEndLatitude(details.getEndLatitude());
        trip.setEndLongitude(details.getEndLongitude());
        trip.setStatus(details.getStatus());
        return tripRepository.save(trip);
    }

    public void deleteTrip(Long id) {
        tripRepository.deleteById(id);
    }

    @Transactional(readOnly = true)
    public Optional<Trip> getTrip(Long id) {
        return tripRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public List<Trip> getAllTrips() {
        return tripRepository.findAll();
    }

    @Transactional(readOnly = true)
    public List<Trip> getTripsByUser(Long appUserId) {
        return tripRepository.findByAppUserId(appUserId);
    }

    public Trip endTrip(Long id) {
        Trip trip = tripRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Trip not found with id: " + id));
        trip.setStatus("COMPLETED");
        trip.setEndTime(LocalDateTime.now());
        return tripRepository.save(trip);
    }

    public Trip triggerEmergency(Long id) {
        Trip trip = tripRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Trip not found with id: " + id));
        trip.setStatus("EMERGENCY");
        tripRepository.save(trip);

        emergencyAlertService.createAlertForTrip(trip);
        return trip;
    }
}
