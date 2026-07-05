import dotenv from 'dotenv';
import http from 'http';
import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';
import { Server } from 'socket.io';
import connectDB from './config/db.js';
import authRoutes from './routes/authRoutes.js';
import menuRoutes from './routes/menuRoutes.js';
import orderRoutes from './routes/orderRoutes.js';
import settingsRoutes from './routes/settingsRoutes.js';
import {
  getAllowedOrigins,
  getCorsOptions,
  isOriginAllowed,
} from './utils/corsOrigins.js';
import { socketAuthMiddleware } from './middleware/socketAuth.js';

dotenv.config();

const corsOptions = getCorsOptions();
const allowedOrigins = getAllowedOrigins();

const applyCorsHeaders = (req, res) => {
  const origin = req.headers.origin;

  if (origin && isOriginAllowed(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader('Vary', 'Origin');
  }
};

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: corsOptions,
});

// CORS before every route.
app.use(cors(corsOptions));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (_req, res) => {
  res.json({
    success: true,
    message: 'SSM SkipQ API',
    health: '/api/health',
  });
});

app.get('/api/health', (_req, res) => {
  res.json({
    success: true,
    message: 'SSM SkipQ API is running',
    timestamp: new Date().toISOString(),
    db: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/menu', menuRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/settings', settingsRoutes);

app.set('io', io);

io.use(socketAuthMiddleware);

io.on('connection', (socket) => {
  const { user } = socket.data;
  console.log(`Socket connected: ${socket.id} (${user.role})`);

  socket.on('join:manager', () => {
    if (user.role !== 'manager') {
      return;
    }
    socket.join('manager');
    console.log(`Manager joined room: ${socket.id}`);
  });

  socket.on('join:student', () => {
    if (user.role !== 'student') {
      return;
    }
    socket.join(`student:${user.id}`);
    console.log(`Student ${user.id} joined room: ${socket.id}`);
  });

  socket.on('disconnect', () => {
    console.log(`Socket disconnected: ${socket.id}`);
  });
});

// Keep CORS headers on error responses for allowed browser origins.
app.use((err, req, res, next) => {
  applyCorsHeaders(req, res);
  next(err);
});

const PORT = Number(process.env.PORT) || 5000;
const HOST = '0.0.0.0';

const startServer = async () => {
  // Listen immediately so Railway's proxy can reach the app while DB connects.
  await new Promise((resolve, reject) => {
    server.listen(PORT, HOST, (error) => {
      if (error) {
        reject(error);
        return;
      }

      console.log(`Server running on http://${HOST}:${PORT}`);
      console.log(`CORS allowed origins: ${allowedOrigins.join(', ')}`);
      resolve();
    });
  });

  try {
    await connectDB();
  } catch (error) {
    console.error('MongoDB connection error:', error.message);
  }
};

startServer().catch((error) => {
  console.error('Failed to start server:', error.message);
  process.exit(1);
});
