import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import styles from './ManagerProfilePage.module.css';

const ManagerProfilePage = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  if (user?.role !== 'manager') return null;

  const handleLogout = () => {
    logout();
    navigate('/manager/login', { replace: true });
  };

  return (
    <div className={styles.page}>
      <h1 className={styles.title}>Profile</h1>
      <dl className={styles.details}>
        <div className={styles.row}>
          <dt>Name</dt>
          <dd>{user.name}</dd>
        </div>
        <div className={styles.row}>
          <dt>Manager ID</dt>
          <dd>{user.managerId}</dd>
        </div>
      </dl>
      <button type="button" className={styles.logout} onClick={handleLogout}>
        Logout
      </button>
    </div>
  );
};

export default ManagerProfilePage;
