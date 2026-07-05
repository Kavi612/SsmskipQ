import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { fetchOrderingWindow } from '../services/settings';
import { getSocket } from '../services/socket';
import type { OrderingWindow } from '../types/settings';

interface OrderingWindowContextValue extends OrderingWindow {
  isLoading: boolean;
  refresh: () => Promise<void>;
}

const OrderingWindowContext = createContext<OrderingWindowContextValue | null>(
  null,
);

export const OrderingWindowProvider = ({
  children,
}: {
  children: ReactNode;
}) => {
  const [window_, setWindow] = useState<OrderingWindow>({
    orderingOpenTime: '09:30',
    orderingCloseTime: '11:30',
    isOpen: true,
  });
  const [isLoading, setIsLoading] = useState(true);

  const refresh = useCallback(async () => {
    try {
      const data = await fetchOrderingWindow();
      setWindow(data);
    } catch {
      setWindow((prev) => ({ ...prev, isOpen: false }));
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;

    fetchOrderingWindow()
      .then((data) => {
        if (!cancelled) setWindow(data);
      })
      .catch(() => {
        if (!cancelled) setWindow((prev) => ({ ...prev, isOpen: false }));
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    const interval = setInterval(() => {
      fetchOrderingWindow()
        .then((data) => {
          if (!cancelled) setWindow(data);
        })
        .catch(() => {});
    }, 60_000);

    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, []);

  useEffect(() => {
    const socket = getSocket();
    if (!socket.connected) socket.connect();

    const handler = (data: OrderingWindow) => setWindow(data);
    socket.on('settings:ordering-window', handler);
    return () => {
      socket.off('settings:ordering-window', handler);
    };
  }, []);

  const value = useMemo(
    () => ({
      ...window_,
      isLoading,
      refresh,
    }),
    [window_, isLoading, refresh],
  );

  return (
    <OrderingWindowContext.Provider value={value}>
      {children}
    </OrderingWindowContext.Provider>
  );
};

export const useOrderingWindow = () => {
  const ctx = useContext(OrderingWindowContext);
  if (!ctx) {
    throw new Error(
      'useOrderingWindow must be used within OrderingWindowProvider',
    );
  }
  return ctx;
};
