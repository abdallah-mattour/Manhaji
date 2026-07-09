# Manhaji

## Backend Setup

The Spring Boot backend requires a JWT signing secret. Do not commit a real
secret to source control.

For local development, copy the example file and replace the placeholder:

```bash
cd backend
cp src/main/resources/application-local.example.properties src/main/resources/application-local.properties
openssl rand -base64 64
```

Paste the generated value into `app.jwt.secret`, then run with the local
profile. If your terminal wraps the generated value onto two lines, paste it
as one continuous value.

```bash
./gradlew bootRun --args='--spring.profiles.active=local'
```

You can also run without a local properties file by setting an environment
variable:

```bash
APP_JWT_SECRET="$(openssl rand -base64 64)" ./gradlew bootRun
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
