import { useEffect, useState } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  Check,
  ChefHat,
  CircleCheck,
  ClipboardCheck,
  PackageCheck,
  ShoppingBag,
  type LucideIcon,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import PageHeader from '../components/PageHeader';
import { fetchOrder } from '../services/orders';
import { joinStudentRoom } from '../services/socket';
import type { Order, OrderStatus } from '../types/order';
import styles from './StudentOrderConfirmationPage.module.css';

const STAGES: { label: string; icon: LucideIcon }[] = [
  { label: 'Order Placed', icon: ClipboardCheck },
  { label: 'Preparing', icon: ChefHat },
  { label: 'Ready for Pickup', icon: PackageCheck },
  { label: 'Collected', icon: ShoppingBag },
];

const STATUS_RANK: Record<OrderStatus, number> = {
  PENDING: 0,
  CONFIRMED: 0,
  PREPARING: 1,
  READY: 2,
  PICKED_UP: 3,
  CANCELLED: -1,
};

const statusMessage = (status: OrderStatus) => {
  switch (status) {
    case 'PREPARING':
      return 'The canteen is preparing your food.';
    case 'READY':
      return 'Your order is ready! Please collect it from the counter using your token number.';
    case 'PICKED_UP':
      return 'Order completed. Enjoy your meal!';
    default:
      return 'Your order has been received!';
  }
};

const StudentOrderConfirmationPage = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const { orderId } = useParams();
  const initialOrder = location.state?.order as Order | undefined;
  const requestedOrderId = orderId ?? initialOrder?.id;
  const [order, setOrder] = useState<Order | undefined>(initialOrder);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!requestedOrderId) {
      navigate('/student', { replace: true });
      return;
    }

    let cancelled = false;

    fetchOrder(requestedOrderId)
      .then((latest) => {
        if (!cancelled) setOrder(latest);
      })
      .catch(() => {
        if (!cancelled && !initialOrder) setError('Unable to load this order.');
      });

    return () => {
      cancelled = true;
    };
  }, [initialOrder, navigate, requestedOrderId]);

  useEffect(() => {
    if (!user || user.role !== 'student' || !requestedOrderId) return;

    const socket = joinStudentRoom();
    const handleUpdate = (updated: Order) => {
      if (updated.id === requestedOrderId) setOrder(updated);
    };

    socket.on('order:updated', handleUpdate);
    return () => {
      socket.off('order:updated', handleUpdate);
    };
  }, [user, requestedOrderId]);

  if (error) {
    return (
      <div className={styles.page}>
        <PageHeader title="Track Order" backTo="/student" />
        <p className={styles.error}>{error}</p>
      </div>
    );
  }

  if (!order) return null;

  const currentRank = STATUS_RANK[order.status];
  const progress = order.status === 'CANCELLED'
    ? 0
    : (currentRank / (STAGES.length - 1)) * 100;

  return (
    <div className={styles.page}>
      <PageHeader title="Track Order" backTo="/student" />

      <main className={styles.body}>
        <section className={styles.tokenCard}>
          <span className={styles.tokenLabel}>Your Token Number</span>
          <strong className={styles.token}>{order.tokenNumber}</strong>
          <p className={styles.message}>{statusMessage(order.status)}</p>
        </section>

        <section className={styles.section} aria-label="Order status">
          <h2 className={styles.sectionTitle}>Order Status</h2>
          {order.status === 'CANCELLED' ? (
            <div className={styles.cancelled}>
              <CircleCheck size={22} />
              <span>This order was cancelled.</span>
            </div>
          ) : (
            <div className={styles.tracker}>
              <div className={styles.progressTrack} aria-hidden="true">
                <motion.div
                  className={styles.progressFill}
                  initial={{ width: 0 }}
                  animate={{ width: `${progress * 0.75}%` }}
                  transition={{ duration: 0.6, ease: 'easeOut' }}
                />
              </div>
              <ol className={styles.stages}>
                {STAGES.map((stage, index) => {
                  const Icon = stage.icon;
                  const isComplete = index < currentRank;
                  const isCurrent = index === currentRank;

                  return (
                    <li
                      key={stage.label}
                      className={`${styles.stage} ${isComplete ? styles.complete : ''} ${isCurrent ? styles.current : ''}`}
                    >
                      <span className={styles.stageIcon}>
                        {isComplete ? <Check size={18} strokeWidth={3} /> : <Icon size={18} />}
                      </span>
                      <span className={styles.stageLabel}>{stage.label}</span>
                    </li>
                  );
                })}
              </ol>
            </div>
          )}
        </section>

        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Order Details</h2>
          <ul className={styles.items}>
            {order.items.map((item, index) => (
              <li key={`${item.menuItemId}-${index}`} className={styles.itemRow}>
                <span>{item.name} × {item.quantity}</span>
                <span>₹{item.price * item.quantity}</span>
              </li>
            ))}
          </ul>
          <div className={styles.totalRow}>
            <span>Total</span>
            <span>₹{order.total}</span>
          </div>
        </section>
      </main>
    </div>
  );
};

export default StudentOrderConfirmationPage;
