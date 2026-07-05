import dotenv from 'dotenv';
import http from 'http';
import express from 'express';
import cors from 'cors';
import { Server } from 'socket.io';
import connectDB from './config/db.js';
import authRoutes from './routes/authRoutes.js';
import menuRoutes from './routes/menuRoutes.js';
import orderRoutes from './routes/orderRoutes.js';
import settingsRoutes from './routes/settingsRoutes.js';
import { getAllowedOrigins } from './utils/corsOrigins.js';
import { socketAuthMiddleware } from './middleware/socketAuth.js';

dotenv.config();

const allowedOrigins = getAllowedOrigins();

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: allowedOrigins,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    credentials: true,
  },
});

app.use(
  cors({
    origin: allowedOrigins,
    credentials: true,
  }),
);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/api/health', (_req, res) => {
  res.json({
    success: true,
    message: 'SSM SkipQ API is running',
    timestamp: new Date().toISOString(),
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

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();

  server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
};

startServer();
