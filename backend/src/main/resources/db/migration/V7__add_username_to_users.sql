-- =============================================
-- CareSync Database Migration
-- V7 - Add username column and bootstrap initial admins
-- =============================================

ALTER TABLE users ADD COLUMN username VARCHAR(50) UNIQUE;
CREATE INDEX idx_users_username_lower ON users (LOWER(username));

-- Bootstrap designated initial administrators if they exist in production
UPDATE users SET role = 'ADMIN' WHERE LOWER(email) IN ('battula.keerthika0@gmail.com', 'm.mohithreddy99@gmail.com');
