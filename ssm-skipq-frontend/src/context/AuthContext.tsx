import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  api,
  clearStoredToken,
  setStoredToken,
  getStoredToken,
  setUnauthorizedHandler,
} from '../services/api';
import type { AuthResponse, MeResponse, User } from '../types/auth';

interface AuthContextValue {
  user: User | null;
  isLoading: boolean;
  registerStudent: (name: string, mobile: string) => Promise<void>;
  loginStudent: (mobile: string) => Promise<void>;
  loginManager: (managerId: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const logout = useCallback(() => {
    clearStoredToken();
    setUser(null);
  }, []);

  const registerStudent = useCallback(async (name: string, mobile: string) => {
    const { data } = await api.post<AuthResponse>('/auth/student-register', {
      name,
      mobile,
    });

    if (!data.success) {
      throw new Error(data.message || 'Registration failed');
    }

    setStoredToken(data.data.token);
    setUser(data.data.user);
  }, []);

  const loginStudent = useCallback(async (mobile: string) => {
    const { data } = await api.post<AuthResponse>('/auth/student-login', {
      mobile,
    });

    if (!data.success) {
      throw new Error(data.message || 'Student login failed');
    }

    setStoredToken(data.data.token);
    setUser(data.data.user);
  }, []);

  const loginManager = useCallback(
    async (managerId: string, password: string) => {
      const { data } = await api.post<AuthResponse>('/auth/manager-login', {
        managerId,
        password,
      });

      if (!data.success) {
        throw new Error(data.message || 'Manager login failed');
      }

      setStoredToken(data.data.token);
      setUser(data.data.user);
    },
    [],
  );

  useEffect(() => {
    const restoreSession = async () => {
      const token = getStoredToken();

      if (!token) {
        setIsLoading(false);
        return;
      }

      try {
        const { data } = await api.get<MeResponse>('/auth/me');
        if (data.success) {
          setUser(data.data.user);
        } else {
          clearStoredToken();
        }
      } catch {
        clearStoredToken();
      } finally {
        setIsLoading(false);
      }
    };

    restoreSession();
  }, []);

  useEffect(() => {
    setUnauthorizedHandler(() => {
      setUser(null);
    });

    return () => {
      setUnauthorizedHandler(null);
    };
  }, []);

  const value = useMemo(
    () => ({
      user,
      isLoading,
      registerStudent,
      loginStudent,
      loginManager,
      logout,
    }),
    [user, isLoading, registerStudent, loginStudent, loginManager, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
