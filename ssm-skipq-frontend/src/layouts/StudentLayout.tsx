import { Outlet, useLocation } from 'react-router-dom';
import StudentHeader from '../components/StudentHeader';
import StudentBottomNav from '../components/StudentBottomNav';
import styles from './StudentLayout.module.css';

const StudentLayout = () => {
  const location = useLocation();
  const isHome = location.pathname === '/student';

  return (
    <div className={styles.layout}>
      {isHome && <StudentHeader />}
      <main className={styles.main}>
        <Outlet />
      </main>
      <StudentBottomNav />
    </div>
  );
};

export default StudentLayout;
