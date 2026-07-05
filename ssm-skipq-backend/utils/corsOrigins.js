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
  if (!origin) return true;
  return getAllowedOrigins().includes(normalizeOrigin(origin));
};

/**
 * Origin callback for the `cors` package.
 * Returns the request origin string when allowed (required for credentials).
 */
export const createCorsOriginValidator = (allowedOrigins) => {
  const allowed = new Set(allowedOrigins.map(normalizeOrigin));

  return (origin, callback) => {
    if (!origin) {
      callback(null, true);
      return;
    }

    if (allowed.has(normalizeOrigin(origin))) {
      callback(null, origin);
      return;
    }

    console.warn(`CORS blocked request from origin: ${origin}`);
    callback(null, false);
  };
};

/** Shared CORS options for Express and Socket.io. */
export const getCorsOptions = () => {
  const allowedOrigins = getAllowedOrigins();

  return {
    origin: createCorsOriginValidator(allowedOrigins),
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    optionsSuccessStatus: 204,
    preflightContinue: false,
  };
};

export { DEFAULT_ORIGINS };
