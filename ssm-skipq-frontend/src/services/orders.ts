import { api } from './api';
import type {
  CreateOrderPayload,
  OrderResponse,
  OrdersResponse,
} from '../types/order';

export const fetchMyOrders = async () => {
  const { data } = await api.get<OrdersResponse>('/api/orders');
  return data.data.orders;
};

export const createOrder = async (payload: CreateOrderPayload) => {
  const { data } = await api.post<OrderResponse>('/api/orders', payload);
  return data.data.order;
};
