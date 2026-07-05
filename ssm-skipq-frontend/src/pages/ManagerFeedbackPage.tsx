import { useEffect, useState } from 'react';
import { MessageSquare, Star } from 'lucide-react';
import { fetchManagerFeedback } from '../services/feedback';
import type { OrderFeedback } from '../types/feedback';
import { OrderCardSkeletonList } from '../components/OrderCardSkeleton';
import { EmptyState } from '../components/ui/UiStates';
import styles from './ManagerFeedbackPage.module.css';

const formatDate = (iso: string) =>
  new Intl.DateTimeFormat('en-IN', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: 'Asia/Kolkata',
  }).format(new Date(iso));

const StarRating = ({ rating }: { rating: number }) => (
  <span className={styles.starRow} aria-label={`${rating} out of 5 stars`}>
    {[1, 2, 3, 4, 5].map((value) => (
      <Star
        key={value}
        size={16}
        className={value <= rating ? styles.starFilled : styles.starEmpty}
        fill={value <= rating ? 'currentColor' : 'none'}
      />
    ))}
  </span>
);

const ManagerFeedbackPage = () => {
  const [feedback, setFeedback] = useState<OrderFeedback[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;

    fetchManagerFeedback()
      .then((data) => {
        if (!cancelled) setFeedback(data);
      })
      .catch(() => {
        if (!cancelled) setError('Unable to load feedback.');
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className={styles.page}>
      <p className={styles.subtitle}>
        {feedback.length} review{feedback.length === 1 ? '' : 's'}
      </p>

      {isLoading && (
        <ul className={styles.list}>
          <OrderCardSkeletonList count={3} />
        </ul>
      )}
      {error && <p className={styles.error}>{error}</p>}

      {!isLoading && !error && feedback.length === 0 && (
        <EmptyState
          icon={MessageSquare}
          title="No feedback yet"
          message="Student reviews will appear here after they collect their orders."
        />
      )}

      {!isLoading && feedback.length > 0 && (
        <ul className={styles.list}>
          {feedback.map((entry) => (
            <li key={entry.id} className={styles.card}>
              <div className={styles.cardHeader}>
                <div>
                  <span className={styles.token}>
                    {entry.order?.tokenNumber ?? '—'}
                  </span>
                  {entry.student && (
                    <span className={styles.student}>{entry.student.name}</span>
                  )}
                </div>
                <div className={styles.ratingBlock}>
                  <StarRating rating={entry.rating} />
                  <span className={styles.ratingValue}>{entry.rating}/5</span>
                </div>
              </div>

              {entry.review && (
                <p className={styles.review}>&ldquo;{entry.review}&rdquo;</p>
              )}

              {entry.order?.items && entry.order.items.length > 0 && (
                <ul className={styles.items}>
                  {entry.order.items.map((item, idx) => (
                    <li key={`${item.menuItemId}-${idx}`}>
                      {item.name} × {item.quantity}
                    </li>
                  ))}
                </ul>
              )}

              <div className={styles.footer}>
                <span>₹{entry.order?.total ?? '—'}</span>
                <span className={styles.date}>
                  {formatDate(entry.createdAt)}
                </span>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};

export default ManagerFeedbackPage;
