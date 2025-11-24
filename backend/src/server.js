require('dotenv').config();
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const connectDB = require('./config/db');

// Import routes
const userRoutes = require('./routes/userRoutes');
const adminRoutes = require('./routes/adminRoutes');
const alertRoutes = require('./routes/alertRoutes');

// Import models for Socket.IO
const User = require('./models/User');
const Alert = require('./models/Alert');

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Initialize Socket.IO with CORS
const io = socketIo(server, {
  cors: {
    origin: '*', // Configure this based on your frontend URL
    methods: ['GET', 'POST'],
  },
});

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files (Admin Panel)
app.use(express.static('public'));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Routes
app.use('/api/user', userRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/admin', alertRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString(),
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'TourGuard Backend API',
    version: '1.0.0',
  });
});

// Admin config endpoint (returns public config for admin UI)
app.get('/admin/config', (req, res) => {
  // Prefer an explicit Maps JavaScript key if provided, otherwise fall back to places key
  const mapsKey = process.env.GOOGLE_MAPS_JS_KEY || process.env.GOOGLE_PLACES_API_KEY || '';
  res.json({ success: true, data: { mapsKey } });
});

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  // Join admin room
  socket.on('join-admin', () => {
    socket.join('admin');
    console.log(`Client ${socket.id} joined admin room`);
  });

  // Handle location updates from users
  socket.on('location-update', async (data) => {
    try {
      const { userId, lat, lng } = data;
      
      // Update user location in database
      await User.findByIdAndUpdate(userId, {
        lastLocation: {
          lat,
          lng,
          timestamp: new Date(),
        },
      });

      // Emit to admin clients
      io.to('admin').emit('live-location', {
        userId,
        location: { lat, lng, timestamp: new Date() },
      });
    } catch (error) {
      console.error('Socket location update error:', error);
    }
  });

  // Handle disconnect
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Store io instance for use in controllers
app.set('io', io);

// Middleware to attach io to request object
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

// Start server
const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`\n✅ Admin Panel: http://localhost:${PORT}`);
  console.log(`✅ Admin Panel (Network): http://10.38.111.74:${PORT}`);
  console.log(`✅ API Base URL: http://10.38.111.74:${PORT}/api`);
  console.log(`\n📱 Use IP 10.38.111.74 in Flutter app for mobile device connection\n`);
});

// Export io for use in controllers if needed
module.exports = { io };

