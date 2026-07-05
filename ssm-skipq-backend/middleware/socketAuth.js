import { verifyToken } from '../config/jwt.js';

export const socketAuthMiddleware = (socket, next) => {
  const token = socket.handshake.auth?.token;

  if (!token) {
    return next(new Error('Authentication required'));
  }

  try {
    socket.data.user = verifyToken(token);
    next();
  } catch {
    next(new Error('Invalid or expired token'));
  }
};
