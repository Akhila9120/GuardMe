package com.guardme.domain;

import jakarta.persistence.*;
import jakarta.validation.constraints.Size;

@Entity
@Table(name = "jhi_authority")
public class Authority {

    @Id
    @Size(max = 50)
    @Column(length = 50)
    private String name;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
