# TourGuard Backend API

Complete backend REST API for TourGuard Tourist Safety Application with real-time features using Socket.IO.

## Architecture

```
Android User App → Backend REST API → MongoDB Database → Admin Panel
```

## Tech Stack

- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MongoDB / Mongoose** - Database and ODM
- **JWT** - Authentication
- **bcrypt** - Password hashing
- **Socket.IO** - Real-time communication
- **CORS** - Cross-origin resource sharing
- **dotenv** - Environment configuration

## Project Structure

```
backend/
  src/
    config/
      db.js              # MongoDB connection
    models/
      User.js            # User schema
      ActivityLog.js     # Activity log schema
      Alert.js           # Alert schema
    controllers/
      userController.js  # User endpoints
      adminController.js # Admin endpoints
      alertController.js # Alert management
    routes/
      userRoutes.js      # User routes
      adminRoutes.js     # Admin routes
      alertRoutes.js     # Alert routes
    middleware/
      auth.js            # JWT authentication middleware
    utils/
      response.js        # Standardized response utility
    server.js            # Main server file
```

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Environment Configuration

Copy `.env.example` to `.env` and fill in your configuration:

```bash
cp .env.example .env
```

Edit `.env` with your MongoDB connection string and JWT secret:

```env
MONGO_URI=mongodb://localhost:27017/tourguard
JWT_SECRET=your-super-secret-jwt-key
PORT=5000
```

### 3. Start MongoDB

Make sure MongoDB is running on your system:

```bash
# Using MongoDB locally
mongod

# Or use MongoDB Atlas (cloud)
# Update MONGO_URI in .env with your Atlas connection string
```

### 4. Run the Server

**Development mode (with auto-reload):**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

Server will start on `http://localhost:5000` (or your configured PORT).

## API Endpoints

### User App Endpoints

#### Register User
```http
POST /api/user/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "password123"
}
```

#### Login User
```http
POST /api/user/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

#### Update Location
```http
POST /api/user/update-location
Authorization: Bearer <token>
Content-Type: application/json

{
  "lat": 28.6139,
  "lng": 77.2090
}
```

#### Log Activity
```http
POST /api/user/activity
Authorization: Bearer <token>
Content-Type: application/json

{
  "action": "opened_app",
  "metadata": {}
}
```

#### Create Alert
```http
POST /api/user/alert
Authorization: Bearer <token>
Content-Type: application/json

{
  "alertType": "panic",
  "lat": 28.6139,
  "lng": 77.2090,
  "message": "Emergency situation"
}
```

### Admin Panel Endpoints

All admin endpoints require authentication token.

#### Get All Users
```http
GET /api/admin/users
Authorization: Bearer <token>
```

#### Get User by ID
```http
GET /api/admin/user/:id
Authorization: Bearer <token>
```

#### Get User Activity History
```http
GET /api/admin/user/:id/activity?page=1&limit=100
Authorization: Bearer <token>
```

#### Get All Alerts
```http
GET /api/admin/alerts?status=pending&page=1&limit=100
Authorization: Bearer <token>
```

#### Get Live Locations
```http
GET /api/admin/live-locations
Authorization: Bearer <token>
```

#### Update Alert Status
```http
PATCH /api/admin/alert/:id/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "viewed"
}
```

## Socket.IO Real-Time Events

### Client → Server Events

#### Join Admin Room
```javascript
socket.emit('join-admin');
```

#### Send Location Update
```javascript
socket.emit('location-update', {
  userId: 'user_id',
  lat: 28.6139,
  lng: 77.2090
});
```

### Server → Client Events

#### Live Location Update
```javascript
socket.on('live-location', (data) => {
  // data: { userId, name, email, phone, location: { lat, lng, timestamp } }
});
```

#### New Alert
```javascript
socket.on('new-alert', (data) => {
  // data: { alert: { _id, userId, user, location, alertType, message, status, timestamp } }
});
```

## Database Schemas

### User Schema
- `name` - String (required)
- `email` - String (required, unique)
- `phone` - String (required, unique)
- `password` - String (required, hashed)
- `lastLocation` - Object { lat, lng, timestamp }
- `activityLogs` - Array of activity objects
- `createdAt` - Date

### ActivityLog Schema
- `userId` - ObjectId (reference to User)
- `action` - String (enum: location_update, panic_button, opened_app, etc.)
- `timestamp` - Date
- `metadata` - Mixed type for additional data

### Alert Schema
- `userId` - ObjectId (reference to User)
- `location` - Object { lat, lng }
- `alertType` - String (enum: panic, sos, danger_zone_entry)
- `timestamp` - Date
- `status` - String (enum: pending, viewed, resolved)
- `message` - String

## Security Features

- Password hashing with bcrypt
- JWT token authentication
- Input validation
- Protected routes with middleware
- CORS enabled
- Error handling

## Testing the API

### Using cURL

**Register:**
```bash
curl -X POST http://localhost:5000/api/user/register \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","phone":"+1234567890","password":"password123"}'
```

**Login:**
```bash
curl -X POST http://localhost:5000/api/user/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}'
```

**Update Location (with token):**
```bash
curl -X POST http://localhost:5000/api/user/update-location \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"lat":28.6139,"lng":77.2090}'
```

### Using Postman

Import the API endpoints and test with Postman. Remember to:
1. Save the token from login/register response
2. Use it in Authorization header as `Bearer <token>`

## Health Check

```http
GET /health
```

Returns server status and timestamp.

## Error Handling

All errors follow a consistent format:

```json
{
  "success": false,
  "message": "Error message",
  "errors": ["Additional error details"]
}
```

## License

ISC



