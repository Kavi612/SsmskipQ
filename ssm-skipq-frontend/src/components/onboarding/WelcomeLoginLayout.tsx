import type { ReactNode } from 'react';
import { motion, useReducedMotion } from 'framer-motion';
import logoAppIcon from '../../assets/logo-app-icon.png';
import FoodCollage from './FoodCollage';
import styles from './WelcomeLoginLayout.module.css';

interface WelcomeLoginLayoutProps {
  headline: string;
  variant?: 'student' | 'manager';
  subtitle?: string;
  children: ReactNode;
  footer?: ReactNode;
}

const WelcomeLoginLayout = ({
  headline,
  variant = 'manager',
  subtitle,
  children,
  footer,
}: WelcomeLoginLayoutProps) => {
  const reduceMotion = useReducedMotion();
  const isStudent = variant === 'student';

  return (
    <div className={styles.page}>
      {isStudent ? (
        <header className={styles.collageHeader}>
          <FoodCollage />
        </header>
      ) : (
        <header className={styles.logoHeader}>
          <img src={logoAppIcon} alt="SkipQ@SSM" className={styles.logo} />
        </header>
      )}

      <motion.main
        className={styles.main}
        initial={reduceMotion ? false : { opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: 'easeOut', delay: 0.06 }}
      >
        {isStudent && <p className={styles.wordmark}>SkipQ@SSM</p>}

        <h1 className={styles.headline}>{headline}</h1>
        {subtitle && <p className={styles.lead}>{subtitle}</p>}

        {children}

        {footer && <footer className={styles.footer}>{footer}</footer>}
      </motion.main>
    </div>
  );
};

export default WelcomeLoginLayout;
