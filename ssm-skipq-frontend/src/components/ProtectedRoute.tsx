import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import type { UserRole } from '../types/auth';
import { LoadingSpinner } from './ui/UiStates';
import styles from './ProtectedRoute.module.css';

interface ProtectedRouteProps {
  allowedRole: UserRole;
}

const ProtectedRoute = ({ allowedRole }: ProtectedRouteProps) => {
  const { user, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className={styles.loading}>
        <LoadingSpinner label="Signing you in…" />
      </div>
    );
  }

  if (!user) {
    return (
      <Navigate
        to={allowedRole === 'student' ? '/student/login' : '/manager/login'}
        replace
      />
    );
  }

  if (user.role !== allowedRole) {
    return (
      <Navigate
        to={user.role === 'student' ? '/student' : '/manager'}
        replace
      />
    );
  }

  return <Outlet />;
};

export default ProtectedRoute;
