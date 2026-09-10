/* Flyway migration to add role column to users table */
ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'USER';
ALTER TABLE users ADD CONSTRAINT chk_user_role CHECK (role IN ('USER', 'ADMIN'));
