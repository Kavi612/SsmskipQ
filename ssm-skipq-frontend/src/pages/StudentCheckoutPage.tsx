import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import axios from 'axios';
import {
  CreditCard,
  Loader2,
  ShieldCheck,
  Store,
  UtensilsCrossed,
} from 'lucide-react';
import { useCart } from '../context/CartContext';
import { createOrder } from '../services/orders';
import PageHeader from '../components/PageHeader';
import type { PaymentMethod } from '../types/order';
import styles from './StudentCheckoutPage.module.css';

const PACKAGING_CHARGE = 0;

const StudentCheckoutPage = () => {
  const navigate = useNavigate();
  const { items, totalAmount, clear } = useCart();
  const [selectedMethod, setSelectedMethod] =
    useState<PaymentMethod>('GOOGLE_PAY');
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState('');

  if (items.length === 0 && !isProcessing) {
    navigate('/student/cart', { replace: true });
    return null;
  }

  const subtotal = totalAmount;
  const total = subtotal + PACKAGING_CHARGE;

  const handleConfirm = async () => {
    setError('');
    setIsProcessing(true);

    const isOnline = selectedMethod !== 'PAY_AT_COUNTER';

    try {
      if (isOnline) {
        await new Promise((resolve) => setTimeout(resolve, 1500));
      }

      const order = await createOrder({
        items: items.map((item) => ({
          menuItemId: item.menuItemId,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
        })),
        total: subtotal,
        paymentMethod: selectedMethod,
        paymentStatus: isOnline ? 'PAID' : 'PENDING',
      });

      clear();
      navigate('/student/order-confirmation', {
        replace: true,
        state: { order },
      });
    } catch (err) {
      const message =
        axios.isAxiosError(err) && err.response?.data?.message
          ? err.response.data.message
          : 'Unable to place order. Please try again.';
      setError(message);
      setIsProcessing(false);
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader title="Checkout" backTo="/student/cart" />

      <div className={styles.body}>
        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Your Order</h2>
          <ul className={styles.orderList}>
            {items.map((item) => (
              <li key={item.menuItemId} className={styles.orderItem}>
                <div className={styles.thumb}>
                  {item.imageUrl ? (
                    <img src={item.imageUrl} alt={item.name} />
                  ) : (
                    <UtensilsCrossed size={18} />
                  )}
                </div>
                <div className={styles.orderInfo}>
                  <span className={styles.orderName}>{item.name}</span>
                  <span className={styles.orderPrice}>₹{item.price}</span>
                </div>
                <span className={styles.orderQty}>× {item.quantity}</span>
              </li>
            ))}
          </ul>
        </section>

        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Bill Details</h2>
          <dl className={styles.bill}>
            <div className={styles.billRow}>
              <dt>Subtotal</dt>
              <dd>₹{subtotal}</dd>
            </div>
            <div className={styles.billRow}>
              <dt>Packaging Charge</dt>
              <dd>₹{PACKAGING_CHARGE}</dd>
            </div>
            <div className={`${styles.billRow} ${styles.billTotal}`}>
              <dt>Total</dt>
              <dd>₹{total}</dd>
            </div>
          </dl>
        </section>

        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Select Payment Method</h2>
          <div className={styles.paymentOptions}>
            <label
              className={`${styles.paymentCard} ${selectedMethod !== 'PAY_AT_COUNTER' ? styles.paymentCardActive : ''}`}
            >
              <input
                type="radio"
                name="payment"
                checked={selectedMethod !== 'PAY_AT_COUNTER'}
                onChange={() => setSelectedMethod('GOOGLE_PAY')}
                className={styles.radioInput}
                disabled={isProcessing}
              />
              <span className={styles.paymentIcon}>
                <CreditCard size={22} />
              </span>
              <span className={styles.paymentText}>
                <span className={styles.paymentLabel}>Pay Online</span>
                <span className={styles.paymentDesc}>
                  UPI · Cards · Net Banking (Mock)
                </span>
              </span>
            </label>

            <label
              className={`${styles.paymentCard} ${selectedMethod === 'PAY_AT_COUNTER' ? styles.paymentCardActive : ''}`}
            >
              <input
                type="radio"
                name="payment"
                checked={selectedMethod === 'PAY_AT_COUNTER'}
                onChange={() => setSelectedMethod('PAY_AT_COUNTER')}
                className={styles.radioInput}
                disabled={isProcessing}
              />
              <span className={styles.paymentIcon}>
                <Store size={22} />
              </span>
              <span className={styles.paymentText}>
                <span className={styles.paymentLabel}>Pay at Counter</span>
                <span className={styles.paymentDesc}>
                  Pay when you collect your order
                </span>
              </span>
            </label>
          </div>
        </section>

        {error && <p className={styles.error}>{error}</p>}

        {isProcessing && (
          <motion.div
            className={styles.processing}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
          >
            <Loader2 size={28} className={styles.spinner} />
            <p>Processing payment…</p>
          </motion.div>
        )}

        <p className={styles.secure}>
          <ShieldCheck size={16} />
          Your order is safe and secure
        </p>

        <button
          type="button"
          className={styles.placeBtn}
          onClick={handleConfirm}
          disabled={isProcessing}
        >
          {isProcessing ? 'Please wait…' : 'PLACE ORDER'}
        </button>
      </div>
    </div>
  );
};

export default StudentCheckoutPage;
