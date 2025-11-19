// Node.js Backend Setup - Copy this to your backend project
// File: server.js

const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const redis = require('redis');
const cors = require('cors');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIO(server, { cors: { origin: '*' } });
const redisClient = redis.createClient();

// Middleware
app.use(cors());
app.use(express.json());

// Connect to Redis
redisClient.connect()
  .then(() => console.log('Redis connected'))
  .catch(console.error);

// =================== REST API ENDPOINTS ===================

// 1. GET Nearby Zones - With Redis Caching
app.get('/api/zones', async (req, res) => {
  try {
    const { lat, lng } = req.query;
    const cacheKey = `zones_${lat}_${lng}`;

    // Check cache
    const cached = await redisClient.get(cacheKey);
    if (cached) {
      return res.json({ source: 'redis', data: JSON.parse(cached) });
    }

    // Simulated data (replace with DB query)
    const zones = [
      { id: 1, name: 'Tourist Zone', distance: '0.2 km', status: 'SAFE', icon: '🏛️' },
      { id: 2, name: 'Market Area', distance: '0.5 km', status: 'CAUTION', icon: '🏪' },
      { id: 3, name: 'Remote Forest', distance: '2.1 km', status: 'DANGER', icon: '🌲' },
    ];

    // Cache for 5 minutes
    await redisClient.setEx(cacheKey, 300, JSON.stringify(zones));

    res.json({ source: 'database', data: zones });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 2. GET Alerts
app.get('/api/alerts', async (req, res) => {
  try {
    const cacheKey = 'alerts';

    const cached = await redisClient.get(cacheKey);
    if (cached) {
      return res.json({ source: 'redis', data: JSON.parse(cached) });
    }

    const alerts = [
      {
        id: 1,
        title: 'Zone Alert',
        type: 'Warning',
        message: 'Approaching caution zone - Market Area',
        time: '2 min ago',
        color: 'orange',
      },
      {
        id: 2,
        title: 'Security Alert',
        type: 'Danger',
        message: 'Avoid remote forest area - increased risk level',
        time: '1 hour ago',
        color: 'red',
      },
      {
        id: 3,
        title: 'Weather Update',
        type: 'Info',
        message: 'Heavy rainfall expected in 1 hour',
        time: '15 min ago',
        color: 'blue',
      },
    ];

    // Cache for 1 minute
    await redisClient.setEx(cacheKey, 60, JSON.stringify(alerts));

    res.json({ source: 'database', data: alerts });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 3. GET Safety Score
app.get('/api/safety-score', async (req, res) => {
  try {
    const cacheKey = 'safety_score';

    const cached = await redisClient.get(cacheKey);
    if (cached) {
      return res.json({ source: 'redis', data: JSON.parse(cached) });
    }

    const safetyScore = {
      score: 87,
      maxScore: 100,
      currentZone: 'SAFE',
      time: '17:15 PM',
      crowdDensity: 'MEDIUM',
      weather: 'Clear',
    };

    // Cache for 5 minutes
    await redisClient.setEx(cacheKey, 300, JSON.stringify(safetyScore));

    res.set('Cache-Control', 'public, max-age=300');
    res.set('ETag', 'safety-score-v1');

    res.json({ source: 'database', data: safetyScore });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 4. GET User Profile
app.get('/api/profile', async (req, res) => {
  try {
    const profile = {
      id: 'TID-2025-001234',
      name: 'Rajesh Kumar',
      email: 'rajesh@example.com',
      phone: '+91 98765 43210',
      country: 'India',
      memberSince: 'January 2025',
      avatar: 'https://i.pravatar.cc/150?u=rajeshkumar',
    };

    res.json(profile);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 5. GET Places/Explore
app.get('/api/places', async (req, res) => {
  try {
    const cacheKey = 'places';

    const cached = await redisClient.get(cacheKey);
    if (cached) {
      return res.json({ source: 'redis', data: JSON.parse(cached) });
    }

    const places = [
      {
        id: '1',
        name: 'Sula Vineyards',
        description: 'India\'s most popular winery',
        category: 'famous',
        distance: '8 km',
        rating: 4.5,
      },
      {
        id: '2',
        name: 'Sadhana Restaurant',
        description: 'Authentic Misal Pav',
        category: 'food',
        distance: '5 km',
        rating: 4.3,
      },
      {
        id: '3',
        name: 'Zonkers Adventure Park',
        description: 'Thrilling activities',
        category: 'adventure',
        distance: '9 km',
        rating: 4.2,
      },
    ];

    // Cache for 10 minutes
    await redisClient.setEx(cacheKey, 600, JSON.stringify(places));

    res.json({ source: 'database', data: places });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 6. GET Emergency Services
app.get('/api/emergency-services', async (req, res) => {
  try {
    const services = [
      { id: 1, name: 'Police', phone: '100', icon: '🚨', color: 'blue' },
      { id: 2, name: 'Ambulance', phone: '102', icon: '🚑', color: 'green' },
      { id: 3, name: 'Fire Department', phone: '101', icon: '🔥', color: 'orange' },
      { id: 4, name: 'Local Police Station', phone: '+91 2560 234567', icon: '👮', color: 'indigo' },
    ];

    res.json(services);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 7. POST Report Incident
app.post('/api/incidents/report', async (req, res) => {
  try {
    const { title, description, location, type } = req.body;

    const incident = {
      id: Math.random().toString(36).substr(2, 9),
      title,
      description,
      location,
      type,
      timestamp: new Date(),
      status: 'reported',
    };

    // Save to database (simulated)
    console.log('Incident reported:', incident);

    // Clear cache
    await redisClient.del('alerts');

    res.status(201).json({ success: true, data: incident });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 8. POST Send SOS
app.post('/api/sos/send', async (req, res) => {
  try {
    const { location, message } = req.body;

    const sos = {
      id: Math.random().toString(36).substr(2, 9),
      location,
      message,
      timestamp: new Date(),
      status: 'sent',
    };

    console.log('SOS sent:', sos);

    res.status(201).json({ success: true, data: sos });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// =================== WEBSOCKET (REAL-TIME) ===================

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Chat message
  socket.on('chatMessage', (message) => {
    console.log('Chat message:', message);
    io.emit('chatMessage', message); // broadcast to all
  });

  // Live location update
  socket.on('locationUpdate', (location) => {
    console.log('Location update:', location);
    io.emit('locationUpdate', location); // broadcast to all
  });

  // Disconnect
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// =================== START SERVER ===================

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
