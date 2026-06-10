# GuardMe - Personal Safety App

Emergency alerting, trip tracking, and real-time notifications.

```
┌─────────────┐     HTTP/WS      ┌──────────────┐     JDBC      ┌─────────┐
│  Flutter App │ ───────────────→ │ Spring Boot  │ ────────────→ │  MySQL  │
│  (Android/   │ ←─────────────── │  Backend     │ ←──────────── │  8.2    │
│   iOS/Linux) │    JSON/STOMP    │  :8080       │               │  :3306  │
└─────────────┘                   └──────────────┘               └─────────┘
```

## Prerequisites

| Tool | Windows | Linux |
|------|---------|-------|
| **Docker** | [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/) | `sudo apt install docker.io docker-compose-v2` |
| **Flutter** | [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) | [Flutter SDK](https://docs.flutter.dev/get-started/install/linux) |
| **Git** | `git` from [git-scm.com](https://git-scm.com) | `sudo apt install git` |

Verify everything is installed:
```bash
docker --version
docker compose version
flutter --version
git --version
```

## Quick Start

### 1. Clone & enter project

```bash
git clone <repo-url> guardmev2
cd guardmev2
```

### 2. Set up backend environment

Copy and edit the backend env file:
```bash
cp .env.example .env
# Edit .env to add your Twilio/SMTP keys (optional)
```

The `.env` file lives at the **project root** (`guardmev2/.env`). Docker Compose reads it automatically.

| Variable | Required | Description |
|----------|----------|-------------|
| `JWT_SECRET` | **Yes** | Base64-encoded 256+ bit secret for JWT signing |
| `TWILIO_ACCOUNT_SID` | No | Twilio account SID (SMS/WhatsApp) |
| `TWILIO_AUTH_TOKEN` | No | Twilio auth token |
| `TWILIO_FROM_NUMBER` | No | Twilio phone number |

A default `JWT_SECRET` is built in. For production, generate a new one:
```bash
openssl rand -base64 64
```

### 3. Set up Flutter environment

Copy and edit the Flutter env file:
```bash
cd guardme_app
cp .env.example .env
# Edit .env with your API keys
```

The `.env` file lives at **`guardme_app/.env`**. Flutter reads it at runtime.

| Variable | Required | Description |
|----------|----------|-------------|
| `GOOGLE_MAPS_API_KEY` | **Yes** | Google Maps API key (get from [console.cloud.google.com](https://console.cloud.google.com)) |
| `ALAN_VOICE_KEY` | No | Alan AI voice assistant key |
| `API_BASE_URL` | **Yes** | Backend URL (see table below) |

#### API_BASE_URL by platform

| Platform | Value | Notes |
|----------|-------|-------|
| Android Emulator | `http://10.0.2.2:8080` | 10.0.2.2 reaches host machine |
| Android Device (USB/Wi-Fi) | `http://<your-ip>:8080` | See [Find your IP](#6-same-network--finding-your-ip) |
| iOS Device (physical) | `http://<your-ip>:8080` | Same network required; use LAN IP |
| iOS Simulator | `http://localhost:8080` | Simulator shares host network |
| Linux Desktop | `http://localhost:8080` | Runs natively on host |
| Chrome Web | `http://localhost:8080` | Runs in browser |

> **Tip:** You can also set the backend URL at runtime from the app's **Settings** screen — no need to edit `.env` files every time.

### 4. Start backend (Docker)

From the **project root** (`guardmev2/`):
```bash
docker compose up -d
```

Or use the included scripts:

| OS | Script |
|----|--------|
| Windows | Double-click `start_backend.bat` |
| Linux/macOS | `./start_backend.sh` |

What this does:
- `docker compose up` — Creates and starts MySQL + Backend containers
- `-d` — Runs in detached mode (background), so you can keep using the terminal

This starts:
- **MySQL 8.2** — port `3306` (exposed to host for debugging; only needed inside Docker network)
- **Backend API** — port `8080`

First startup takes ~2-3 minutes (Docker builds the backend + Liquibase runs migrations).

#### View logs

```bash
docker compose logs -f          # tail all services
docker compose logs -f backend  # backend only
docker compose logs -f mysql    # database only
```

Press `Ctrl+C` to exit log view (containers keep running).

#### Check health

```bash
curl http://localhost:8080/management/health
# → {"status": "UP"}
```

If the response is `{"status": "UP"}`, the backend is ready.

#### Restart after code changes

```bash
docker compose build --no-cache backend   # rebuild the image
docker compose up -d                      # recreate containers
```

Or as a single command:
```bash
docker compose up -d --build
```

---

### 5. Run Flutter app

```bash
cd guardme_app
flutter pub get
flutter run
```

Select your device when prompted:
- Android emulator (recommended)
- Chrome (web — limited functionality, no GPS)
- Linux desktop (if on Linux)
- Connected Android device

To run on a **specific device** without the prompt:
```bash
flutter devices                        # list available devices
flutter run -d <device-id>             # e.g. flutter run -d chrome
```

#### How to use the app

The app has the following screens:

| Route | Screen | What it does |
|-------|--------|--------------|
| `/splash` | Splash | Auto-check auth, redirects to `/login` or `/home` |
| `/signup` | Sign Up | Create a new account (name, email, password) |
| `/login` | Login | Sign in with existing credentials |
| `/home` | Dashboard | Main hub with quick-access tiles (SOS, Map, Trips, Contacts, Notifications) |
| `/map` | Live Map | Real-time location tracking with Google Maps |
| `/contacts` | Emergency Contacts | Add/edit trusted contacts who get alerts |
| `/notifications` | Notifications | View alert history and trip notifications |
| `/trips` | Trip Details | Active trip tracking with shareable links |
| `/profile` | Profile | View/edit user profile and guardian settings |
| `/settings` | Settings | **Configure backend server URL** (see below) |

**Settings screen** — If your device can't reach the backend, go to `/settings`:
1. Toggle **"Use default address"** OFF
2. Enter your machine's IP address (see step 6 below)
3. Tap **"Test Connection"** to verify
4. Tap **"Save Settings"** and **restart the app**

---

### 6. Same network & finding your IP

**The Flutter app and the Docker backend MUST be on the same network** to communicate. Use your machine's LAN IP (not `localhost` or `127.0.0.1`) when running on a physical phone or a different device.

#### Find your IP on Linux

```bash
ip addr show | grep 'inet ' | grep -v 127.0.0.1
# or
hostname -I
```

Example output: `192.168.1.100` — use this as the backend IP.

#### Find your IP on Windows

**Option 1 — Run the included script (easiest):**

Double-click `find_ip.bat` from the project folder. It prints only your IPv4 addresses.

**Option 2 — PowerShell:**

```powershell
ipconfig
```

Look for the **IPv4 Address** under your active network adapter (Wi-Fi or Ethernet).

Example output: `192.168.1.105` — use this as the backend IP.

#### Find your IP on macOS

```bash
ipconfig getifaddr en0   # Wi-Fi
ipconfig getifaddr en1   # Ethernet
```

#### Set it in the Flutter app

Once you have your IP:
1. Open the app → go to **Settings** (`/settings`)
2. Toggle **"Use default address"** OFF
3. Enter your IP (e.g., `192.168.1.100`) and port (`8080`)
4. Tap **"Test Connection"** — should show a green success
5. Tap **"Save Settings"** and **restart the app**

Alternatively, set it in the `.env` file (`guardme_app/.env`):
```env
API_BASE_URL=http://192.168.1.100:8080
```

Then restart the app.

---

### 7. Stop everything

```bash
# Stop containers (keeps data volumes):
docker compose down

# Stop containers AND delete the database volume:
docker compose down -v
```

Or use the included scripts:

| OS | Script |
|----|--------|
| Windows | Double-click `stop_backend.bat` |
| Linux/macOS | `./stop_backend.sh` |

| Command | Stops containers | Removes containers | Deletes DB data | Deletes images |
|---------|:---:|:---:|:---:|:---:|
| `docker compose stop` | Yes | No | No | No |
| `docker compose down` | Yes | Yes | No | No |
| `docker compose down -v` | Yes | Yes | Yes | No |
| `docker compose down --rmi all` | Yes | Yes | No | Yes |

Use `docker compose down` for normal shutdown. Use `-v` only if you want a **clean slate** (all data wiped).

To see what's running:
```bash
docker compose ps
```

---

## Platform-Specific Notes

### Windows (Docker Desktop)

- Docker Desktop uses WSL2 backend. Everything works the same as Linux.
- If you see `File not found` errors, ensure Git is set to checkout with `LF` endings:
  ```bash
  git config --global core.autocrlf input
  ```
- Flutter on Windows: use **PowerShell** or **Command Prompt** (not Git Bash for `flutter run`).

### Linux

- If running without sudo, add your user to the `docker` group:
  ```bash
  sudo usermod -aG docker $USER
  # Then log out and back in
  ```
- Flutter Linux desktop requires `gtk3`:
  ```bash
  sudo apt install libgtk-3-dev
  ```

### macOS

- Same as Linux. Use Docker Desktop for Mac or `colima`.
- iOS simulator: use `flutter run -d ios` (requires Xcode).

---

## Environment File Locations (Cheat Sheet)

```
guardmev2/                        ← project root
├── .env                          ← BACKEND env vars (JWT_SECRET, Twilio)
│                                   Auto-loaded by docker compose
│
├── guardme_app/
│   ├── .env                      ← FLUTTER env vars (API keys, backend URL)
│   │                               Loaded by flutter_dotenv at runtime
│   └── ...
│
├── docker-compose.yml
└── README.md
```

### `.env.example` files — create these yourself

**Root `.env.example`** (for reference):
```env
JWT_SECRET=your-base64-secret-here
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_FROM_NUMBER=
SPRING_MAIL_HOST=
SPRING_MAIL_PORT=
SPRING_MAIL_USERNAME=
SPRING_MAIL_PASSWORD=
```

**`guardme_app/.env.example`** (for reference):
```env
GOOGLE_MAPS_API_KEY=your-google-maps-key
ALAN_VOICE_KEY=your-alan-voice-key
API_BASE_URL=http://10.0.2.2:8080
```

---

## Troubleshooting

### Backend won't start

```bash
# Check logs
docker compose logs backend

# Most common: MySQL not ready yet. Wait 30s and retry.
# Or rebuild:
docker compose build --no-cache backend
docker compose up -d
```

### Flutter build error on Linux

```
error: identifier '_json' preceded by whitespace in a literal operator declaration
```

This is a `flutter_secure_storage` C++ plugin issue. Already fixed in this project's `linux/CMakeLists.txt`. If you regenerate the Linux folder, re-apply the fix:
```cmake
target_compile_options(${TARGET} PRIVATE -Wno-deprecated-literal-operator)
```

### Flutter can't connect to backend

1. Check backend is running: `curl http://localhost:8080/management/health`
2. **Are both devices on the same network?** Phone and computer must be on the same Wi-Fi. Mobile data won't work.
3. Check `API_BASE_URL` in `guardme_app/.env` matches your platform
4. Android emulator: use `10.0.2.2` (not `localhost`)
5. Physical Android/iOS device: use your computer's **LAN IP** (see [Find your IP](#6-same-network--finding-your-ip) above)
6. Use the in-app **Settings** screen (`/settings`) to test and configure the backend URL without editing files
7. Firewall may block port 8080. On Linux, allow it:
   ```bash
   sudo ufw allow 8080/tcp
   ```

### Port already in use

Edit `docker-compose.yml` to change ports:
```yaml
ports:
  - "9090:8080"   # change 8080 to 9090 (host:container)
```

Then update `API_BASE_URL` in Flutter `.env` to match.

---

## Project Structure

```
guardmev2/
├── backend/                  # Spring Boot 3.2 / Java 17
│   ├── src/main/java/com/guardme/
│   │   ├── config/           # Security, WebSocket, CORS, Jackson
│   │   ├── domain/           # JPA entities (9)
│   │   ├── repository/       # Spring Data JPA repos (9)
│   │   ├── service/          # Business logic (7)
│   │   ├── web/rest/         # REST controllers (10)
│   │   └── security/         # JWT provider, filter, UserDetails
│   ├── src/main/resources/
│   │   ├── application.yml
│   │   ├── application-docker.yml
│   │   └── db/changelog/     # Liquibase migrations
│   ├── Dockerfile
│   └── pom.xml
├── guardme_app/              # Flutter (Riverpod + Clean Architecture)
│   ├── lib/
│   │   ├── core/             # Dio client, constants, exceptions
│   │   ├── data/repositories # API calls
│   │   ├── domain/           # Entities, interfaces
│   │   └── presentation/
│   │       ├── providers/    # Riverpod state (4)
│   │       ├── pages/        # Screens (9)
│   │       ├── widgets/      # Reusable UI (4)
│   │       └── router/       # GoRouter
│   └── pubspec.yaml
├── docker-compose.yml
└── README.md
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Spring Boot 3.2, Java 17, Maven |
| Database | MySQL 8.2, Liquibase migrations |
| Auth | JWT (jjwt 0.12), BCrypt |
| Cache | Hazelcast (embedded) |
| Real-time | WebSocket STOMP |
| SMS/WhatsApp | Twilio SDK |
| Frontend | Flutter 3, Dart 3 |
| State Mgmt | Riverpod |
| Routing | GoRouter |
| HTTP | Dio |
| Maps | Google Maps Flutter |
| Container | Docker, Docker Compose |
