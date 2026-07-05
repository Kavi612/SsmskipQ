import { Link, useLocation } from 'react-router-dom';
import { Menu, RefreshCw } from 'lucide-react';
import logoAppIcon from '../assets/logo-app-icon.png';
import styles from './ManagerHeader.module.css';

interface ManagerHeaderProps {
  onRefresh?: () => void;
}

const TITLES: Record<string, string> = {
  '/manager': 'Dashboard',
  '/manager/orders': 'Orders',
  '/manager/menu': 'Menu',
  '/manager/feedback': 'Feedback',
  '/manager/profile': 'Profile',
};

const ManagerHeader = ({ onRefresh }: ManagerHeaderProps) => {
  const { pathname } = useLocation();
  const title = TITLES[pathname] ?? 'SkipQ';

  return (
    <header className={styles.header}>
      <button type="button" className={styles.iconBtn} aria-label="Menu">
        <Menu size={22} />
      </button>
      {pathname === '/manager' ? (
        <Link to="/manager" className={styles.logoLink}>
          <img src={logoAppIcon} alt="SkipQ@SSM" className={styles.logo} />
        </Link>
      ) : (
        <h1 className={styles.title}>{title}</h1>
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
        <span className={styles.spacer} />
      )}
    </header>
  );
};

export default ManagerHeader;
