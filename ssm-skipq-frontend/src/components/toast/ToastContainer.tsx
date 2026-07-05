import { AnimatePresence, motion } from 'framer-motion';
import { BellRing, CheckCircle2, ChefHat, PackageCheck, X } from 'lucide-react';
import type { Toast } from '../../types/toast';
import styles from './ToastContainer.module.css';

interface ToastContainerProps {
  toasts: Toast[];
  onDismiss: (id: string) => void;
}

const studentIcon = (title: string) => {
  if (title.includes('Confirmed')) return CheckCircle2;
  if (title.includes('Preparing')) return ChefHat;
  if (title.includes('Ready')) return PackageCheck;
  if (title.includes('Completed')) return CheckCircle2;
  return CheckCircle2;
};

const ToastContainer = ({ toasts, onDismiss }: ToastContainerProps) => {
  return (
    <div
      className={styles.viewport}
      aria-live="polite"
      aria-relevant="additions"
    >
      <AnimatePresence mode="popLayout">
        {toasts.map((toast) => {
          const isManager = toast.variant === 'manager';
          const StudentIcon = studentIcon(toast.title);

          return (
            <motion.div
              key={toast.id}
              layout
              role="status"
              className={`${styles.toast} ${isManager ? styles.toastManager : styles.toastStudent}`}
              initial={{ opacity: 0, y: isManager ? -28 : -16, scale: 0.94 }}
              animate={{
                opacity: 1,
                y: 0,
                scale: 1,
                ...(isManager
                  ? {
                      boxShadow: [
                        '0 0 0 0 rgba(254, 65, 1, 0.45)',
                        '0 0 0 10px rgba(254, 65, 1, 0)',
                        '0 0 0 0 rgba(254, 65, 1, 0)',
                      ],
                    }
                  : {}),
              }}
              exit={{ opacity: 0, y: -12, scale: 0.96 }}
              transition={
                isManager
                  ? {
                      type: 'spring',
                      stiffness: 420,
                      damping: 26,
                      boxShadow: {
                        duration: 1.1,
                        repeat: 2,
                        ease: 'easeOut',
                      },
                    }
                  : { type: 'spring', stiffness: 380, damping: 28 }
              }
            >
              <span
                className={`${styles.iconWrap} ${isManager ? styles.iconManager : styles.iconStudent}`}
                aria-hidden
              >
                {isManager ? (
                  <BellRing size={20} className={styles.bellIcon} />
                ) : (
                  <StudentIcon size={20} />
                )}
              </span>

              <div className={styles.content}>
                <p className={styles.title}>{toast.title}</p>
                {toast.message && (
                  <p className={styles.message}>{toast.message}</p>
                )}
              </div>

              <button
                type="button"
                className={styles.dismissBtn}
                onClick={() => onDismiss(toast.id)}
                aria-label="Dismiss notification"
              >
                <X size={16} />
              </button>
            </motion.div>
          );
        })}
      </AnimatePresence>
    </div>
  );
};

export default ToastContainer;
