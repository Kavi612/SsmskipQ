import { io, type Socket } from 'socket.io-client';
import { getStoredToken } from './api';

const SOCKET_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000';

let socket: Socket | null = null;

export const getSocket = () => {
  if (!socket) {
    socket = io(SOCKET_URL, {
      autoConnect: false,
      transports: ['websocket', 'polling'],
    });
  }
  return socket;
};

export const connectSocket = () => {
  const s = getSocket();
  const token = getStoredToken();

  if (!token) {
    throw new Error('Cannot connect socket without auth token');
  }

  s.auth = { token };

  if (!s.connected) {
    s.connect();
  }

  return s;
};

export const disconnectSocket = () => {
  if (socket?.connected) {
    socket.disconnect();
  }
};

export const joinManagerRoom = () => {
  const s = connectSocket();
  s.emit('join:manager');
  return s;
};

export const joinStudentRoom = () => {
  const s = connectSocket();
  s.emit('join:student');
  return s;
};
