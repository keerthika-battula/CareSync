-- =============================================
-- CareSync Database Migration
-- V8 - Add snoozed_until and original_scheduled_time to reminder_occurrences
-- =============================================

ALTER TABLE reminder_occurrences ADD COLUMN IF NOT EXISTS original_scheduled_time TIMESTAMP;
ALTER TABLE reminder_occurrences ADD COLUMN IF NOT EXISTS snoozed_until TIMESTAMP;

-- Backfill original_scheduled_time from scheduled_time for existing records
UPDATE reminder_occurrences SET original_scheduled_time = scheduled_time WHERE original_scheduled_time IS NULL;
