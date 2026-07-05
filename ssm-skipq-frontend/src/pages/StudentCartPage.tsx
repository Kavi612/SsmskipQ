import { useNavigate } from 'react-router-dom';
import {
  Minus,
  Plus,
  ShoppingBag,
  Trash2,
  UtensilsCrossed,
} from 'lucide-react';
import { useCart } from '../context/CartContext';
import PageHeader from '../components/PageHeader';
import { EmptyState } from '../components/ui/UiStates';
import styles from './StudentCartPage.module.css';

const StudentCartPage = () => {
  const navigate = useNavigate();
  const { items, totalAmount, increment, decrement, removeItem } = useCart();

  if (items.length === 0) {
    return (
      <div className={styles.page}>
        <PageHeader title="Your Cart" backTo="/student" />
        <EmptyState
          icon={ShoppingBag}
          title="Your cart is empty"
          message="Browse the menu and add your favourite dishes to get started."
          actionLabel="Browse Menu"
          actionTo="/student"
        />
      </div>
    );
  }

  return (
    <div className={styles.page}>
      <PageHeader title="Your Cart" backTo="/student" />

      <div className={styles.body}>
        <ul className={styles.list}>
          {items.map((item) => (
            <li key={item.menuItemId} className={styles.item}>
              <div className={styles.imageWrap}>
                {item.imageUrl ? (
                  <img
                    src={item.imageUrl}
                    alt={item.name}
                    className={styles.image}
                  />
                ) : (
                  <div className={styles.placeholder}>
                    <UtensilsCrossed size={20} />
                  </div>
                )}
              </div>

              <div className={styles.itemBody}>
                <div className={styles.itemTop}>
                  <h2 className={styles.itemName}>{item.name}</h2>
                  <button
                    type="button"
                    className={styles.removeBtn}
                    onClick={() => removeItem(item.menuItemId)}
                    aria-label={`Remove ${item.name}`}
                  >
                    <Trash2 size={16} />
                  </button>
                </div>

                <p className={styles.itemPrice}>₹{item.price} each</p>

                <div className={styles.itemFooter}>
                  <div className={styles.stepper}>
                    <button
                      type="button"
                      className={styles.stepperBtn}
                      onClick={() => decrement(item.menuItemId)}
                      aria-label="Decrease quantity"
                    >
                      <Minus size={14} />
                    </button>
                    <span className={styles.qty}>{item.quantity}</span>
                    <button
                      type="button"
                      className={styles.stepperBtn}
                      onClick={() => increment(item.menuItemId)}
                      aria-label="Increase quantity"
                    >
                      <Plus size={14} />
                    </button>
                  </div>
                  <span className={styles.lineTotal}>
                    ₹{item.price * item.quantity}
                  </span>
                </div>
              </div>
            </li>
          ))}
        </ul>

        <div className={styles.footer}>
          <div className={styles.totalRow}>
            <span>Total</span>
            <span className={styles.totalAmount}>₹{totalAmount}</span>
          </div>
          <button
            type="button"
            className={styles.checkoutBtn}
            onClick={() => navigate('/student/checkout')}
          >
            Proceed to Checkout
          </button>
        </div>
      </div>
    </div>
  );
};

export default StudentCartPage;
