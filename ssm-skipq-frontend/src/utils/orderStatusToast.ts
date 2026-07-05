import type { OrderStatus } from '../types/order';

const STUDENT_STATUS_TOAST: Partial<Record<OrderStatus, string>> = {
  CONFIRMED: 'Order Confirmed',
  PREPARING: 'Preparing',
  READY: 'Ready for Pickup',
  PICKED_UP: 'Order Completed',
};

export const getStudentStatusToastTitle = (
  status: OrderStatus,
): string | null => STUDENT_STATUS_TOAST[status] ?? null;
