# Tourist Safety Hub - Setup Guide

## 🚀 Backend Setup (Node.js)

### 1. Create Backend Project

```bash
mkdir tourguard-backend
cd tourguard-backend
npm init -y
```

### 2. Install Dependencies

```bash
npm install express socket.io redis cors dotenv
npm install --save-dev nodemon
```

### 3. Setup package.json

```json
{
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  }
}
```

### 4. Copy server.js

Copy the content from `BACKEND_SETUP.js` to your `server.js`

### 5. Create .env

```
PORT=3000
NODE_ENV=development
```

### 6. Start Redis (Windows)

Download from: https://github.com/microsoftarchive/redis/releases

Or use Docker:
```bash
docker run -d -p 6379:6379 redis
```

### 7. Start Server

```bash
npm run dev
```

---

## 📱 Flutter Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Update pubspec.yaml (Already done)

```yaml
hive: ^2.2.3
hive_flutter: ^1.1.0
http: ^1.1.0
socket_io_client: ^2.0.0
```

### 3. Update API Endpoint

In `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:3000/api';
```

### 4. Update Chat Service

In `lib/services/chat_service.dart`:

```dart
socket = IO.io('http://YOUR_SERVER_IP:3000', {
  'transports': ['websocket'],
  'autoConnect': false,
});
```

---

## 🎯 How Caching Works

### 1. REST API Caching (Analytics, Reports)

- **Where**: Redis server (1-5 min cache)
- **Why**: Heavy queries, multiple requests
- **Example**: Safety score, alerts, places list

### 2. Local Caching (Offline Support)

- **Where**: Hive on device
- **Why**: Offline access, instant loading
- **Example**: Chat history, user profile, past alerts

### 3. Real-Time Data (No Caching)

- **Where**: WebSocket (Socket.io)
- **Why**: Live updates needed
- **Example**: Chat messages, location updates

---

## 📊 API Endpoints

### GET Endpoints (Cached)

- `GET /api/zones?lat=20&lng=73` - Nearby zones (5 min cache)
- `GET /api/alerts` - Active alerts (1 min cache)
- `GET /api/safety-score` - Safety score (5 min cache)
- `GET /api/profile` - User profile
- `GET /api/places` - Explore places (10 min cache)
- `GET /api/emergency-services` - Emergency contacts

### POST Endpoints (Real-time)

- `POST /api/incidents/report` - Report incident
- `POST /api/sos/send` - Send SOS alert

### WebSocket Events (Real-time)

- `chatMessage` - Send/receive messages
- `locationUpdate` - Share live location

---

## ✨ Features Implemented

✅ **Offline-First Architecture**
- Local cache with Hive
- Auto-sync when online

✅ **Server-Side Caching**
- Redis cache-aside pattern
- 1-10 min TTL per endpoint

✅ **Real-Time Chat & Location**
- Socket.io WebSocket
- No server caching (live)

✅ **HTTP Caching**
- ETag + Cache-Control headers
- Browser cache optimization

✅ **All 5 App Sections**
- Dashboard with safety score
- Profile with contacts
- Explore places
- Emergency SOS
- Settings

---

## 🔧 Configuration

### Change Cache Duration

**api_service.dart**:
```dart
await box.put(cacheKey, data); // local cache
```

**server.js**:
```js
await redisClient.setEx(cacheKey, 300, JSON.stringify(data)); // 300 = 5 min
```

### Change API Server

Update in both:
- `lib/services/api_service.dart` - baseUrl
- `lib/services/chat_service.dart` - socket URL

---

## 🚨 Troubleshooting

### Redis Connection Error
```
Solution: Make sure Redis is running on port 6379
```

### API Not Responding
```
Solution: Check baseUrl matches your server IP/port
```

### WebSocket Connection Failed
```
Solution: Ensure server is running and socket URL is correct
```

### Hive Box Already Open
```
Solution: Close app completely and restart
```

---

## 📈 Next Steps

1. ✅ Deploy Node.js backend
2. ✅ Configure database (PostgreSQL/MongoDB)
3. ✅ Add authentication (JWT)
4. ✅ Setup error logging
5. ✅ Add push notifications
6. ✅ Deploy Flutter app to stores

---

## 💡 Best Practices

1. **Always check cache first** - Reduces API calls
2. **Use WebSocket for real-time** - No caching
3. **Clear cache on logout** - Security
4. **Monitor Redis memory** - Set eviction policies
5. **Use ETags** - Browser cache optimization

