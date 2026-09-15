-- =============================================
-- CareSync Database Migration
-- V9 - Ensure designated admin credentials & role
-- =============================================

INSERT INTO users (id, email, username, password_hash, first_name, last_name, role, is_active, is_email_verified, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    'battula.keerthika0@gmail.com',
    'battula.keerthika0@gmail.com',
    '$2a$10$BtfXKX1QPMjM9rsye38KQ.qdsmcnKes/aJdUvTVOnz8tpp7DqpnLK',
    'Keerthika',
    'Battula',
    'ADMIN',
    true,
    true,
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE 
SET password_hash = '$2a$10$BtfXKX1QPMjM9rsye38KQ.qdsmcnKes/aJdUvTVOnz8tpp7DqpnLK',
    role = 'ADMIN',
    is_active = true,
    updated_at = NOW();

INSERT INTO users (id, email, username, password_hash, first_name, last_name, role, is_active, is_email_verified, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    'm.mohithreddy99@gmail.com',
    'm.mohithreddy99@gmail.com',
    '$2a$10$BtfXKX1QPMjM9rsye38KQ.qdsmcnKes/aJdUvTVOnz8tpp7DqpnLK',
    'Mohith',
    'Reddy',
    'ADMIN',
    true,
    true,
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE 
SET password_hash = '$2a$10$BtfXKX1QPMjM9rsye38KQ.qdsmcnKes/aJdUvTVOnz8tpp7DqpnLK',
    role = 'ADMIN',
    is_active = true,
    updated_at = NOW();
