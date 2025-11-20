# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project overview

- `Tourist Safety Hub` Flutter client for TourGuard, an AI-powered tourist safety & incident response system for Smart India Hackathon 2025.
- This repo contains the **mobile app only** (Flutter). Backend code is external, but a reference Node.js + Redis backend and its setup are described in `SETUP_GUIDE.md`.
- Key concepts: real-time location tracking & geofencing, offline-first incident reporting & alerts, multi-language UI, chat & family tracking, and SOS/emergency workflows.

## Common development commands

### Flutter app

- Install dependencies:
  - `flutter pub get`
- Run on a connected device/emulator (debug):
  - `flutter run`
- Analyze/lint Dart code (uses `analysis_options.yaml` + `flutter_lints`):
  - `flutter analyze`
- Run all tests:
  - `flutter test`
- Run a single test file (example – geofence helper):
  - `flutter test test/geofence_helper_test.dart`
- Build Android release APK:
  - `flutter build apk`
- Build iOS release app (requires Xcode setup):
  - `flutter build ios`

### Example backend dev (external; see `SETUP_GUIDE.md`)

The mobile app talks to a Node.js + Redis backend at `http://<server>:3000`:

- From a separate backend project (not this folder):
  - Initialize project:
    - `mkdir tourguard-backend && cd tourguard-backend && npm init -y`
  - Install deps:
    - `npm install express socket.io redis cors dotenv`
    - `npm install --save-dev nodemon`
  - Example `package.json` scripts:
    - `"start": "node server.js"`
    - `"dev": "nodemon server.js"`
  - Start Redis via Docker (from `SETUP_GUIDE.md`):
    - `docker run -d -p 6379:6379 redis`
  - Start backend in dev mode:
    - `npm run dev`

When pointing the app at a real backend, update the hosts in:

- `lib/services/api_service.dart` → `ApiService.baseUrl`
- `lib/services/chat_service.dart` → Socket `IO.io('http://...')` URL

## High-level architecture

### Entry point & navigation

- `lib/main.dart`
  - Initializes core services before `runApp`:
    - `NotificationService.initialize()` (platform channel `tourapp/notifications`)
    - `ApiService.initCache()` (Hive-backed API cache)
    - `ChatService.initialize()` (Socket.IO + local chat cache)
    - `IncidentService.initIncidents()` (local incident store)
    - `LocalizationService.initialize()` (language persistence + notifier)
  - Wraps `MaterialApp` in a `ValueListenableBuilder` bound to `LocalizationService.languageNotifier`, so changing language rebuilds the whole app.
  - Starts at `SplashScreen` (`lib/screens/splash_screen.dart`), which after a short animation navigates to `/home`.
  - `/home` maps to `MainNavigationScreen`, a 5-tab bottom-nav shell:
    - Dashboard
    - Profile
    - Explore
    - Emergency
    - Settings (v2)

### Modules

- `lib/core/themes/`
  - Global color palette and theme configuration (`AppColors`).
- `lib/models/`
  - Simple data holders for alerts, contacts, places, suggestions, users, etc.
- `lib/utils/`
  - `constants.dart` – app-wide constants, demo alerts/places, and a central definition of fixed geofence zones (`DemoData.geofenceZones`) exposed via `AppConstants.geofenceZones`.
  - `geofence_helper.dart` – converts `AppConstants.geofenceZones` into `google_maps_flutter` `Circle`s; tests assert that mapping stays in sync with `AppConstants`.
- `lib/services/` – core business logic and integration layer:
  - **API & caching:** `ApiService` (HTTP client + Hive cache-aside for GETs).
  - **Realtime chat & family tracking:** `ChatService`, `FamilyTrackingService` (Socket.IO-based messaging and periodic location updates).
  - **Incidents & E-FIRs:** `IncidentService` (local incident store, emergency response metadata, nearby incident queries).
  - **Geofence & anomaly detection:** `GeofenceService` (restricted zones, route deviation/speed anomaly detection, listeners for alerts).
  - **Other integrations:** notification, location, weather, safety score, emergency services, blockchain, auth, maps, chatbot, localization, etc.
