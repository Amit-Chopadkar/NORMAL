# Integration Guide: Flutter App ↔ Backend ↔ Admin Panel

This guide explains how the Flutter user app, backend API, and admin panel work together.

## Architecture Overview

```
┌─────────────────┐         ┌──────────────┐         ┌──────────────┐
│  Flutter App    │ ◄─────► │   Backend    │ ◄─────► │ Admin Panel  │
│  (User App)     │  HTTP   │   (Node.js)  │  HTTP   │   (Web)      │
│                 │         │              │         │              │
│  - Location     │         │  - REST API  │         │  - Dashboard │
│  - Alerts       │         │  - Socket.IO │         │  - Real-time │
│  - Activities   │         │  - MongoDB  │         │  - Maps      │
└─────────────────┘         └──────────────┘         └──────────────┘
```

## Data Flow

### 1. User Registration/Login

**Flutter App** → **Backend**
```
POST /api/user/register
POST /api/user/login
```

**Response**: JWT token stored in SharedPreferences

### 2. Location Updates

**Flutter App** → **Backend** → **Admin Panel**

1. Flutter app sends location update:
   ```dart
   BackendService.updateLocation(lat: 28.6139, lng: 77.2090)
   ```

2. Backend receives and stores:
   - Updates user's `lastLocation` in database
   - Creates activity log entry
   - Emits Socket.IO event to admin panel

3. Admin panel receives:
   - Real-time location update via Socket.IO
   - Updates map marker
   - Logs event in communication log

### 3. Alert Creation

**Flutter App** → **Backend** → **Admin Panel**

1. User presses SOS button in Flutter app
2. Flutter app sends alert:
   ```dart
   BackendService.createAlert(
     alertType: 'sos',
     lat: 28.6139,
     lng: 77.2090,
     message: 'Emergency!'
   )
   ```

3. Backend:
   - Creates alert in database
   - Creates activity log
   - Emits Socket.IO event to admin panel

4. Admin panel:
   - Receives alert notification
   - Displays user information
   - Centers map on alert location
   - Shows alert in communication log

### 4. Activity Logging

**Flutter App** → **Backend**

```dart
BackendService.logActivity(
  action: 'opened_app',
  metadata: {'device': 'Android'}
)
```

Stored in ActivityLog collection for admin review.

## Configuration

### Flutter App Configuration

**File**: `lib/services/backend_service.dart`

Update base URL for your environment:

```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:5000/api';
  }
  // For Android emulator
  return 'http://10.0.2.2:5000/api';
  // For physical device, use your computer's IP:
  // return 'http://192.168.1.XXX:5000/api';
}
```

### Backend Configuration

**File**: `backend/.env`

```env
MONGO_URI=mongodb://localhost:27017/tourguard
JWT_SECRET=your-secret-key
PORT=5000
```

### Admin Panel Configuration

**File**: `backend/public/app.js`

Socket.IO connection is automatic:
```javascript
const SOCKET_URL = window.location.origin;
socket = io(SOCKET_URL);
```

## Testing the Integration

### 1. Start Backend

```bash
cd backend
npm install
npm start
```

### 2. Open Admin Panel

Navigate to `http://localhost:5000`

### 3. Run Flutter App

```bash
flutter run
```

### 4. Test Flow

1. **Register/Login** in Flutter app
2. **Navigate** around (location updates sent automatically)
3. **Press SOS** button (alert appears in admin panel)
4. **Check admin panel** for real-time updates

## Socket.IO Events

### Flutter App → Backend

Currently, Flutter app uses HTTP REST API. Socket.IO integration can be added for real-time bidirectional communication.

### Backend → Admin Panel

**Events Emitted**:
- `live-location` - User location update
- `new-alert` - New alert notification

**Events Received**:
- `join-admin` - Admin joins monitoring room

## Authentication Flow

1. User registers/logs in via Flutter app
2. Backend returns JWT token
3. Token stored in SharedPreferences
4. All subsequent requests include token in Authorization header
5. Admin panel uses same authentication (login required)

## Error Handling

### Flutter App

- Network errors are caught and logged
- Location updates are non-blocking (fire-and-forget)
- Alerts have fallback to SMS if backend fails

### Backend

- All errors return consistent JSON format
- Validation errors include field details
- Authentication errors return 401 status

### Admin Panel

- Connection errors show in communication log
- Failed API calls logged to console
- Automatic reconnection for Socket.IO

## Security Considerations

1. **JWT Tokens**: Stored securely in SharedPreferences
2. **HTTPS**: Use in production
3. **CORS**: Configured for development, restrict in production
4. **Rate Limiting**: Add for production
5. **Input Validation**: All inputs validated on backend

## Production Checklist

- [ ] Use HTTPS for all connections
- [ ] Configure CORS properly
- [ ] Add rate limiting
- [ ] Implement role-based access control
- [ ] Add monitoring and logging
- [ ] Use environment-specific configurations
- [ ] Set up database backups
- [ ] Configure firewall rules
- [ ] Add error tracking (Sentry, etc.)
- [ ] Set up CI/CD pipeline

## Troubleshooting

### Flutter app can't connect to backend

- Check backend is running
- Verify IP address/port
- Check firewall settings
- For emulator, use `10.0.2.2`
- For physical device, use computer's IP

### Admin panel not receiving updates

- Check Socket.IO connection in browser console
- Verify backend is emitting events
- Check network tab for WebSocket connection
- Ensure admin joined the room (`join-admin` event)

### Location updates not appearing

- Verify user is authenticated
- Check backend logs for errors
- Verify location permissions in Flutter app
- Check database for stored locations

## Next Steps

1. Add Socket.IO client to Flutter app for real-time updates
2. Implement push notifications
3. Add geofencing alerts
4. Implement two-way communication
5. Add analytics and reporting



