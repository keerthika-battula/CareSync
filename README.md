# CARESYNC — Smart Medicine & Healthcare Reminder Platform

**"Your Care. In Sync. On Time."**

CARESYNC is a comprehensive healthcare organization and reminder platform designed to securely manage family healthcare documents, track medicine stock, and enforce medication adherence through a robust push notification scheduling system.

> **IMPORTANT DISCLAIMER**: 
> CARESYNC is a healthcare organization/reminder platform. 
> It is **NOT**:
> - a diagnosis system
> - a treatment recommendation system
> - a prescription generator
> - an automatic dosage recommendation system

## Key Features
- **Family Profiles**: Manage healthcare data for multiple dependents securely under one unified account.
- **Smart Reminders**: Quartz-powered CRON scheduling system driving Firebase Cloud Messaging (FCM) pushes for exact time dosing.
- **Action Lifecycle**: Track every scheduled occurrence safely (TAKEN, SKIPPED, SNOOZED).
- **Stock Tracking & Refill Prediction**: Automatically deducts usage quantity safely and triggers a refill alert when remaining stock hits user thresholds.
- **Appointment Management**: Track upcoming clinic visits and receive pre-appointment alerts.
- **Secure Healthcare Documents**: MinIO/S3-compatible encrypted object storage for prescriptions, lab results, and medical reports. Strict multi-tenant data isolation prevents unauthorized IDOR access.
- **History & Statistics**: Dashboard aggregation of adherence metrics over time.

## Architecture & Technology Stack
- **Backend**: Java 21, Spring Boot 3.3.4, Spring Security (JWT)
- **Database**: PostgreSQL 16
- **Storage**: MinIO (S3 Compatible Object Storage)
- **Scheduling**: Quartz Scheduler (JDBC Persistent JobStore)
- **Migrations**: Flyway
- **Mobile Client**: Flutter (Android/iOS) with Riverpod, Dio, and Flutter Secure Storage
- **Push Notifications**: Firebase Cloud Messaging (FCM)

## Project Structure
```text
CareSync/
├── backend/            # Spring Boot REST API
├── mobile/             # Flutter Native Mobile App
├── web/                # Responsive HTML/CSS Landing Page
├── docker-compose.yml  # Local Infrastructure Config
├── .env.example        # Environment defaults
└── README.md
```

## Local Setup

### 1. Environment Variables
Copy the `.env.example` file to `.env`:
```bash
cp .env.example .env
```
Ensure you provide secure passwords. **Do NOT commit the `.env` file or Firebase credentials.**

### 2. Infrastructure (Docker)
Start the PostgreSQL, Redis, and MinIO instances:
```bash
docker compose up -d
docker compose ps
```

### 3. Firebase Setup
To enable Push Notifications, place your `firebase-service-account.json` inside:
`backend/src/main/resources/firebase-service-account.json`

### 4. Backend Startup
```bash
cd backend
mvn clean compile
mvn spring-boot:run
```
The application runs on `http://localhost:8080`.
Check Health: `GET http://localhost:8080/actuator/health`
Check Swagger Docs: `http://localhost:8080/swagger-ui.html`

### 5. Flutter Startup
Ensure the Flutter SDK is installed and connected to a simulator/emulator.
```bash
cd mobile
flutter pub get
flutter run
```

## Security Considerations
- **Data Isolation**: All document, appointment, and medicine API queries securely enforce strict ownership mapping down to the `family_member_id` and the authenticated `user_id`.
- **JWT**: Stateless, short-lived tokens.
- **Secrets**: Passwords hashed using BCrypt. MinIO, Firebase, and PostgreSQL credentials rely strictly on environmental injection.
- **Path Traversal**: Object keys in MinIO are uniquely generated UUID combinations appended to User IDs, preventing client-side path injection.

## Testing
Run the backend integration test suite with:
```bash
mvn test
```
*(Covers Quartz scheduling logic, duplicate TAKEN prevention, stock bounds limits, RefillAlert creation, and Unauthorized Access rejection).*
