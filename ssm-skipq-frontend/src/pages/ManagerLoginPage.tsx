import { useState, type FormEvent } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';
import WelcomeLoginLayout from '../components/onboarding/WelcomeLoginLayout';
import { LoadingSpinner } from '../components/ui/UiStates';
import styles from './ManagerLoginPage.module.css';

const ManagerLoginPage = () => {
  const { user, isLoading, loginManager } = useAuth();
  const navigate = useNavigate();
  const [managerId, setManagerId] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (isLoading) {
    return <LoadingSpinner label="Loading…" />;
  }

  if (user?.role === 'manager') {
    return <Navigate to="/manager" replace />;
  }

  if (user?.role === 'student') {
    return <Navigate to="/student" replace />;
  }

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setError('');
    setIsSubmitting(true);

    try {
      await loginManager(managerId, password);
      navigate('/manager', { replace: true });
    } catch (err) {
      const message =
        axios.isAxiosError(err) && err.response?.data?.message
          ? err.response.data.message
          : 'Invalid Manager ID or password.';
      setError(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <WelcomeLoginLayout
      variant="manager"
      headline="Canteen Manager Portal"
      subtitle="Sign in to manage orders, menu, and daily operations."
      footer={
        <p>
          Student? <Link to="/student/login">Student login</Link>
        </p>
      }
    >
      <form className={styles.form} onSubmit={handleSubmit} noValidate>
        <div className={styles.field}>
          <label htmlFor="managerId" className={styles.label}>
            Manager ID
          </label>
          <input
            id="managerId"
            type="text"
            className={styles.input}
            placeholder="e.g. SSM001"
            value={managerId}
            onChange={(e) => setManagerId(e.target.value.toUpperCase())}
            autoComplete="username"
            required
          />
        </div>

        <div className={styles.field}>
          <label htmlFor="password" className={styles.label}>
            Password
          </label>
          <input
            id="password"
            type="password"
            className={styles.input}
            placeholder="Your password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
            required
          />
        </div>

        {error && <p className={styles.error}>{error}</p>}

        <button type="submit" className={styles.submit} disabled={isSubmitting}>
          {isSubmitting ? 'Signing in…' : 'Sign In'}
        </button>
      </form>
    </WelcomeLoginLayout>
  );
};

export default ManagerLoginPage;
