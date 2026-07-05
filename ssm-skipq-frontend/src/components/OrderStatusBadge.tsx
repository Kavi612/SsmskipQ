import type { OrderStatus } from '../types/order';
import styles from './OrderStatusBadge.module.css';

const STATUS_LABELS: Record<OrderStatus, string> = {
  PENDING: 'Pending',
  CONFIRMED: 'Confirmed',
  PREPARING: 'Preparing',
  READY: 'Ready',
  PICKED_UP: 'Collected',
  CANCELLED: 'Cancelled',
};

interface OrderStatusBadgeProps {
  status: OrderStatus;
}

const OrderStatusBadge = ({ status }: OrderStatusBadgeProps) => {
  const classMap: Record<OrderStatus, string> = {
    PENDING: styles.pending,
    CONFIRMED: styles.confirmed,
    PREPARING: styles.preparing,
    READY: styles.ready,
    PICKED_UP: styles.pickedUp,
    CANCELLED: styles.cancelled,
  };

  return (
    <span className={`${styles.badge} ${classMap[status]}`}>
      {STATUS_LABELS[status]}
    </span>
  );
};

export default OrderStatusBadge;
