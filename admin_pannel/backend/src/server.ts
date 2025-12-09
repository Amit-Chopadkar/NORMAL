import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { Server } from 'socket.io';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import sosRoutes from './routes/sos.routes';
import incidentsRoutes from './routes/incidents.routes';
import zonesRoutes from './routes/zones.routes';
import aiRoutes from './routes/ai.routes';
import db from './database/db';

dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:5173',
    methods: ['GET', 'POST'],
  },
});

const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes
app.use(authRoutes);
app.use(userRoutes);
app.use(sosRoutes);
app.use(incidentsRoutes);
app.use(zonesRoutes);
app.use(aiRoutes);  // AI-powered features

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('✅ Admin client connected:', socket.id);

  socket.on('disconnect', () => {
    console.log('❌ Admin client disconnected:', socket.id);
  });

  // Join admin room for real-time updates
  socket.join('admin');
});

// Function to emit new SOS event to admin clients
export function emitNewSOSEvent(sosEvent: any) {
  io.to('admin').emit('sos:new', sosEvent);
}

// Function to emit SOS update to admin clients
export function emitSOSUpdate(sosEvent: any) {
  io.to('admin').emit('sos:update', sosEvent);
}

// Start server
httpServer.listen(PORT, () => {
  console.log('\n🚀 TourGuard Admin Panel Backend Running');
  console.log(`📍 Port: ${PORT}`);
  console.log(`🌐 API: http://localhost:${PORT}`);
  console.log(`📊 Database: Connected to SQLite`);
  console.log(`⏰ Started at: ${new Date().toLocaleString()}\n`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing database...');
  db.close();
  httpServer.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

export default app;


