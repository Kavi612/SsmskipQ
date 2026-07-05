import axios from 'axios';

const DEFAULT_API_URL = 'http://localhost:5000/api';

/**
 * Normalizes VITE_API_URL into an absolute API base URL ending with /api.
 * Adds https:// when the env value has no protocol (fixes Railway treating
 * the backend host as a relative path on the frontend domain).
 */
export const resolveApiBaseUrl = (
  raw: string | undefined = import.meta.env.VITE_API_URL,
): string => {
  let url = (raw?.trim() || DEFAULT_API_URL).replace(/\/+$/, '');

  if (!/^https?:\/\//i.test(url)) {
    url = `https://${url.replace(/^\/+/, '')}`;
  }

  if (!url.endsWith('/api')) {
    url = `${url}/api`;
  }

  return url;
};

/** Socket.io connects to the server origin, not the /api path. */
export const resolveSocketUrl = (
  raw: string | undefined = import.meta.env.VITE_API_URL,
): string => resolveApiBaseUrl(raw).replace(/\/api$/, '');

export const API_BASE_URL = resolveApiBaseUrl();

export const TOKEN_KEY = 'ssm_skipq_token';

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

type UnauthorizedHandler = () => void;

let unauthorizedHandler: UnauthorizedHandler | null = null;

export const setUnauthorizedHandler = (handler: UnauthorizedHandler | null) => {
  unauthorizedHandler = handler;
};

api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (axios.isAxiosError(error) && error.response?.status === 401) {
      clearStoredToken();
      unauthorizedHandler?.();
    }
    return Promise.reject(error);
  },
);

export const getStoredToken = () => localStorage.getItem(TOKEN_KEY);

export const setStoredToken = (token: string) =>
  localStorage.setItem(TOKEN_KEY, token);

export const clearStoredToken = () => localStorage.removeItem(TOKEN_KEY);
