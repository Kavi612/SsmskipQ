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

/** Validates request Origin against the allowlist (supports credentials). */
export const createCorsOriginValidator = (allowedOrigins) => {
  const allowed = new Set(allowedOrigins.map(normalizeOrigin));

  return (origin, callback) => {
    // Non-browser clients (curl, health checks) send no Origin header.
    if (!origin) {
      callback(null, true);
      return;
    }

    if (allowed.has(normalizeOrigin(origin))) {
      callback(null, true);
      return;
    }

    callback(null, false);
  };
};
