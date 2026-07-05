import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';

export interface CartItem {
  menuItemId: string;
  name: string;
  price: number;
  quantity: number;
  imageUrl: string;
  isVeg: boolean;
  available: boolean;
}

interface CartContextValue {
  items: CartItem[];
  getQuantity: (menuItemId: string) => number;
  addItem: (item: Omit<CartItem, 'quantity'>) => void;
  addItemWithQuantity: (
    item: Omit<CartItem, 'quantity'>,
    quantity: number,
  ) => void;
  increment: (menuItemId: string) => void;
  decrement: (menuItemId: string) => void;
  removeItem: (menuItemId: string) => void;
  clear: () => void;
  totalItems: number;
  totalAmount: number;
}

const CartContext = createContext<CartContextValue | null>(null);

export const CartProvider = ({ children }: { children: ReactNode }) => {
  const [items, setItems] = useState<CartItem[]>([]);

  const getQuantity = useCallback(
    (menuItemId: string) =>
      items.find((item) => item.menuItemId === menuItemId)?.quantity ?? 0,
    [items],
  );

  const addItem = useCallback((item: Omit<CartItem, 'quantity'>) => {
    setItems((prev) => {
      const existing = prev.find((i) => i.menuItemId === item.menuItemId);
      if (existing) {
        return prev.map((i) =>
          i.menuItemId === item.menuItemId
            ? { ...i, quantity: i.quantity + 1 }
            : i,
        );
      }
      return [...prev, { ...item, quantity: 1 }];
    });
  }, []);

  const addItemWithQuantity = useCallback(
    (item: Omit<CartItem, 'quantity'>, quantity: number) => {
      if (quantity < 1) return;

      setItems((prev) => {
        const existing = prev.find((i) => i.menuItemId === item.menuItemId);
        if (existing) {
          return prev.map((i) =>
            i.menuItemId === item.menuItemId
              ? {
                  ...i,
                  ...item,
                  quantity: i.quantity + quantity,
                }
              : i,
          );
        }
        return [...prev, { ...item, quantity }];
      });
    },
    [],
  );

  const increment = useCallback((menuItemId: string) => {
    setItems((prev) =>
      prev.map((item) =>
        item.menuItemId === menuItemId
          ? { ...item, quantity: item.quantity + 1 }
          : item,
      ),
    );
  }, []);

  const decrement = useCallback((menuItemId: string) => {
    setItems((prev) =>
      prev
        .map((item) =>
          item.menuItemId === menuItemId
            ? { ...item, quantity: item.quantity - 1 }
            : item,
        )
        .filter((item) => item.quantity > 0),
    );
  }, []);

  const removeItem = useCallback((menuItemId: string) => {
    setItems((prev) => prev.filter((item) => item.menuItemId !== menuItemId));
  }, []);

  const clear = useCallback(() => {
    setItems([]);
  }, []);

  const totalItems = useMemo(
    () => items.reduce((sum, item) => sum + item.quantity, 0),
    [items],
  );

  const totalAmount = useMemo(
    () => items.reduce((sum, item) => sum + item.price * item.quantity, 0),
    [items],
  );

  const value = useMemo(
    () => ({
      items,
      getQuantity,
      addItem,
      addItemWithQuantity,
      increment,
      decrement,
      removeItem,
      clear,
      totalItems,
      totalAmount,
    }),
    [
      items,
      getQuantity,
      addItem,
      addItemWithQuantity,
      increment,
      decrement,
      removeItem,
      clear,
      totalItems,
      totalAmount,
    ],
  );

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
};

export const useCart = () => {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within CartProvider');
  }
  return context;
};
