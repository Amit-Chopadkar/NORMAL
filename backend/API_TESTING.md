# API Testing Examples

This document provides example JSON payloads for testing all API endpoints.

## User Registration

**Endpoint:** `POST /api/user/register`

```json
{
  "name": "John Doe",
  "email": "john.doe@example.com",
  "phone": "+1234567890",
  "password": "securePassword123"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

## User Login

**Endpoint:** `POST /api/user/login`

**Option 1 - Using Email:**
```json
{
  "email": "john.doe@example.com",
  "password": "securePassword123"
}
```

**Option 2 - Using Phone:**
```json
{
  "phone": "+1234567890",
  "password": "securePassword123"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

## Update Location

**Endpoint:** `POST /api/user/update-location`  
**Authorization:** Required (Bearer Token)

```json
{
  "lat": 28.6139,
  "lng": 77.2090
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Location updated successfully",
  "data": {
    "location": {
      "lat": 28.6139,
      "lng": 77.2090,
      "timestamp": "2024-01-15T10:30:00.000Z"
    }
  }
}
```

---

## Log Activity

**Endpoint:** `POST /api/user/activity`  
**Authorization:** Required (Bearer Token)

```json
{
  "action": "opened_app",
  "metadata": {
    "device": "Android",
    "version": "1.0.0"
  }
}
```

**Valid Actions:**
- `location_update`
- `panic_button`
- `opened_app`
- `closed_app`
- `sos_alert`
- `danger_zone_entry`
- `login`
- `logout`

**Expected Response:**
```json
{
  "success": true,
  "message": "Activity logged successfully",
  "data": {
    "activityLog": {
      "_id": "507f1f77bcf86cd799439012",
      "userId": "507f1f77bcf86cd799439011",
      "action": "opened_app",
      "timestamp": "2024-01-15T10:30:00.000Z",
      "metadata": {
        "device": "Android",
        "version": "1.0.0"
      }
    }
  }
}
```

---

## Create Alert

**Endpoint:** `POST /api/user/alert`  
**Authorization:** Required (Bearer Token)

**Panic Alert:**
```json
{
  "alertType": "panic",
  "lat": 28.6139,
  "lng": 77.2090,
  "message": "I need immediate help!"
}
```

**SOS Alert:**
```json
{
  "alertType": "sos",
  "lat": 28.6139,
  "lng": 77.2090,
  "message": "Emergency situation"
}
```

**Danger Zone Entry:**
```json
{
  "alertType": "danger_zone_entry",
  "lat": 28.6139,
  "lng": 77.2090,
  "message": "Entered restricted area"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Alert created successfully",
  "data": {
    "alert": {
      "_id": "507f1f77bcf86cd799439013",
      "userId": "507f1f77bcf86cd799439011",
      "location": {
        "lat": 28.6139,
        "lng": 77.2090
      },
      "alertType": "panic",
      "message": "I need immediate help!",
      "status": "pending",
      "timestamp": "2024-01-15T10:30:00.000Z"
    }
  }
}
```

---

## Admin - Get All Users

**Endpoint:** `GET /api/admin/users`  
**Authorization:** Required (Bearer Token)

**Expected Response:**
```json
{
  "success": true,
  "message": "Users retrieved successfully",
  "data": {
    "users": [
      {
        "_id": "507f1f77bcf86cd799439011",
        "name": "John Doe",
        "email": "john.doe@example.com",
        "phone": "+1234567890",
        "lastLocation": {
          "lat": 28.6139,
          "lng": 77.2090,
          "timestamp": "2024-01-15T10:30:00.000Z"
        },
        "createdAt": "2024-01-15T08:00:00.000Z"
      }
    ],
    "count": 1
  }
}
```

---

## Admin - Get User by ID

**Endpoint:** `GET /api/admin/user/:id`  
**Authorization:** Required (Bearer Token)

**Expected Response:**
```json
{
  "success": true,
  "message": "User retrieved successfully",
  "data": {
    "user": {
      "_id": "507f1f77bcf86cd799439011",
      "name": "John Doe",
      "email": "john.doe@example.com",
      "phone": "+1234567890",
      "lastLocation": {
        "lat": 28.6139,
        "lng": 77.2090,
        "timestamp": "2024-01-15T10:30:00.000Z"
      },
      "activityLogs": [...],
      "createdAt": "2024-01-15T08:00:00.000Z"
    }
  }
}
```

---

## Admin - Get User Activity

**Endpoint:** `GET /api/admin/user/:id/activity?page=1&limit=100`  
**Authorization:** Required (Bearer Token)

**Query Parameters:**
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 100)

