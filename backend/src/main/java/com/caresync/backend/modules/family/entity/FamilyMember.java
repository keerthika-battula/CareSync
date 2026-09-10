package com.caresync.backend.modules.family.entity;

import com.caresync.backend.common.entity.BaseEntity;
import com.caresync.backend.modules.auth.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity
@Table(name = "family_members")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FamilyMember extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String name;

    private String relationship;

    private LocalDate dateOfBirth;

    private String bloodGroup;

    private String notes;

    @Column(nullable = false)
    @Builder.Default
    private boolean isSelf = false;
}
