/**
 * BACKEND API EXPANSION - Tourist Safety Hub
 * Add these endpoints to your Node.js/Express server
 * 
 * Base URL: http://localhost:3000/api
 * (Change to your server IP when deploying)
 */

// ============ NEW ENDPOINTS ============

/**
 * POST /api/sos/alert
 * Send SOS alert from user to admin dashboard
 * 
 * Request Body:
 * {
 *   "userId": "user123",
 *   "latitude": 20.0112,
 *   "longitude": 73.7909,
 *   "userName": "Rajesh Kumar",
 *   "timestamp": 1234567890
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "sosId": "SOS-2025-001",
 *   "message": "SOS broadcast to admin"
 * }
 */

/**
 * GET /api/incidents/heatmap
 * Get all incidents aggregated for heatmap visualization
 * 
 * Query Params:
 * - bounds: "lat1,lng1,lat2,lng2" (optional)
 * - filter: "high,medium,low" (optional, comma-separated risk levels)
 * 
 * Response:
 * {
 *   "success": true,
 *   "incidents": [
 *     {
 *       "id": "inc123",
 *       "latitude": 20.0112,
 *       "longitude": 73.7909,
 *       "riskLevel": "high",
 *       "category": "Suspicious Activity",
 *       "count": 3,
 *       "timestamp": 1234567890
 *     }
 *   ],
 *   "totalCount": 24
 * }
 */

/**
 * GET /api/places/recommend?lat=20.0112&lng=73.7909&radius=50
 * Get safe places recommendations within radius (km)
 * 
 * Query Params:
 * - lat: User latitude (required)
 * - lng: User longitude (required)
 * - radius: Search radius in km (default: 50)
 * - minSafetyScore: Minimum safety score 0-100 (default: 70)
 * 
 * Response:
 * {
 *   "success": true,
 *   "places": [
 *     {
 *       "id": "p1",
 *       "name": "Sula Vineyards",
 *       "latitude": 20.0150,
 *       "longitude": 73.8000,
 *       "distance": 5.2,
 *       "safetyScore": 85,
 *       "incidents": 1,
 *       "rating": 4.5,
 *       "type": "Tourist Attraction"
 *     }
 *   ],
 *   "count": 15
 * }
 */

/**
 * GET /api/admin/incidents
 * Get all incidents for admin dashboard (ADMIN ONLY)
 * 
 * Headers:
 * - Authorization: Bearer <admin-token>
 * 
 * Response:
 * {
 *   "success": true,
 *   "incidents": [
 *     {
 *       "id": "inc123",
 *       "title": "Suspicious Activity",
 *       "category": "Theft",
 *       "latitude": 20.0112,
 *       "longitude": 73.7909,
 *       "riskLevel": "high",
 *       "timestamp": 1234567890,
 *       "userId": "user123",
 *       "status": "reported"
 *     }
 *   ],
 *   "total": 24
 * }
 */

/**
 * GET /api/admin/users
 * Get all active users for monitoring (ADMIN ONLY)
 * 
 * Headers:
 * - Authorization: Bearer <admin-token>
 * 
 * Response:
 * {
 *   "success": true,
 *   "users": [
 *     {
 *       "id": "user123",
 *       "name": "Rajesh Kumar",
 *       "email": "rajesh@email.com",
 *       "lastLocation": { "latitude": 20.0112, "longitude": 73.7909 },
 *       "isTrackingEnabled": true,
 *       "lastSeen": 1234567890,
 *       "blockchainId": "0x1234..."
 *     }
 *   ],
 *   "totalOnline": 156
 * }
 */

/**
 * GET /api/admin/active-sos
 * Get all active SOS alerts (ADMIN ONLY)
 * 
 * Headers:
 * - Authorization: Bearer <admin-token>
 * 
 * Response:
 * {
 *   "success": true,
 *   "sosAlerts": [
 *     {
 *       "sosId": "SOS-2025-001",
 *       "userId": "user123",
 *       "userName": "Tourist Name",
 *       "latitude": 20.0112,
 *       "longitude": 73.7909,
 *       "timestamp": 1234567890,
 *       "status": "active",
 *       "respondedBy": null
 *     }
 *   ],
 *   "total": 3
 * }
 */

/**
 * POST /api/admin/respond-sos
 * Mark SOS as responded by admin (ADMIN ONLY)
 * 
 * Headers:
 * - Authorization: Bearer <admin-token>
 * 
 * Request Body:
 * {
 *   "sosId": "SOS-2025-001",
 *   "action": "responded",
 *   "notes": "Police dispatched"
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "message": "SOS marked as responded"
 * }
 */

/**
 * WebSocket EVENTS (Socket.io)
 * 
 * CLIENT TO SERVER:
 * 
 * 1. 'locationUpdate'
 *    Emit user location regularly
 *    Data: { userId, latitude, longitude, timestamp }
 * 
 * 2. 'incidentReport'
 *    Report a new incident
 *    Data: { userId, title, category, latitude, longitude, description }
 * 
 * 3. 'sosAlert'
 *    Send SOS alert
 *    Data: { userId, latitude, longitude, timestamp }
 * 
 * 4. 'chatMessage'
 *    Send chatbot message
 *    Data: { userId, message, timestamp }
 * 
 * SERVER TO CLIENT (BROADCAST TO ADMIN):
 * 
 * 1. 'userLocation'
 *    Real-time user location updates
 *    Data: { userId, latitude, longitude, timestamp }
 * 
 * 2. 'newIncident'
 *    New incident reported
 *    Data: { incidentId, userId, title, latitude, longitude, timestamp }
 * 
 * 3. 'sosAlert'
 *    New SOS alert
 *    Data: { sosId, userId, latitude, longitude, timestamp }
 * 
 * 4. 'alertCleared'
 *    SOS alert cleared
 *    Data: { sosId, timestamp }
 */

