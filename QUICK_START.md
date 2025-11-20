# 🚀 TourGuard - Quick Start Guide

## What is TourGuard?
A comprehensive mobile app for tourist safety with real-time geofencing, multilingual support (10 languages), emergency alerts, and AI-powered chatbot assistance.

---

## ✨ What You Get

### Core Features Ready to Use ✅
- **Safety Dashboard** - Real-time safety score with zone status
- **Emergency SOS** - One-touch emergency alert with location
- **Incident Reporting** - Report unsafe situations with map location
- **Geofencing** - Automatic alerts when entering danger zones
- **Language Switching** - Instant switch between 10 languages
- **Chatbot** - AI assistant for tourist help
- **Family Tracking** - Share location with family
- **Weather Alerts** - Real-time weather-based safety warnings

### Supported Languages 🌍
English, Spanish, Hindi, Punjabi, Gujarati, Kannada, Bengali, Malayalam, Urdu, Telugu

---

## 🎯 Recent Improvements

✅ **Language Switching Fixed** - Changing language now updates the entire app instantly
✅ **TourGuard Branding** - App name changed to "TourGuard" across all platforms  
✅ **New Icon** - Professional diamond-shaped TourGuard logo added
✅ **Dashboard Localized** - All dashboard text uses translation system
✅ **Screen Rebuilding** - Screens rebuild when language changes

---

## 🔧 Setup Instructions

### 1. Install Flutter
```bash
# If not already installed
curl https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.16.0.zip
# Unzip and add to PATH
```

### 2. Get Dependencies
```bash
cd /Users/shubham/alternnate/TourGuard_AppInterface
flutter pub get
```

### 3. Configure Google Maps API (IMPORTANT)
The app requires a Google Maps API key. To set it up:

**For Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE"/>
```

**For iOS** (`ios/Runner/Info.plist`):
```xml
<key>GMSAPIKey</key>
<string>YOUR_ACTUAL_API_KEY_HERE</string>
```

### 4. Get API Key (Free Option Available)
Visit: https://console.cloud.google.com/
1. Create a project
2. Enable Google Maps SDK
3. Create API key (Maps SDK for Android + Maps SDK for iOS)
4. Restrict to your app package name

### 5. Run the App
```bash
flutter run
```

Or target a specific device:
```bash
flutter run -d emulator-5554
```

---

## 📱 Testing on Emulator

### Android Emulator
```bash
# List available emulators
flutter emulators

# Launch one
flutter emulators --launch Pixel_4_API_30

# Run app
flutter run
```

### iOS Simulator
```bash
open -a Simulator
flutter run
```

---

## 🌐 Language Testing

To test language switching:
1. Open the app
2. Go to Settings (bottom navigation)
3. Tap "Language & Region"
4. Select a different language
5. Watch as the entire app updates instantly!

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry - has ValueListenableBuilder for language
├── screens/                     # All user-facing screens
│   ├── dashboard_screen.dart    # Main safety dashboard
│   ├── settings_screen_v2.dart  # Language & settings picker
│   └── [other screens...]
├── services/
│   ├── localization_service.dart  # ⭐ Language support (10 languages)
│   ├── location_service.dart      # GPS & permissions
│   ├── map_service.dart           # Safety zones calculation
│   └── [other services...]
└── assets/
    └── images/
        └── icon.png             # TourGuard logo
```

---

## 🎨 Key Components

### Language System (Fully Integrated)
- **Service**: `LocalizationService` 
- **Helper**: `tr('key')` function
- **Persistence**: Hive database stores language choice
- **Auto-update**: All screens rebuild when language changes

### Location System
- **Service**: `LocationService`
- **Features**: Permission handling, GPS tracking, stream updates
- **Used in**: Dashboard, Emergency, IncidentReport screens

### Safety Score
- **Calculation**: Based on zone, crowd, weather, incidents
- **Update**: Real-time as location changes
- **Display**: Dashboard with visual indicators

---

## 🔐 Key Files to Know

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry with language listener |
| `lib/services/localization_service.dart` | 10-language translation system |
| `lib/screens/dashboard_screen.dart` | Main safety dashboard |
| `lib/screens/settings_screen_v2.dart` | Language & setting controls |
| `pubspec.yaml` | Dependencies & app configuration |
| `android/app/src/main/AndroidManifest.xml` | Android settings (API key) |
| `ios/Runner/Info.plist` | iOS settings (API key) |

---

## 🚀 Build for Release

### Android APK
```bash
flutter build apk
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS App
```bash
flutter build ios
# Requires Xcode for final build
```

---

## 🐛 Common Issues & Solutions

### Issue: Google Maps shows blank
**Solution**: Add valid API key to AndroidManifest.xml and Info.plist

### Issue: App crashes on startup
**Solution**: Run `flutter clean && flutter pub get`

### Issue: Language not changing
**Solution**: Ensure you're using `tr('key')` in Text widgets, not hardcoded strings

### Issue: Permissions not working
**Solution**: Grant location permission in app settings after first launch

---

## 📊 Testing Checklist

- [ ] App launches without errors
- [ ] Dashboard shows safety score
- [ ] Can change language in Settings
- [ ] Dashboard text updates when language changes
- [ ] Emergency button is accessible
- [ ] Can see map with current location
- [ ] Incident report form is fillable
- [ ] Settings screen opens without issues

---

## 🔗 Important Notes

1. **API Key Required** - App will not show maps without valid Google Maps API key
2. **Permissions** - Must grant location permission for app to work properly
3. **Language Files** - Already includes 10 languages, no additional setup needed
4. **Firebase Optional** - App runs fine without Firebase for demo purposes

---

## 📚 Dependencies Overview

```yaml
# Core
flutter: main framework
google_maps_flutter: Maps display
geolocator: GPS tracking
permission_handler: App permissions

# UI
google_fonts: Typography
cached_network_image: Image loading
flutter_chat_bubble: Chat UI

# Data
hive: Local database
cloud_firestore: Backend storage
firebase_auth: User authentication

# Features
intl: Localization support
socket_io_client: Real-time updates
google_generative_ai: Chatbot AI
```

---

## ✅ Verification Checklist

Before deploying:
- [ ] Icon set to TourGuard diamond logo
- [ ] App name is "TourGuard" in all platforms
- [ ] All 10 languages have complete translations
- [ ] Language switching works instantly
- [ ] Dashboard uses `tr()` for all text
- [ ] No hardcoded English strings visible to users
- [ ] API keys configured for your environment

---

## 🎉 You're Ready!

TourGuard is production-ready. Just:
1. Add your Google Maps API key
2. Configure Firebase (optional)
3. Test on device
4. Submit to App Store/Play Store

**Questions?** Check the code comments in each service - they explain the implementation!

---

**TourGuard v1.0.0** - Making Tourist Safety a Priority 🛡️
