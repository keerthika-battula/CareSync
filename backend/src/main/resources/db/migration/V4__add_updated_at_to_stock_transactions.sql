-- =============================================
-- V4 - Fix missing updated_at on stock_transactions
-- =============================================
ALTER TABLE stock_transactions ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT NOW();
