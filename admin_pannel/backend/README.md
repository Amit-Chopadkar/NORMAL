# TourGuard Admin Panel Backend

Backend server for the TourGuard Admin Panel that reads data from the main TourGuard SQLite database.

## Features

- ✅ Reads from `tourguard-backend Final/database.sqlite`
- ✅ REST API endpoints for users and SOS events
- ✅ Socket.IO for real-time SOS event updates
- ✅ JWT authentication for admin access
- ✅ Maps incidents to SOS events format

## Setup

1. **Install dependencies:**
   ```bash
   cd admin_pannel/backend
   npm install
   ```

2. **Create `.env` file** (optional, defaults are provided):
   ```env
   PORT=5000
   FRONTEND_URL=http://localhost:5173
   JWT_SECRET=admin-secret-key-change-in-production
   ADMIN_EMAIL=admin@tourguard.com
   ADMIN_PASSWORD=admin123
   ```

3. **Start development server:**
   ```bash
   npm run dev
   ```

4. **Build for production:**
   ```bash
   npm run build
   npm start
   ```

## API Endpoints

### Authentication
- `POST /api/auth/login` - Admin login

### Users
- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID

### SOS Events
- `GET /api/sos` - Get all SOS events (filters: `?status=pending&since=2024-01-01`)
- `GET /api/sos/:id` - Get SOS event by ID
- `POST /api/sos` - Create SOS event (for testing)
- `PATCH /api/sos/:id` - Update SOS event status

## Socket.IO Events

- `sos:new` - Emitted when a new SOS event is created
- `sos:update` - Emitted when an SOS event status is updated

## Database Structure

The backend reads from the SQLite database at:
```
tourguard-backend Final/database.sqlite
```

**Tables used:**
- `users` - User accounts
- `incidents` - All incidents (SOS events are incidents with `title = 'SOS Alert'`)

## Default Admin Credentials

- **Email:** `admin@tourguard.com`
- **Password:** `admin123`

⚠️ **Change these in production!**


