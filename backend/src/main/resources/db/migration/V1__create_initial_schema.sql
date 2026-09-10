-- =============================================
-- CareSync Initial Database Schema
-- V1 - Initial Schema
-- =============================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================
-- USERS
-- =============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_email_verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================
-- REFRESH TOKENS
-- =============================================
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    is_revoked BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================
-- FAMILY MEMBERS
-- =============================================
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    relationship VARCHAR(50),
    date_of_birth DATE,
    blood_group VARCHAR(10),
    notes TEXT,
    is_self BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================
-- MEDICINES
-- =============================================
CREATE TABLE medicines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_member_id UUID NOT NULL REFERENCES family_members(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    dosage VARCHAR(100),
    dosage_unit VARCHAR(50),
    instructions TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_ongoing BOOLEAN NOT NULL DEFAULT false,
    current_stock INTEGER,
    refill_threshold INTEGER DEFAULT 7,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================
-- MEDICINE SCHEDULES
-- =============================================
CREATE TABLE medicine_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
    frequency VARCHAR(50) NOT NULL,
    days_of_week JSONB,
    scheduled_times JSONB NOT NULL,
    dosage_per_intake DECIMAL(10, 2) NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================
-- MEDICINE LOGS
-- =============================================
CREATE TABLE medicine_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
    schedule_id UUID REFERENCES medicine_schedules(id),
    scheduled_time TIMESTAMP NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('TAKEN', 'SKIPPED', 'SNOOZED')),
    recorded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================
-- APPOINTMENTS
-- =============================================
CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_member_id UUID NOT NULL REFERENCES family_members(id) ON DELETE CASCADE,
    doctor_name VARCHAR(200),
    hospital_clinic VARCHAR(200),
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    purpose VARCHAR(500),
    notes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'UPCOMING' CHECK (status IN ('UPCOMING', 'COMPLETED', 'CANCELLED')),
    reminder_minutes_before INTEGER DEFAULT 60,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================
-- DOCUMENTS
-- =============================================
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_member_id UUID NOT NULL REFERENCES family_members(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('PRESCRIPTION', 'LAB_REPORT', 'MEDICAL_REPORT', 'INSURANCE', 'OTHER')),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT,
    mime_type VARCHAR(100),
    document_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================
-- NOTIFICATION PREFERENCES
-- =============================================
CREATE TABLE notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    medicine_reminders_enabled BOOLEAN NOT NULL DEFAULT true,
    refill_reminders_enabled BOOLEAN NOT NULL DEFAULT true,
    appointment_reminders_enabled BOOLEAN NOT NULL DEFAULT true,
    missed_reminder_notifications BOOLEAN NOT NULL DEFAULT true,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================
-- FCM TOKENS
-- =============================================
CREATE TABLE fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    device_type VARCHAR(20) CHECK (device_type IN ('ANDROID', 'IOS', 'WEB')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, token)
);

-- =============================================
-- INDEXES
-- =============================================
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);

CREATE INDEX idx_family_members_user_id ON family_members(user_id);

CREATE INDEX idx_medicines_family_member_id ON medicines(family_member_id);
CREATE INDEX idx_medicines_is_active ON medicines(is_active);

CREATE INDEX idx_medicine_schedules_medicine_id ON medicine_schedules(medicine_id);

CREATE INDEX idx_medicine_logs_medicine_id ON medicine_logs(medicine_id);
CREATE INDEX idx_medicine_logs_scheduled_time ON medicine_logs(scheduled_time);
CREATE INDEX idx_medicine_logs_action ON medicine_logs(action);

CREATE INDEX idx_appointments_family_member_id ON appointments(family_member_id);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);

CREATE INDEX idx_documents_family_member_id ON documents(family_member_id);
CREATE INDEX idx_documents_type ON documents(document_type);

CREATE INDEX idx_fcm_tokens_user_id ON fcm_tokens(user_id);