**Expected Response:**
```json
{
  "success": true,
  "message": "User activity retrieved successfully",
  "data": {
    "activityLogs": [
      {
        "_id": "507f1f77bcf86cd799439012",
        "userId": "507f1f77bcf86cd799439011",
        "action": "location_update",
        "timestamp": "2024-01-15T10:30:00.000Z",
        "metadata": {
          "lat": 28.6139,
          "lng": 77.2090
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 100,
      "total": 1,
      "pages": 1
    }
  }
}
```

---

## Admin - Get All Alerts

**Endpoint:** `GET /api/admin/alerts?status=pending&alertType=panic&page=1&limit=100`  
**Authorization:** Required (Bearer Token)

**Query Parameters:**
- `status` - Filter by status (pending, viewed, resolved)
- `alertType` - Filter by type (panic, sos, danger_zone_entry)
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 100)

**Expected Response:**
```json
{
  "success": true,
  "message": "Alerts retrieved successfully",
  "data": {
    "alerts": [
      {
        "_id": "507f1f77bcf86cd799439013",
        "userId": {
          "_id": "507f1f77bcf86cd799439011",
          "name": "John Doe",
          "email": "john.doe@example.com",
          "phone": "+1234567890"
        },
        "location": {
          "lat": 28.6139,
          "lng": 77.2090
        },
        "alertType": "panic",
        "message": "I need immediate help!",
        "status": "pending",
        "timestamp": "2024-01-15T10:30:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 100,
      "total": 1,
      "pages": 1
    }
  }
}
```

---

## Admin - Get Live Locations

**Endpoint:** `GET /api/admin/live-locations`  
**Authorization:** Required (Bearer Token)

**Expected Response:**
```json
{
  "success": true,
  "message": "Live locations retrieved successfully",
  "data": {
    "locations": [
      {
        "userId": "507f1f77bcf86cd799439011",
        "name": "John Doe",
        "email": "john.doe@example.com",
        "phone": "+1234567890",
        "location": {
          "lat": 28.6139,
          "lng": 77.2090,
          "timestamp": "2024-01-15T10:30:00.000Z"
        }
      }
    ],
    "count": 1
  }
}
```

---

## Admin - Update Alert Status

**Endpoint:** `PATCH /api/admin/alert/:id/status`  
**Authorization:** Required (Bearer Token)

```json
{
  "status": "viewed"
}
```

**Valid Status Values:**
- `pending`
- `viewed`
- `resolved`

**Expected Response:**
```json
{
  "success": true,
  "message": "Alert status updated successfully",
  "data": {
    "alert": {
      "_id": "507f1f77bcf86cd799439013",
      "userId": {
        "_id": "507f1f77bcf86cd799439011",
        "name": "John Doe",
        "email": "john.doe@example.com",
        "phone": "+1234567890"
      },
      "location": {
        "lat": 28.6139,
        "lng": 77.2090
      },
      "alertType": "panic",
      "message": "I need immediate help!",
      "status": "viewed",
      "timestamp": "2024-01-15T10:30:00.000Z"
    }
  }
}
```

---

## Error Response Format

All errors follow this format:

```json
{
  "success": false,
  "message": "Error message",
  "errors": ["Additional error details"]
}
```

**Example - Validation Error:**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": ["Email is required", "Password must be at least 6 characters"]
}
```

**Example - Authentication Error:**
```json
{
  "success": false,
  "message": "No token provided. Access denied."
}
```

---

## Socket.IO Testing

### Connect to Socket.IO Server

```javascript
const io = require('socket.io-client');
const socket = io('http://localhost:5000');

// Join admin room
socket.emit('join-admin');

// Listen for live location updates
socket.on('live-location', (data) => {
  console.log('Live location update:', data);
});

// Listen for new alerts
socket.on('new-alert', (data) => {
  console.log('New alert:', data);
});
```

---

## Postman Collection

You can import these endpoints into Postman:

1. Create a new collection: "TourGuard API"
2. Add environment variables:
   - `base_url`: `http://localhost:5000`
   - `token`: (will be set after login)
3. Create requests for each endpoint
4. Use "Tests" tab to automatically save token after login:

```javascript
if (pm.response.code === 200) {
    const jsonData = pm.response.json();
    if (jsonData.data && jsonData.data.token) {
        pm.environment.set("token", jsonData.data.token);
    }
}
```



