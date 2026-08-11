import type { OrderStatus } from '../types/order';

const STUDENT_STATUS_TOAST: Partial<Record<OrderStatus, string>> = {
  CONFIRMED: 'Order Accepted',
  PREPARING: 'Order Accepted',
  READY: 'Ready for Pickup',
};

export const getStudentStatusToastTitle = (
  status: OrderStatus,
): string | null => STUDENT_STATUS_TOAST[status] ?? null;
