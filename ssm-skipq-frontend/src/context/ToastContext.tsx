import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import type { Toast, ToastVariant } from '../types/toast';
import ToastContainer from '../components/toast/ToastContainer';

interface AddToastInput {
  variant: ToastVariant;
  title: string;
  message?: string;
  durationMs?: number;
}

interface ToastContextValue {
  addToast: (input: AddToastInput) => void;
  dismissToast: (id: string) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

const DEFAULT_DURATION_MS = 4500;

export const ToastProvider = ({ children }: { children: ReactNode }) => {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const timersRef = useRef<Map<string, number>>(new Map());

  const dismissToast = useCallback((id: string) => {
    const timer = timersRef.current.get(id);
    if (timer) {
      window.clearTimeout(timer);
      timersRef.current.delete(id);
    }
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const addToast = useCallback(
    ({
      variant,
      title,
      message,
      durationMs = DEFAULT_DURATION_MS,
    }: AddToastInput) => {
      const id = crypto.randomUUID();
      const toast: Toast = { id, variant, title, message };

      setToasts((prev) => [...prev, toast]);

      const timer = window.setTimeout(() => dismissToast(id), durationMs);
      timersRef.current.set(id, timer);
    },
    [dismissToast],
  );

  const value = useMemo(
    () => ({ addToast, dismissToast }),
    [addToast, dismissToast],
  );

  return (
    <ToastContext.Provider value={value}>
      {children}
      <ToastContainer toasts={toasts} onDismiss={dismissToast} />
    </ToastContext.Provider>
  );
};

export const useToast = () => {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    throw new Error('useToast must be used within ToastProvider');
  }
  return ctx;
};
