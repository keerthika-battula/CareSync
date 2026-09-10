
-- =============================================
-- V3 - Phase 3 Reminders & Stock Transactions
-- =============================================

-- 1. Reminder Occurrences
CREATE TABLE reminder_occurrences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
    schedule_id UUID REFERENCES medicine_schedules(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scheduled_time TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'TAKEN', 'SKIPPED', 'SNOOZED')),
    action_time TIMESTAMP,
    snooze_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (medicine_id, scheduled_time)
);

CREATE INDEX idx_reminder_occurrences_user ON reminder_occurrences(user_id);
CREATE INDEX idx_reminder_occurrences_status ON reminder_occurrences(status);

-- 2. Stock Transactions
CREATE TABLE stock_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
    quantity_change DECIMAL(10,2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('TAKEN', 'REFILL', 'CORRECTION')),
    reference_id UUID, -- Can point to reminder_occurrence_id
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 3. Refill Alerts
CREATE TABLE refill_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'DISMISSED', 'RESOLVED')),
    estimated_depletion_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 4. Alter FCM Tokens (Already exists in V1, but we need to ensure device_name is accommodated if needed)
-- V1 has device_type, token. We will use those.
