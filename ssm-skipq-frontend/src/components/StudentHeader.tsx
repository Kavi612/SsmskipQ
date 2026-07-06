import { Link } from 'react-router-dom';
import logoAppIcon from '../assets/logo-app-icon.png';
import styles from './StudentHeader.module.css';

const StudentHeader = () => {
  return (
    <header className={styles.header}>
      <Link to="/student" className={styles.logoLink}>
        <img src={logoAppIcon} alt="SkipQ@SSM" className={styles.logo} />
      </Link>

      <div className={styles.tagline}>
        <span>Pre-Order</span>
        <span className={styles.taglineSep} aria-hidden="true">
          ·
        </span>
        <span>Pick Up</span>
      </div>

      <span className={styles.spacer} aria-hidden="true" />
    </header>
  );
};

export default StudentHeader;
