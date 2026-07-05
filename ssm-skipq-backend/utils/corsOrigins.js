const DEFAULT_ORIGINS = [
  'http://localhost:5173',
  'https://ssmskipq-production.up.railway.app',
];

const normalizeOrigin = (origin) => origin.replace(/\/+$/, '');

/** Merge defaults with comma-separated CLIENT_URL env var. */
export const getAllowedOrigins = () => {
  const fromEnv = (process.env.CLIENT_URL || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  return [...new Set([...DEFAULT_ORIGINS, ...fromEnv].map(normalizeOrigin))];
};

export const isOriginAllowed = (origin) => {
  if (!origin) return false;
  return getAllowedOrigins().includes(normalizeOrigin(origin));
};

/** Socket.io CORS — use a static origin list (not a callback). */
export const getSocketCorsOptions = () => ({
  origin: getAllowedOrigins(),
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
});

export { DEFAULT_ORIGINS };
