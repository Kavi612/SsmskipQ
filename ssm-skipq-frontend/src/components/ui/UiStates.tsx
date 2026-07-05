import type { LucideIcon } from 'lucide-react';
import { Link } from 'react-router-dom';
import styles from './ui.module.css';

interface LoadingSpinnerProps {
  label?: string;
}

export const LoadingSpinner = ({ label = 'Loading…' }: LoadingSpinnerProps) => (
  <div className={styles.spinnerWrap} role="status" aria-live="polite">
    <div className={styles.spinner} aria-hidden />
    <p className={styles.spinnerLabel}>{label}</p>
  </div>
);

interface EmptyStateProps {
  icon: LucideIcon;
  title: string;
  message: string;
  actionLabel?: string;
  actionTo?: string;
  onAction?: () => void;
}

export const EmptyState = ({
  icon: Icon,
  title,
  message,
  actionLabel,
  actionTo,
  onAction,
}: EmptyStateProps) => (
  <div className={styles.empty}>
    <div className={styles.emptyIcon} aria-hidden>
      <Icon size={28} strokeWidth={1.75} />
    </div>
    <h2 className={styles.emptyTitle}>{title}</h2>
    <p className={styles.emptyMessage}>{message}</p>
    {actionLabel && actionTo && (
      <Link to={actionTo} className={styles.emptyAction}>
        {actionLabel}
      </Link>
    )}
    {actionLabel && onAction && !actionTo && (
      <button type="button" className={styles.emptyAction} onClick={onAction}>
        {actionLabel}
      </button>
    )}
  </div>
);
