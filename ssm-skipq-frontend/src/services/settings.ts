import { api } from './api';
import type { OrderingWindowResponse } from '../types/settings';

export const fetchOrderingWindow = async () => {
  const { data } = await api.get<OrderingWindowResponse>(
    '/api/settings/ordering-window',
  );
  return data.data;
};

export const updateOrderingWindow = async (
  orderingOpenTime: string,
  orderingCloseTime: string,
) => {
  const { data } = await api.patch<OrderingWindowResponse>(
    '/api/settings/ordering-window',
    { orderingOpenTime, orderingCloseTime },
  );
  return data.data;
};
