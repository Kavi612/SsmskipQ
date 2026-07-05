import { useEffect } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import PageHeader from '../components/PageHeader';
import OrderStatusTimeline from '../components/OrderStatusTimeline';
import type { Order } from '../types/order';
import styles from './StudentOrderConfirmationPage.module.css';

const formatTime = (iso: string) =>
  new Intl.DateTimeFormat('en-IN', {
    timeStyle: 'short',
    timeZone: 'Asia/Kolkata',
  }).format(new Date(iso));

const paymentLabel = (order: Order) => {
  if (order.paymentMethod === 'PAY_AT_COUNTER') return 'Pay at Counter';
  if (order.paymentMethod === 'PHONEPE') return 'PhonePe (Mock)';
  return 'Google Pay (Mock)';
};

const StudentOrderConfirmationPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const order = location.state?.order as Order | undefined;

  useEffect(() => {
    if (!order) {
      navigate('/student/orders', { replace: true });
    }
  }, [order, navigate]);

  if (!order) return null;

  return (
    <div className={styles.page}>
      <PageHeader title="My Order" backTo="/student" />

      <div className={styles.body}>
        <section className={styles.tokenCard}>
          <span className={styles.tokenLabel}>Token Number</span>
          <span className={styles.token}>{order.tokenNumber}</span>
          <div className={styles.tokenMeta}>
            <div>
              <span className={styles.metaLabel}>Order Placed</span>
              <span className={styles.metaValue}>
                {formatTime(order.createdAt)}
              </span>
            </div>
            <div>
              <span className={styles.metaLabel}>Payment Method</span>
              <span className={`${styles.metaValue} ${styles.metaAccent}`}>
                {paymentLabel(order)}
              </span>
            </div>
          </div>
        </section>

        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Order Status</h2>
          <OrderStatusTimeline status={order.status} />
        </section>

        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Order Details</h2>
          <ul className={styles.items}>
            {order.items.map((item, idx) => (
              <li key={`${item.menuItemId}-${idx}`} className={styles.itemRow}>
                <span>
                  {item.name} × {item.quantity}
                </span>
                <span>₹{item.price * item.quantity}</span>
              </li>
            ))}
          </ul>
          <div className={styles.totalRow}>
            <span>Total</span>
            <span>₹{order.total}</span>
          </div>
        </section>

        <Link to="/student/orders" className={styles.outlineBtn}>
          VIEW PREVIOUS ORDERS
        </Link>
      </div>
    </div>
  );
};

export default StudentOrderConfirmationPage;
