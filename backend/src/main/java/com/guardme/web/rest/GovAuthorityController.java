package com.guardme.web.rest;

import com.guardme.domain.GovAuthority;
import com.guardme.repository.GovAuthorityRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/gov-authorities")
public class GovAuthorityController {

    private final GovAuthorityRepository govAuthorityRepository;

    public GovAuthorityController(GovAuthorityRepository govAuthorityRepository) {
        this.govAuthorityRepository = govAuthorityRepository;
    }

    @GetMapping
    public ResponseEntity<List<GovAuthority>> getAll() {
        return ResponseEntity.ok(govAuthorityRepository.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<GovAuthority> getById(@PathVariable Long id) {
        return govAuthorityRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<GovAuthority> create(@RequestBody GovAuthority govAuthority) {
        return ResponseEntity.status(HttpStatus.CREATED).body(govAuthorityRepository.save(govAuthority));
    }

    @PutMapping("/{id}")
    public ResponseEntity<GovAuthority> update(@PathVariable Long id, @RequestBody GovAuthority details) {
        return govAuthorityRepository.findById(id).map(existing -> {
            existing.setName(details.getName());
            existing.setDepartment(details.getDepartment());
            existing.setPhone(details.getPhone());
            existing.setEmail(details.getEmail());
            existing.setJurisdiction(details.getJurisdiction());
            existing.setRegion(details.getRegion());
            return ResponseEntity.ok(govAuthorityRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        govAuthorityRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
