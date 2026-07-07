import { Check } from 'lucide-react';
import type { OrderStatus } from '../types/order';
import styles from './OrderStatusTimeline.module.css';

const STEPS: { status: OrderStatus; label: string }[] = [
  { status: 'CONFIRMED', label: 'Order Received' },
  { status: 'PREPARING', label: 'Preparing' },
  { status: 'READY', label: 'Ready for Pickup' },
  { status: 'PICKED_UP', label: 'Collected' },
];

const STATUS_RANK: Record<OrderStatus, number> = {
  PENDING: 0,
  CONFIRMED: 1,
  PREPARING: 2,
  READY: 3,
  PICKED_UP: 4,
  CANCELLED: -1,
};

interface OrderStatusTimelineProps {
  status: OrderStatus;
}

const OrderStatusTimeline = ({ status }: OrderStatusTimelineProps) => {
  const currentRank =
    status === 'CANCELLED' ? -1 : (STATUS_RANK[status] ?? 0);

  return (
    <ol className={styles.timeline}>
      {STEPS.map((step, index) => {
        const stepRank = STATUS_RANK[step.status];
        const isComplete =
          status !== 'CANCELLED' &&
          status !== 'PENDING' &&
          currentRank >= stepRank;
        const isCurrent =
          status !== 'CANCELLED' &&
          status !== 'PICKED_UP' &&
          ((status === 'PENDING' && index === 0) ||
            currentRank === stepRank);

        return (
          <li
            key={step.status}
            className={`${styles.step} ${isComplete ? styles.stepComplete : ''} ${isCurrent ? styles.stepCurrent : ''}`}
          >
            <span className={styles.dot}>
              {isComplete && <Check size={12} strokeWidth={3} />}
            </span>
            <div className={styles.stepBody}>
              <span className={styles.stepLabel}>{step.label}</span>
              {index === 0 && status === 'PENDING' && (
                <span className={styles.stepHint}>
                  Waiting for confirmation
                </span>
              )}
            </div>
          </li>
        );
      })}
    </ol>
  );
};

export default OrderStatusTimeline;
