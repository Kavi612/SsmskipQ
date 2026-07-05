import { Link } from 'react-router-dom';
import { Bell, Menu } from 'lucide-react';
import logoAppIcon from '../assets/logo-app-icon.png';
import styles from './StudentHeader.module.css';

const StudentHeader = () => {
  return (
    <header className={styles.header}>
      <button type="button" className={styles.iconBtn} aria-label="Menu">
        <Menu size={22} />
      </button>
      <Link to="/student" className={styles.logoLink}>
        <img src={logoAppIcon} alt="SkipQ@SSM" className={styles.logo} />
      </Link>
      <button
        type="button"
        className={styles.iconBtn}
        aria-label="Notifications"
      >
        <Bell size={22} />
      </button>
    </header>
  );
};

export default StudentHeader;
