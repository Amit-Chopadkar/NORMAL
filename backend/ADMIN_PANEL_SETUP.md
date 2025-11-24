# Admin Panel Setup Guide

## Overview

The TourGuard Admin Panel is a web-based dashboard that provides real-time monitoring of user locations, alerts, and emergency situations.

## Features

- **Live Incident Map**: Real-time map showing user locations
- **User Information**: Display user details and emergency contacts
- **Nearby Resources**: List of emergency services and dispatch options
- **Communication Log**: Real-time log of all events and actions
- **Alert Management**: View and resolve alerts
- **Real-time Updates**: Socket.IO integration for live updates

## Setup Instructions

### 1. Start the Backend Server

```bash
cd backend
npm install
npm start
```

The server will start on `http://localhost:5000`

### 2. Access the Admin Panel

Open your web browser and navigate to:
```
http://localhost:5000
```

### 3. Login

Use an admin user account to login:
- Email: (any registered user email)
- Password: (user's password)

**Note**: Currently, any authenticated user can access admin endpoints. For production, you should add role-based access control.

### 4. Google Maps API Key (Optional)

To use the map feature, you need a Google Maps API key:

1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Edit `backend/public/index.html`
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY&libraries=places"></script>
```

## Usage

### Viewing Live Locations

- Users' locations are automatically updated on the map when they move
- Locations update every 10 seconds via polling
- Real-time updates via Socket.IO when users send location updates

### Handling Alerts

1. When a user sends an SOS/panic alert, it appears on the dashboard
2. The map centers on the user's location
3. User information is displayed in the left panel
4. Use action buttons to:
   - **Broadcast Alert**: Send alert to all emergency services
   - **Manual Dispatch**: Manually dispatch resources
   - **Resolve Incident**: Mark the incident as resolved

### Communication Log

All events are logged in real-time:
- Location updates
- Alert activations
- Dispatch actions
- System messages

## API Integration

The admin panel uses the following endpoints:

- `GET /api/admin/users` - Get all users
- `GET /api/admin/user/:id` - Get user details
- `GET /api/admin/user/:id/activity` - Get user activity
- `GET /api/admin/alerts` - Get all alerts
- `GET /api/admin/live-locations` - Get live locations
- `PATCH /api/admin/alert/:id/status` - Update alert status

## Socket.IO Events

### Receiving Events

- `live-location` - Real-time location updates from users
- `new-alert` - New alert notifications

### Sending Events

- `join-admin` - Join the admin room to receive updates

## Customization

### Styling

Edit `backend/public/styles.css` to customize the appearance.

### Functionality

Edit `backend/public/app.js` to add custom features:
- Additional resource types
- Custom dispatch workflows
- Integration with external services

## Troubleshooting

### Map Not Loading

- Check if Google Maps API key is set correctly
- Verify API key has proper permissions
- Check browser console for errors

### No Location Updates

- Verify backend server is running
- Check Socket.IO connection in browser console
- Ensure users are authenticated and sending location updates

### Login Issues

- Verify user exists in database
- Check backend logs for authentication errors
- Clear browser localStorage and try again

## Production Deployment

For production:

1. **Security**:
   - Add role-based access control
   - Use HTTPS
   - Implement proper authentication

2. **Performance**:
   - Use CDN for static files
   - Optimize Socket.IO connections
   - Implement rate limiting

3. **Monitoring**:
   - Add error tracking
   - Monitor Socket.IO connections
   - Track API usage

## Support

For issues or questions, refer to:
- `README.md` - Full API documentation
- `API_TESTING.md` - API testing examples
- `QUICK_START.md` - Quick setup guide



