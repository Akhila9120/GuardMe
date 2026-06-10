package com.guardme.repository;

import com.guardme.domain.Trip;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TripRepository extends JpaRepository<Trip, Long> {

    List<Trip> findByAppUserId(Long appUserId);
}
