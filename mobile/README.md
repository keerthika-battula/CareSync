# CareSync — Frontend Client (Flutter Web & PWA)

This directory contains the cross-platform Flutter frontend for the CareSync healthcare organization platform. It is engineered with full support for **Flutter Web / PWA** as well as responsive mobile and desktop viewports.

---

## Key Technical Highlights

- **Framework**: Flutter 3.x with Dart
- **Target Platforms**: Web (PWA-enabled), Android, iOS, Desktop
- **State Management**: [Riverpod](https://riverpod.dev) (StateNotifierProvider, AsyncValue, FutureProvider.family)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) with declarative role-aware route guards
- **Networking**: [Dio](https://pub.dev/packages/dio) configured with JWT authentication interceptors and token auto-refresh
- **Secure Storage**: `flutter_secure_storage` with cross-platform persistence
- **Design System**: Modern healthcare SaaS UI with responsive sidebar navigation, clean cards, metric grids, and dynamic theme tokens
- **Branding**: Dedicated `AppLogo` vector and raster assets with official `CARESYNC` typography

---

## Directory Structure

```text
mobile/
├── lib/
│   ├── core/           # Constants, theme, network client, router, secure storage
│   ├── features/       # Feature-driven architecture
│   │   ├── admin/      # Admin dashboard, user directory, user detail, healthcare inspection
│   │   ├── appointments/# Appointment scheduling and management
│   │   ├── auth/       # Authentication, login, register, role providers
│   │   ├── dashboard/  # Main overview, dynamic horizontal greetings, adherence summaries
│   │   ├── documents/  # Medical document uploads, browser preview, downloads
│   │   ├── family/     # Family member profiles, public community directory
│   │   ├── medicines/  # Medication tracking, stock thresholds, refill alerts
│   │   └── profile/    # Authenticated user details, security status, sign-out
│   └── shared/         # Reusable widgets (AppLogo, AppButton, MainScaffold)
├── test/               # Widget and role-model automated test suite
└── pubspec.yaml        # Flutter package specifications and assets
```

---

## Verification & Quality Status

The frontend has been verified locally:

- **Static Analysis**: `flutter analyze` — **No issues found** (0 errors, 0 warnings)
- **Automated Tests**: `flutter test` — **All 8 tests passed**
- **Production Build**: `flutter build web --release` — **Build succeeded**
- **Browser Automation**: Verified via Chrome CDP across Desktop (1280×800) and Mobile (375×812) viewports with zero RenderFlex overflows and zero runtime console exceptions.

---

## Local Development Commands

### Install Dependencies
```bash
flutter pub get
```

### Run in Chrome (Web)
```bash
flutter run -d chrome
```

### Run Static Analysis
```bash
flutter analyze
```

### Run Automated Tests
```bash
flutter test
```

### Build Production Web Release
```bash
flutter build web --release
```
The optimized production bundle will be generated under `build/web/`.

