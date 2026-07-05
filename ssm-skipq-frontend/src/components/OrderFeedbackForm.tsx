import { useState, type FormEvent } from 'react';
import { Star } from 'lucide-react';
import { submitOrderFeedback } from '../services/feedback';
import styles from './OrderFeedbackForm.module.css';

interface OrderFeedbackFormProps {
  orderId: string;
  tokenNumber: string;
  onSubmitted: () => void;
}

const OrderFeedbackForm = ({
  orderId,
  tokenNumber,
  onSubmitted,
}: OrderFeedbackFormProps) => {
  const [rating, setRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [review, setReview] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const displayRating = hoverRating || rating;

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (rating < 1) {
      setError('Please select a star rating.');
      return;
    }

    setIsSubmitting(true);
    setError('');

    try {
      await submitOrderFeedback(orderId, {
        rating,
        review: review.trim() || undefined,
      });
      onSubmitted();
    } catch {
      setError('Unable to submit feedback. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form className={styles.form} onSubmit={handleSubmit}>
      <p className={styles.prompt}>
        How was your order <strong>{tokenNumber}</strong>?
      </p>

      <div
        className={styles.stars}
        role="radiogroup"
        aria-label="Rate your order from 1 to 5 stars"
      >
        {[1, 2, 3, 4, 5].map((value) => (
          <button
            key={value}
            type="button"
            role="radio"
            aria-checked={rating === value}
            aria-label={`${value} star${value === 1 ? '' : 's'}`}
            className={styles.starBtn}
            onMouseEnter={() => setHoverRating(value)}
            onMouseLeave={() => setHoverRating(0)}
            onClick={() => setRating(value)}
          >
            <Star
              size={28}
              className={
                value <= displayRating ? styles.starFilled : styles.starEmpty
              }
              fill={value <= displayRating ? 'currentColor' : 'none'}
            />
          </button>
        ))}
      </div>

      <textarea
        className={styles.reviewInput}
        placeholder="Optional short review…"
        value={review}
        onChange={(e) => setReview(e.target.value)}
        maxLength={500}
        rows={3}
      />

      {error && <p className={styles.error}>{error}</p>}

      <button
        type="submit"
        className={styles.submitBtn}
        disabled={isSubmitting || rating < 1}
      >
        {isSubmitting ? 'Submitting…' : 'Submit Feedback'}
      </button>
    </form>
  );
};

export default OrderFeedbackForm;
