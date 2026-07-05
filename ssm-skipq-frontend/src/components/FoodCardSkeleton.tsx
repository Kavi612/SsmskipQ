import styles from './FoodCardSkeleton.module.css';
import skeleton from './ui/skeleton.module.css';

const FoodCardSkeleton = () => (
  <article className={styles.card} aria-hidden>
    <div className={`${styles.image} ${skeleton.skeleton}`} />
    <div className={styles.body}>
      <div className={`${styles.lineTitle} ${skeleton.skeleton}`} />
      <div className={`${styles.lineDesc} ${skeleton.skeleton}`} />
      <div className={`${styles.linePrice} ${skeleton.skeleton}`} />
    </div>
  </article>
);

export const FoodCardSkeletonGrid = ({ count = 6 }: { count?: number }) => (
  <>
    {Array.from({ length: count }, (_, i) => (
      <FoodCardSkeleton key={i} />
    ))}
  </>
);

export default FoodCardSkeleton;
