const DEFAULT_ORIGINS = ['http://localhost:5173'];

const normalizeOrigin = (origin) => origin.replace(/\/+$/, '');

/** Merge localhost default with comma-separated CLIENT_URL env var. */
export const getAllowedOrigins = () => {
  const fromEnv = (process.env.CLIENT_URL || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  return [...new Set([...DEFAULT_ORIGINS, ...fromEnv].map(normalizeOrigin))];
};

const isLocalDevOrigin = (origin) =>
  /^http:\/\/localhost:\d+$/.test(normalizeOrigin(origin));

export const isOriginAllowed = (origin) => {
  if (!origin) return false;
  if (process.env.NODE_ENV !== 'production' && isLocalDevOrigin(origin)) {
    return true;
  }
  return getAllowedOrigins().includes(normalizeOrigin(origin));
};

/** Socket.io CORS — use a static origin list (not a callback). */
export const getSocketCorsOptions = () => ({
  origin: getAllowedOrigins(),
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
});

export { DEFAULT_ORIGINS };
