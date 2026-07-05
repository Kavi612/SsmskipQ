import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import StudentAuthForm from '../components/auth/StudentAuthForm';
import { LoadingSpinner } from '../components/ui/UiStates';

const StudentLoginPage = () => {
  const { user, isLoading } = useAuth();

  if (isLoading) {
    return <LoadingSpinner label="Loading…" />;
  }

  if (user?.role === 'student') {
    return <Navigate to="/student" replace />;
  }

  if (user?.role === 'manager') {
    return <Navigate to="/manager" replace />;
  }

  return <StudentAuthForm />;
};

export default StudentLoginPage;
