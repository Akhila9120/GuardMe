# GuardMe - Personal Safety App

A personal safety application with emergency alerting, trip tracking, and real-time notifications.

## Architecture

- **Backend**: Spring Boot 3.2 / Java 17 (Docker container)
- **Database**: MySQL 8.2 (Docker container)
- **Frontend**: Flutter (runs on Android emulator / iOS simulator / device)
- **Real-time**: WebSocket (STOMP) for live notifications

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Flutter SDK (for mobile app development)

### 1. Start Backend Services

```bash
docker compose up -d
```

This starts:
- MySQL on port 3306
- Backend API on port 8080

Check health:
```bash
curl http://localhost:8080/management/health
```

### 2. Run Flutter App

```bash
cd guardme_app
flutter pub get
flutter run
```

The app connects to the backend at `http://10.0.2.2:8080` (Android emulator default).

### 3. Stop Services

```bash
docker compose down
```

To also delete the database volume:
```bash
docker compose down -v
```

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `JWT_SECRET` | Base64-encoded JWT signing key | (built-in default) |
| `TWILIO_ACCOUNT_SID` | Twilio account SID | (optional) |
| `TWILIO_AUTH_TOKEN` | Twilio auth token | (optional) |
| `TWILIO_FROM_NUMBER` | Twilio phone number | (optional) |

## Flutter Configuration

Create `guardme_app/.env`:

```env
GOOGLE_MAPS_API_KEY=your_key_here
ALAN_VOICE_KEY=your_key_here
API_BASE_URL=http://10.0.2.2:8080
```

## Project Structure

```
guardmev2/
├── backend/              # Spring Boot API
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
├── guardme_app/          # Flutter mobile app
│   ├── lib/
│   └── pubspec.yaml
├── docker-compose.yml    # Docker orchestration
├── .env                  # Backend environment
└── README.md
```

## Features

- User authentication (JWT)
- Real-time trip tracking with Google Maps
- Emergency alerting (SMS + WhatsApp via Twilio)
- Emergency contacts management
- Voice data recording during trips
- WebSocket notifications
- Dark & Light theme
