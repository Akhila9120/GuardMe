package com.guardme.web.rest;

import com.guardme.domain.AppUser;
import com.guardme.domain.Trip;
import com.guardme.repository.UserRepository;
import com.guardme.service.AppUserService;
import com.guardme.service.TripService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/trips")
public class TripController {

    private final TripService tripService;
    private final AppUserService appUserService;
    private final UserRepository userRepository;

    public TripController(TripService tripService, AppUserService appUserService,
                          UserRepository userRepository) {
        this.tripService = tripService;
        this.appUserService = appUserService;
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<List<Trip>> getTripsForCurrentUser() {
        AppUser appUser = getCurrentAppUser();
        return ResponseEntity.ok(tripService.getTripsByUser(appUser.getId()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Trip> getTrip(@PathVariable Long id) {
        return tripService.getTrip(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Trip> createTrip(@RequestBody Trip trip) {
        AppUser appUser = getCurrentAppUser();
        trip.setAppUser(appUser);
        return ResponseEntity.status(HttpStatus.CREATED).body(tripService.createTrip(trip));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Trip> updateTrip(@PathVariable Long id, @RequestBody Trip trip) {
        return ResponseEntity.ok(tripService.updateTrip(id, trip));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTrip(@PathVariable Long id) {
        tripService.deleteTrip(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/end")
    public ResponseEntity<Trip> endTrip(@PathVariable Long id) {
        return ResponseEntity.ok(tripService.endTrip(id));
    }

    @PutMapping("/{id}/emergency")
    public ResponseEntity<Trip> triggerEmergency(@PathVariable Long id) {
        return ResponseEntity.ok(tripService.triggerEmergency(id));
    }

    private AppUser getCurrentAppUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String login = auth.getName();
        var user = userRepository.findByLogin(login)
                .orElseThrow(() -> new RuntimeException("User not found: " + login));
        return appUserService.getAppUserByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("AppUser not found for user: " + login));
    }
}
