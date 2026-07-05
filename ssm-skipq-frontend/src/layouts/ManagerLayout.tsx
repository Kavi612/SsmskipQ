import { useCallback, useState } from 'react';
import { Outlet, useOutletContext } from 'react-router-dom';
import ManagerNav from '../components/ManagerNav';
import ManagerHeader from '../components/ManagerHeader';
import ManagerBottomNav from '../components/ManagerBottomNav';
import ManagerOrderToastListener from '../components/toast/ManagerOrderToastListener';
import { ToastProvider } from '../context/ToastContext';
import styles from './ManagerLayout.module.css';

export type ManagerOutletContext = {
  setHeaderRefresh: (handler: (() => void) | null) => void;
};

export const useManagerOutlet = () => useOutletContext<ManagerOutletContext>();

const ManagerLayout = () => {
  const [headerRefresh, setHeaderRefresh] = useState<(() => void) | null>(null);

  const handleRefresh = useCallback(() => {
    headerRefresh?.();
  }, [headerRefresh]);

  return (
    <ToastProvider>
      <ManagerOrderToastListener />
      <div className={styles.layout}>
        <ManagerHeader onRefresh={headerRefresh ? handleRefresh : undefined} />
        <div className={styles.body}>
          <ManagerNav />
          <main className={styles.main}>
            <Outlet context={{ setHeaderRefresh }} />
          </main>
        </div>
        <ManagerBottomNav />
      </div>
    </ToastProvider>
  );
};

export default ManagerLayout;