- `lib/screens/`
  - Top-level pages for each tab (`DashboardScreen`, `ProfileScreen`, `ExploreScreen`, `EmergencyScreen`, `SettingsScreen`) and flows like `IncidentReportScreen`, `MyIncidentsScreen`, `GeofenceEventsScreen`, etc.
- `lib/widgets/`
  - Reusable UI pieces (SOS button, bottom nav bar, alert/safety cards, chatbot widget, etc.).
- `test/`
  - Unit + widget tests for geofence helpers/zones and a basic widget smoke test.

## Data & caching model

The app is designed to be **offline-first**, combining backend caching and local Hive storage (see `SETUP_GUIDE.md` and `lib/services/`).

### Local storage via Hive

Boxes and their responsibilities:

- `apiCache` (opened in `ApiService.initCache`)
  - Stores responses for GET endpoints using a cache-aside pattern keyed by `get_<endpoint>`.
  - All high-level data fetchers in `ApiService` (`getNearbyZones`, `getAlerts`, `getSafetyScore`, `getPlaces`, etc.) go through this layer.
- `chatCache` (`ChatService`)
  - Persists chat history under `messages`; all incoming/outgoing messages are saved locally, then emitted via Socket.IO.
- `incidentBox` (`IncidentService`)
  - Stores all reported incidents, E-FIRs, emergency response state, and nearby-incident heatmap data.
  - Many flows (like emergency response requests) update this store first, then sync or mirror to the backend.
- `geofenceBox` (`GeofenceService`)
  - Holds `locationHistory` and supports continuous geofence/anomaly monitoring based on `Geolocator` streams.
- `localizationBox` (`LocalizationService`)
  - Persists the `selectedLanguage`, then feeds `languageNotifier` so the UI uses the last-selected locale on startup.
- `userBox` (used by `SettingsScreen` and `IncidentReportScreen`)
  - Persists emergency contacts under `emergencyContacts`, which are then used for SMS backup in incident reporting.

When adding new persistent state, prefer defining a dedicated box and keeping access logic in a `services/` class rather than reading/writing Hive directly from widgets.

### Backend-facing services

- `ApiService` encapsulates REST calls to the Node backend at `baseUrl`:
  - Uses `http` + JSON encode/decode.
  - For GETs, it reads from Hive cache first, then backend, then falls back to cached data on error.
  - High-level helpers:
    - `getNearbyZones(lat, lng)` → `/zones`
    - `getAlerts()` → `/alerts`
    - `getSafetyScore()` → `/safety-score`
    - `getUserProfile()` → `/profile`
    - `getPlaces()` → `/places`
    - `reportIncident(data)` → `POST /incidents/report`
- `ChatService` manages the Socket.IO connection:
  - Default URL is `http://localhost:3000`.
  - Subscribes to `chatMessage`, saves messages to Hive, and notifies registered listeners.
  - `sendMessage` emits via socket but also saves locally first for offline history.
  - `FamilyTrackingService` piggybacks on this connection and periodically emits `locationUpdate` events with the user’s GPS coordinates.

If you add new backend endpoints, expose them via `ApiService` or `ChatService` rather than talking to `http` or Socket.IO directly from widgets so that caching and error handling remain consistent.

## Location, geofencing, and safety pipeline

The main safety pipeline is centered around `DashboardScreen`:

- Subscribes to a `Geolocator.getPositionStream` with a distance filter to limit updates.
- For each significant location update:
  - Updates `_currentPosition` and triggers:
    - `_evaluateGeofenceStatus` – checks against the `Circle`s drawn on the map and:
      - Tracks per-zone enter/exit state in `_zoneStates`.
      - Logs events to Hive and sends user notifications via `NotificationService.showAlertNotification` using the `tourapp/notifications` platform channel.
    - `_refreshSafetyScore` – periodically (≥ 60s) calls:
      - `LocationService.getAddressFromCoordinates`
      - `IncidentService.getNearbyIncidents` (radius ≈ 3 km)
      - `SafetyScoreService.getLiveSafetyScore` with incidents and address.
    - `_refreshWeather` – periodically (≥ 5 minutes) calls `WeatherService`:
      - Prefers `fetchOpenWeatherCurrent`, falls back to `fetchCurrentWeather`.
      - Normalizes the weather payload into a consistent structure for the UI.
    - `_refreshActiveAlerts` – periodically (≥ 5 minutes) refreshes active system alerts.
