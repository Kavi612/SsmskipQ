import { Link, useLocation } from 'react-router-dom';
import { RefreshCw } from 'lucide-react';
import logoAppIcon from '../assets/logo-app-icon.png';
import styles from './ManagerHeader.module.css';

interface ManagerHeaderProps {
  onRefresh?: () => void;
}

const TITLES: Record<string, string> = {
  '/manager/orders': 'Orders',
  '/manager/menu': 'Menu',
  '/manager/feedback': 'Feedback',
  '/manager/profile': 'Profile',
};

const ManagerHeader = ({ onRefresh }: ManagerHeaderProps) => {
  const { pathname } = useLocation();
  const pageTitle = TITLES[pathname];

  return (
    <header className={styles.header}>
      <Link to="/manager" className={styles.logoLink}>
        <img src={logoAppIcon} alt="SkipQ@SSM" className={styles.logo} />
      </Link>

      {pageTitle ? (
        <h1 className={styles.title}>{pageTitle}</h1>
      ) : (
        <div className={styles.tagline}>
          <span>Pre-Order</span>
          <span className={styles.taglineSep} aria-hidden="true">
            ·
          </span>
          <span>Pick Up</span>
        </div>
      )}

      {onRefresh ? (
        <button
          type="button"
          className={styles.iconBtn}
          onClick={onRefresh}
          aria-label="Refresh"
        >
          <RefreshCw size={20} />
        </button>
      ) : (
        <span className={styles.spacer} aria-hidden="true" />
      )}
    </header>
  );
};

export default ManagerHeader;
