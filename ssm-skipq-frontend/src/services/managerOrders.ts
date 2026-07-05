import { api } from './api';
import type { Order } from '../types/order';

interface ManagerOrdersResponse {
  success: boolean;
  data: { orders: Order[] };
}

interface OrderResponse {
  success: boolean;
  data: { order: Order };
}

export const fetchManagerOrders = async () => {
  const { data } = await api.get<ManagerOrdersResponse>('/api/orders/manager');
  return data.data.orders;
};

export const advanceOrderStatus = async (orderId: string) => {
  const { data } = await api.patch<OrderResponse>(
    `/api/orders/${orderId}/status`,
  );
  return data.data.order;
};

export const updateOrderPayment = async (
  orderId: string,
  paymentStatus: 'PENDING' | 'PAID',
) => {
  const { data } = await api.patch<OrderResponse>(
    `/api/orders/${orderId}/payment`,
    { paymentStatus },
  );
  return data.data.order;
};
