# Quick Start Guide - Testing on Redmi K50i

## Device Info
- **Model**: Redmi K50i
- **Serial**: WWTOZTMVC67TAMKN
- **Android**: 13 (API 33)
- **Status**: Connected & ready

## Build & Run Commands

### Option 1: Direct Run on Device (Fastest)
```powershell
cd d:\projects\tourAPP
flutter run -d WWTOZTMVC67TAMKN
```

### Option 2: Build APK for Installation
```powershell
cd d:\projects\tourAPP
flutter build apk
# APK will be at: build\app\outputs\apk\release\app-release.apk
```

### Option 3: Install APK on Device
```powershell
cd d:\projects\tourAPP
adb -s WWTOZTMVC67TAMKN install build\app\outputs\apk\release\app-release.apk
```

## Pre-Test Checklist

✅ **Code Compilation**
- No errors found
- All dependencies installed
- Desugaring configured for Java 8 APIs

✅ **Services Initialized**
- Firebase Auth
- Location & Notification permissions
- Chat service (Socket.io)
- Hive local storage

✅ **Features Ready**
- Authentication (signup/login with blockchain ID)
- Emergency SOS with location broadcast
- Chatbot with e-FIR & incident buttons
- Admin dashboard (if marked as admin)
- Maps integration
- Heatmap visualization service

## Testing Scenarios

### 1. First Run (Create Test Account)
1. **Launch app** → AuthScreen
2. **Tap "Sign Up"**
3. **Enter credentials**:
   - Name: "Test User"
   - Email: "test@example.com"
   - Password: "password123"
   - Phone: "+919876543210"
4. **Tap Sign Up** → Generates blockchain ID
5. **Redirects to DashboardScreen**

### 2. Emergency SOS Test
1. **Tap Emergency tab** (bottom nav)
2. **Tap large red SOS button**
3. **Grant location permission** (popup)
4. **Button animates to orange** (sending state)
5. **Notification appears**: "SOS Alert sent to authorities"
6. **Button returns to normal** (sent)

### 3. Emergency Phone Calls
1. **On Emergency screen**
2. **Tap call icon** on any emergency contact (Police 100, Ambulance 102, etc.)
3. **Native phone dialer opens** with number
4. **Tap to call** (if network available)

### 4. Explore Section with Chatbot
1. **Tap Explore tab** (bottom nav)
2. **See places list** (Sula Vineyards, Sadhana Restaurant, etc.)
3. **Tap blue chat FAB** (bottom-right)
4. **Chatbot interface appears**
5. **Try buttons**: "Generate e-FIR", "Report Incident"
6. **Type message**: "safe place" or "incident"
7. **Bot responds** with recommendations

### 5. Incident Report Map
1. **From Dashboard, find incident report button**
   - Or Emergency tab → "Report Incident"
2. **Map appears for location selection**
3. **Tap on map** to set incident location
4. **Fill form**: Title, Category, Urgency
5. **Submit** → Saves locally + attempts backend POST

### 6. Admin Dashboard (If Admin)
1. **Logout** from current account
2. **Create admin account**:
   - Manually set `isAdmin: true` in Firestore user doc
   - Or use admin claim
3. **Login with admin account** → AdminDashboardScreen loads
4. **See live metrics**: SOS alerts, incidents, active users
5. **Interactive map** shows markers
6. **SOS alerts table** with respond buttons
7. **Incidents list** by severity

### 7. Settings & Family Tracking
1. **Tap Settings tab** (bottom nav)
2. **Toggle "Enable Family Tracking"**
3. **Select emergency contacts**
4. **Choose language** (English/Hindi/Spanish)
5. **Save** → Location broadcasts every 15 seconds via Socket.io

### 8. Chatbot in Dashboard
1. **Dashboard screen** (home tab)
2. **Look for chat overlay or widget**
3. **Send messages** about locations, safety, etc.
4. **Test e-FIR generation**:
   - Tap "Generate e-FIR"
   - Enter person name, description
   - Submit → e-FIR ID displayed

## Common Issues & Fixes

### Issue: "gradle build failed"
**Solution**: Already fixed in build.gradle.kts (desugaring enabled)
```
coreLibraryDesugaring = true
```

### Issue: "Permission denied"
**Solution**: App requests on startup
- Allow Location (Fine + Coarse)
- Allow Notifications
- Check: Settings > Apps > Permissions

### Issue: "SOS not working"
**Solution**: 
1. Check GPS is on
2. Check location permission granted
3. Check "Enable Location Sharing" in Settings
4. Ensure backend server running (if API endpoint needed)

### Issue: "Emergency numbers not calling"
**Solution**: Check phone carrier supports tel: protocol
- Alternative: Check dial logs in phone app

### Issue: "Map shows blank"
**Solution**: 
1. API key may need configuration
2. Check internet connection
3. Wait for map controller to initialize

## Performance Tips

✅ **Optimize**:
- Heatmap circles only show if >3 incidents in area
- Maps lazy-load incident markers
- Chat messages cached locally
- Notifications batched via Redis

⚠️ **Note**: Backend API calls will fail locally without:
- Node.js server running
- MongoDB setup
- Firebase Firestore connected
- Socket.io server configured

## Deployment Checklist

Before production release:
- [ ] Backend server deployed (change localhost to server IP)
- [ ] Firebase project configured with Firestore
- [ ] Google Maps API key added to AndroidManifest.xml
- [ ] Push notifications configured (Firebase Cloud Messaging)
- [ ] Admin users created in Firestore
- [ ] Emergency contact verification
- [ ] Blockchain wallet setup for digital IDs
- [ ] Security: Firebase Auth + custom claims + role verification
- [ ] Testing: All emergency numbers verified
- [ ] Testing: Map tiles loaded correctly
- [ ] Testing: Permissions flows on Android 11+
- [ ] Testing: SQLite database backup
- [ ] App signing certificate generated

## File Changes This Session

### New Screens
- `lib/screens/admin_dashboard_screen.dart` (200 lines)
- `lib/screens/auth_screen.dart` (existing, enhanced)

### New Widgets
- `lib/widgets/chatbot_widget_v2.dart` (130 lines)

### New Services
- `lib/services/heatmap_service.dart` (90 lines)

### Updated Core
- `lib/main.dart` (role-based routing)
- `lib/screens/emergency_screen.dart` (tel: dialers + SOS)
- `lib/screens/dashboard_screen.dart` (SafeArea)
- `lib/screens/explore_screen.dart` (chatbot FAB)

## Build Metrics

| Metric | Value |
|--------|-------|
| Dart Files | 25+ |
| Lines of Code | 3000+ |
| Dependencies | 20+ packages |
| APK Size | ~50 MB (debug) |
| Build Time | ~60 seconds |

## Support

For quick debugging:
```powershell
# View device logs
adb -s WWTOZTMVC67TAMKN logcat | findstr "flutter|error|exception"

# Record device screen
adb -s WWTOZTMVC67TAMKN shell screenrecord /sdcard/recording.mp4

# Copy from device
adb -s WWTOZTMVC67TAMKN pull /sdcard/recording.mp4 C:\

# Check connected devices
flutter devices
```

---

**Ready to test?** Run: `flutter run -d WWTOZTMVC67TAMKN`
