/** Parse comma-separated CLIENT_URL for CORS (local + Vercel preview + production). */
export const getAllowedOrigins = () => {
  const raw = process.env.CLIENT_URL || 'http://localhost:5173';
  return raw
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
};