// ============ IMPLEMENTATION EXAMPLE (Node.js/Express) ============

/*
const express = require('express');
const app = express();
const socketIO = require('socket.io');
const redis = require('redis');

// Middleware
app.use(express.json());

// Redis client for caching
const redisClient = redis.createClient();

// ====== SOS ALERT ENDPOINT ======
app.post('/api/sos/alert', async (req, res) => {
  const { userId, latitude, longitude, userName, timestamp } = req.body;
  
  try {
    // Store in database
    const sosId = `SOS-${Date.now()}`;
    await db.collection('sosAlerts').insertOne({
      sosId,
      userId,
      latitude,
      longitude,
      userName,
      timestamp,
      status: 'active',
      respondedBy: null
    });
    
    // Cache in Redis for quick access
    await redisClient.setex(
      `sos:${sosId}`,
      3600,
      JSON.stringify({ sosId, userId, latitude, longitude, timestamp })
    );
    
    // Broadcast to all connected admin clients
    io.to('admin').emit('sosAlert', {
      sosId,
      userId,
      latitude,
      longitude,
      userName,
      timestamp
    });
    
    res.json({ success: true, sosId, message: 'SOS broadcast to admin' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ====== HEATMAP ENDPOINT ======
app.get('/api/incidents/heatmap', async (req, res) => {
  const { bounds, filter } = req.query;
  
  try {
    let query = {};
    
    // Filter by bounds if provided
    if (bounds) {
      const [lat1, lng1, lat2, lng2] = bounds.split(',').map(Number);
      query = {
        'location.latitude': { $gte: lat1, $lte: lat2 },
        'location.longitude': { $gte: lng1, $lte: lng2 }
      };
    }
    
    // Filter by risk level if provided
    if (filter) {
      const levels = filter.split(',');
      query.riskLevel = { $in: levels };
    }
    
    const incidents = await db.collection('incidents')
      .find(query)
      .toArray();
    
    res.json({
      success: true,
      incidents,
      totalCount: incidents.length
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ====== PLACES RECOMMENDATION ENDPOINT ======
app.get('/api/places/recommend', async (req, res) => {
  const { lat, lng, radius = 50, minSafetyScore = 70 } = req.query;
  
  if (!lat || !lng) {
    return res.status(400).json({ error: 'lat and lng required' });
  }
  
  try {
    const places = await db.collection('places')
      .find({
        latitude: { $gte: lat - radius/111, $lte: lat + radius/111 },
        longitude: { $gte: lng - radius/111, $lte: lng + radius/111 },
        safetyScore: { $gte: minSafetyScore }
      })
      .sort({ safetyScore: -1 })
      .limit(20)
      .toArray();
    
    res.json({
      success: true,
      places,
      count: places.length
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ====== ADMIN ENDPOINTS ======
const adminAuth = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  // Verify admin token and set req.isAdmin = true
  // TODO: Implement Firebase custom claims verification
  next();
};

app.get('/api/admin/incidents', adminAuth, async (req, res) => {
  try {
    const incidents = await db.collection('incidents')
      .find({})
      .sort({ timestamp: -1 })
      .limit(100)
      .toArray();
    
    res.json({ success: true, incidents, total: incidents.length });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/admin/users', adminAuth, async (req, res) => {
  try {
    const users = await db.collection('users')
      .find({ isTrackingEnabled: true })
      .toArray();
    
    res.json({ success: true, users, totalOnline: users.length });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/admin/active-sos', adminAuth, async (req, res) => {
  try {
    const sosAlerts = await db.collection('sosAlerts')
      .find({ status: 'active' })
      .toArray();
    
    res.json({ success: true, sosAlerts, total: sosAlerts.length });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/admin/respond-sos', adminAuth, async (req, res) => {
  const { sosId, action, notes } = req.body;
  
  try {
    await db.collection('sosAlerts').updateOne(
      { sosId },
      { $set: { status: 'responded', notes, respondedAt: new Date() } }
    );
    
    io.emit('sosResolved', { sosId });
    res.json({ success: true, message: 'SOS marked as responded' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ====== SOCKET.IO EVENT HANDLERS ======
io.on('connection', (socket) => {
  socket.on('registerAdmin', () => {
    socket.join('admin');
  });
  
  socket.on('locationUpdate', (data) => {
    // Broadcast to admin only
    io.to('admin').emit('userLocation', data);
    
    // Store in Redis for quick access
    redisClient.setex(`location:${data.userId}`, 300, JSON.stringify(data));
  });
  
  socket.on('incidentReport', (data) => {
    // Store incident
    // Broadcast to admin
    io.to('admin').emit('newIncident', data);
  });
  
  socket.on('sosAlert', (data) => {
    // Store SOS alert
    // Broadcast to admin with high priority
    io.to('admin').emit('sosAlert', data);
  });
});
*/

module.exports = {};
