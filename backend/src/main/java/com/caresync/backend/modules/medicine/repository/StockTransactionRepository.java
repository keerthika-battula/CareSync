package com.caresync.backend.modules.medicine.repository;

import com.caresync.backend.modules.medicine.entity.StockTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface StockTransactionRepository extends JpaRepository<StockTransaction, UUID> {
}
