import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import styles from './StudentProfilePage.module.css';

const StudentProfilePage = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  if (user?.role !== 'student') return null;

  const handleLogout = () => {
    logout();
    navigate('/student/login', { replace: true });
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
          <dt>Mobile</dt>
          <dd>{user.mobile}</dd>
        </div>
      </dl>
      <button type="button" className={styles.logout} onClick={handleLogout}>
        Logout
      </button>
    </div>
  );
};

export default StudentProfilePage;
