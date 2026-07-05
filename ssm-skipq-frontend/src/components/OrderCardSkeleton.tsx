import styles from './OrderCardSkeleton.module.css';
import skeleton from './ui/skeleton.module.css';

const OrderCardSkeleton = () => (
  <li className={styles.card} aria-hidden>
    <div className={styles.header}>
      <div className={`${styles.token} ${skeleton.skeleton}`} />
      <div className={`${styles.badge} ${skeleton.skeleton}`} />
    </div>
    <div className={`${styles.line} ${skeleton.skeleton}`} />
    <div className={`${styles.lineShort} ${skeleton.skeleton}`} />
    <div className={styles.footer}>
      <div className={`${styles.price} ${skeleton.skeleton}`} />
      <div className={`${styles.meta} ${skeleton.skeleton}`} />
    </div>
  </li>
);

export const OrderCardSkeletonList = ({ count = 3 }: { count?: number }) => (
  <>
    {Array.from({ length: count }, (_, i) => (
      <OrderCardSkeleton key={i} />
    ))}
  </>
);

export default OrderCardSkeleton;
