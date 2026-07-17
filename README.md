# Manhaji 📚

**Full-stack education platform for school students** — a Flutter mobile app backed by a Java Spring Boot REST API, with role-based experiences for students, parents, teachers, and admins.

Students follow their curriculum through lessons, quizzes, and audio content; parents track their children's progress; teachers create and assign quizzes and review class results; admins manage users with full audit logging.

## Architecture

```
Manhaji/
├── manhaji_app/   → Flutter mobile app (Dart)
├── backend/       → Spring Boot REST API (Java)
├── manhaji.sql    → MySQL database schema
└── tools/         → Python utilities (curriculum & PDF content extraction)
```

## Backend (Java / Spring Boot)

- **REST API** with 12+ controllers: authentication, lessons, quizzes, quiz assignment, progress tracking, progress reports, leaderboard, and student / parent / teacher / admin management
- **Security:** Spring Security with JWT (jjwt), role-based authorization, phone-number login support
- **Persistence:** Spring Data JPA + MySQL, request validation, DTO request/response layers
- **Adaptive quizzes:** quiz engine that adjusts to student mastery (knowledge-tracing based)
- **AI integration:** external AI API calls via Spring WebClient (WebFlux)
- **Auditing & ops:** AspectJ-based audit logs for all admin actions, Spring Boot Actuator, database seeding for local development

## Mobile App (Flutter / Dart)

- **State management:** Provider
- **Networking:** Dio HTTP client against the Spring Boot API
- **Secure auth:** JWT tokens stored in `flutter_secure_storage` (Android Keystore / iOS Keychain)
- **Local storage:** `shared_preferences` for user settings
- **Learning UX:** audio lesson playback (`just_audio`), voice recording (`record`), progress charts (`fl_chart`), localization, animated mascots and celebration effects

## Run locally

**Backend** (requires Java 17+, MySQL):
```bash
cd Manhaji/backend
# create a MySQL database named manhaji_db (or set MANHAJI_DB_URL)
./gradlew bootRun
```

**Mobile app** (requires Flutter):
```bash
cd Manhaji/manhaji_app
flutter pub get
flutter run
```

## Tech Stack

`Java` `Spring Boot` `Spring Security` `JWT` `Spring Data JPA` `MySQL` `Spring WebClient` `Actuator` `Flutter` `Dart` `Provider` `Dio` `Python`
