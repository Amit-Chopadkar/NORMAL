# TourGuard Wear OS - Emergency SOS App

A Flutter-based Wear OS application that provides emergency SOS functionality and intelligent zone notifications for the TourGuard safety platform.

## Features

### 🆘 Emergency SOS
- **Large SOS Button**: Prominent red button for quick emergency access
- **3-Second Countdown**: Prevents accidental triggers with cancellable countdown
- **Location Sharing**: Automatically sends GPS coordinates to backend
- **Retry Logic**: Ensures alert delivery even with poor connectivity
- **Haptic Feedback**: Strong vibrations confirm alert sending

### 🗺️ Intelligent Zone Monitoring
- **Real-time Geofencing**: Continuously monitors user location
- **Risk-Based Alerts**: Different notifications for zone types:
  - **🔴 DANGER/RED ZONES**: Critical alert with 3 vibration pulses
  - **🟡 CAUTION/YELLOW ZONES**: Warning with 2 vibration pulses
  - **🟢 SAFE/GREEN ZONES**: Info notification with 1 pulse
- **Approach Warnings**: 500m buffer alerts before entering zones
- **Smart Deduplication**: Avoids repeated alerts (15-min cooldown)
- **Offline Support**: Falls back to hardcoded zones if API unavailable

### 📡 Backend Integration
- Connects to TourGuard backend API
- `POST /api/sos` - Send emergency alerts
- `GET /api/zones?lat=X&lng=Y` - Fetch nearby safety zones
- Configurable backend URL via settings

## Setup

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio with Wear OS emulator
- TourGuard backend running

### Installation

1. **Install Dependencies**:
   ```bash
   cd "wear os"
   flutter pub get
   ```

2. **Configure Backend URL**:
   - Default: `http://10.0.2.2:3000` (for emulator)
   - For physical device: Use your computer's IP address
   - Can be changed in app settings

3. **Build and Run**:
   ```bash
   # For Wear OS emulator
   flutter run
   
   # For physical Wear OS device
   flutter run -d <device-id>
   ```

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/
│   ├── zone.dart                  # Safety zone model
│   ├── sos_alert.dart             # SOS alert model
│   └── zone_alert.dart            # Zone notification model
├── services/
│   ├── api_service.dart           # Backend API integration
│   ├── location_service.dart      # GPS location tracking
│   ├── sos_service.dart           # SOS alert handler
│   ├── zone_service.dart          # Zone monitoring & geofencing
│   └── notification_service.dart  # Vibration & haptics
└── screens/
    ├── home_screen.dart           # Main SOS button screen
    ├── zone_alert_screen.dart     # Zone entry notifications
    ├── confirmation_screen.dart   # SOS confirmation
    └── settings_screen.dart       # App configuration
```

## Usage

### Sending SOS Alert
1. Tap the large red **SOS** button
2. 3-second countdown begins (button turns orange)
3. Tap again to cancel, or wait for auto-send
4. Confirmation screen shows success/failure

### Zone Notifications
- Watch automatically monitors your location
- Full-screen alert when entering danger/caution zones
- Current zone indicator shown on home screen
- Quick SOS button available on danger zone alerts

### Configuration
1. Swipe down or tap Settings icon
2. Enter backend URL
3. Tap Save

## Safety Zones

Default hardcoded zones (used when API unavailable):

| Zone | Type | Risk | Radius | Location |
|------|------|------|--------|----------|
| Remote Forest | Danger | High | 2000m | 20.0112, 73.7909 |
| Market Area | Caution | Medium | 800m | 20.0150, 73.7950 |
| Industrial Zone | Danger | High | 1500m | 20.0050, 73.7850 |
| Tourist Zone | Safe | Low | 500m | 20.0098, 73.7954 |

## Testing

### On Emulator
1. Launch Wear OS emulator from Android Studio
2. Run `flutter run`
3. Use emulator location tools to simulate movement
4. Test zone entry by setting location within zone coordinates

### Testing SOS
- Tap SOS button
- Verify countdown works
- Check backend receives alert at `/api/sos`
- Verify location data is accurate

### Testing Zones
- Set emulator location to danger zone (e.g., 20.0112, 73.7909)
- Verify danger alert appears with 3 vibrations
- Move to caution zone and verify warning alert
- Check approach warnings at 500m buffer

## Backend Configuration

### Required Endpoints

**POST /api/sos**
```json
{
  "userId": "string",
  "latitude": number,
  "longitude": number,
  "accuracy": number,
  "message": "string",
  "timestamp": "ISO8601 string"
}
```

**GET /api/zones?lat=X&lng=Y**
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "type": "safe|caution|danger",
      "riskLevel": "low|medium|high",
      "lat": number,
      "lng": number,
      "radius": number
    }
  ]
}
```

### Network Configuration

**For Emulator**: Use `http://10.0.2.2:3000` (routes to host machine's localhost)

**For Physical Device**: 
1. Find your computer's IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
2. Use `http://YOUR_IP:3000`
3. Ensure device and computer are on same network

## Troubleshooting

### Location Not Working
- Check location permissions in Android settings
- Ensure GPS is enabled on watch
- Try restarting location service

### SOS Not Sending
- Verify backend URL in settings
- Check network connectivity
- Ensure backend is running
- Check backend logs for errors

### Zone Alerts Not Appearing
- Verify location permissions
- Check if zones loaded (see logs)
- Ensure you're within zone radius
- Wait 15 minutes if recently alerted

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

## Permissions

The app requires:
- **Location**: For GPS tracking and geofencing
- **Internet**: For backend API communication
- **Vibration**: For alert notifications
- **Background Location**: For continuous zone monitoring

## Future Enhancements

- [ ] Complications for quick SOS access
- [ ] Emergency contact configuration
- [ ] Battery optimization modes
- [ ] Offline SOS queue
- [ ] Voice activation
- [ ] Health sensor integration
- [ ] Custom zone creation

## License

Copyright © 2024 TourGuard. All rights reserved.

## Support

For issues or questions, please contact the TourGuard development team.