- `GeofenceService` can also run continuous background monitoring:
  - Uses `Geolocator.getPositionStream` with its own distance filter and writes compact location history to Hive.
  - `checkGeofence` determines whether the user is inside a restricted zone or approaching within a buffer.
  - `detectAnomalies` flags unusual speed or large positional jumps across recent history.
  - Alerts and anomalies are pushed to registered listeners via `onAlert`.

When modifying geofence behavior, keep `AppConstants.geofenceZones`, `GeofenceHelper.buildFixedCircles`, `GeofenceService` logic, and the tests in `test/geofence_helper_test.dart` and `test/geofence_zones_test.dart` in sync.

## Emergency, incidents, and family flows

- **SOS & emergency screen** (`EmergencyScreen`):
  - Shows a large SOS button that, when confirmed, writes an SOS alert to Firestore (`collection('alerts')`) including the current location.
  - Provides quick actions to call police/ambulance/fire via `url_launcher` `tel:` URLs.
  - Navigates to `IncidentReportScreen` for structured incident reporting.
- **Incident reporting** (`IncidentReportScreen`):
  - Captures category, urgency, description, and map-selected location (Google Maps).
  - On submit:
    - Builds a payload and tries to POST to backend via `ApiService.reportIncident`.
    - Always stores a local copy via `IncidentService.reportIncident`.
    - For high/critical urgency, requests emergency response via `IncidentService.requestEmergencyResponse`.
    - Sends optional SMS backups to saved emergency contacts (from `userBox`) using `url_launcher` with `sms:` URLs.
- **My incidents & tracking**:
  - `IncidentService.getAllIncidents` and `getNearbyIncidents` are the primary read APIs for showing lists and building heatmaps.
- **Family tracking** (`FamilyTrackingService` + Settings):
  - Controlled from `SettingsScreen` via “Family Tracking” and “Share Location with Family” toggles.
  - When enabled, a timer periodically reads `Geolocator` and emits `locationUpdate` events through `ChatService.socket`.

When you extend emergency features, prefer plumbing them through `IncidentService` and `FamilyTrackingService` so that local persistence and backend sync stay aligned.

## Localization & UI text

- All user-visible strings that use the `tr('key')` helper are defined in `LocalizationService.translations`.
- Supported languages include English (`en`), Hindi (`hi`), Spanish (`es`), and several additional Indian languages (Punjabi, Gujarati, Kannada, Bengali, Malayalam, Urdu, Telugu).
- `LocalizationService.setLanguage`:
  - Persists the language code in Hive (`localizationBox`), then updates `languageNotifier`, which causes `MaterialApp` (and any `tr()` calls) to rebuild.
- `SettingsScreen` allows language changes and uses `LocalizationService.getLanguageName` for display.

When adding new UI strings, add at least an English entry to `LocalizationService.translations['en']` and use `tr('your_key')` in widgets so the language switcher continues to work.

## Testing

- Tests live under `test/` and rely on `flutter_test` and `google_maps_flutter`:
  - `geofence_helper_test.dart` – ensures `GeofenceHelper.buildFixedCircles` stays consistent with `AppConstants.geofenceZones`.
  - `geofence_zones_test.dart` – verifies each geofence zone maps to a `Circle` with the expected id, center, and radius.
  - `widget_test.dart` – minimal widget smoke test ensuring a `Navigator` is present.
- Run tests:
  - All tests: `flutter test`
  - Single file: `flutter test test/geofence_zones_test.dart`
  - With verbose output: `flutter test -r expanded`

Keep geofence-related tests updated whenever you change geofence constants or helper logic so they continue to guard the safety-zone visualizations and behavior.
