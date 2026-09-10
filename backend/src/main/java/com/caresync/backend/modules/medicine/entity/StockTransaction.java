package com.caresync.backend.modules.medicine.entity;

import com.caresync.backend.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "stock_transactions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockTransaction extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "medicine_id", nullable = false)
    private Medicine medicine;

    @Column(nullable = false)
    private BigDecimal quantityChange;

    @Column(nullable = false)
    private String transactionType; // TAKEN, REFILL, CORRECTION

    private UUID referenceId;
}
