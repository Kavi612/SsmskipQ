import { useMemo, useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useAuth } from '../../context/AuthContext';
import WelcomeLoginLayout from '../onboarding/WelcomeLoginLayout';
import {
  getMobileErrorImmediate,
  getNameErrorImmediate,
  validateStudentMobile,
  validateStudentName,
} from '../../utils/studentLoginValidation';
import styles from './StudentAuthForm.module.css';

export type AuthMode = 'register' | 'login';

interface FlowError {
  message: string;
  switchTo: AuthMode;
}

interface StudentAuthFormProps {
  initialMode?: AuthMode;
}

const StudentAuthForm = ({ initialMode = 'login' }: StudentAuthFormProps) => {
  const { registerStudent, loginStudent } = useAuth();
  const navigate = useNavigate();
  const [mode, setMode] = useState<AuthMode>(initialMode);
  const [name, setName] = useState('');
  const [mobile, setMobile] = useState('');
  const [flowError, setFlowError] = useState<FlowError | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showNameError, setShowNameError] = useState(false);
  const [showMobileError, setShowMobileError] = useState(false);

  const nameError = useMemo(() => getNameErrorImmediate(name), [name]);
  const mobileError = useMemo(() => getMobileErrorImmediate(mobile), [mobile]);

  const isRegister = mode === 'register';

  const isFormValid = isRegister
    ? validateStudentName(name) === null &&
      validateStudentMobile(mobile) === null
    : validateStudentMobile(mobile) === null;

  const switchMode = (next: AuthMode) => {
    setMode(next);
    setFlowError(null);
    setShowNameError(false);
    setShowMobileError(false);
  };

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setShowMobileError(true);

    const mobileValidation = validateStudentMobile(mobile);
    if (mobileValidation) return;

    if (isRegister) {
      setShowNameError(true);
      const nameValidation = validateStudentName(name);
      if (nameValidation) return;
    }

    setFlowError(null);
    setIsSubmitting(true);

    try {
      if (isRegister) {
        await registerStudent(name.trim(), mobile);
      } else {
        await loginStudent(mobile);
      }
      navigate('/student', { replace: true });
    } catch (err) {
      if (axios.isAxiosError(err) && err.response?.data?.message) {
        const status = err.response.status;
        const message = err.response.data.message as string;

        if (status === 409) {
          setFlowError({ message, switchTo: 'login' });
        } else if (status === 404) {
          setFlowError({ message, switchTo: 'register' });
        } else {
          setFlowError({ message, switchTo: mode });
        }
      } else {
        setFlowError({
          message: 'Unable to connect. Please try again.',
          switchTo: mode,
        });
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <WelcomeLoginLayout
      variant="student"
      headline="SSM's Own Canteen Pre-Order App"
      footer={
        <Link to="/manager/login" className={styles.staffLink}>
          Canteen Staff Login
        </Link>
      }
    >
      <div className={styles.modeToggle} role="tablist" aria-label="Auth mode">
        <button
          type="button"
          role="tab"
          aria-selected={isRegister}
          className={`${styles.modeBtn} ${isRegister ? styles.modeBtnActive : ''}`}
          onClick={() => switchMode('register')}
        >
          Register
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={!isRegister}
          className={`${styles.modeBtn} ${!isRegister ? styles.modeBtnActive : ''}`}
          onClick={() => switchMode('login')}
        >
          Login
        </button>
      </div>

      <form className={styles.form} onSubmit={handleSubmit} noValidate>
        {isRegister && (
          <div className={styles.field}>
            <label htmlFor="name" className={styles.label}>
              Full Name
            </label>
            <input
              id="name"
              type="text"
              className={`${styles.input} ${showNameError && nameError ? styles.inputInvalid : ''}`}
              placeholder="Your name"
              value={name}
              onChange={(e) => {
                setName(e.target.value.replace(/[^A-Za-z ]/g, ''));
                setShowNameError(true);
                setFlowError(null);
              }}
              onBlur={() => setShowNameError(true)}
              autoComplete="name"
              aria-invalid={showNameError && !!nameError}
              aria-describedby={nameError ? 'name-error' : undefined}
            />
            {showNameError && nameError && (
              <p id="name-error" className={styles.fieldError} role="alert">
                {nameError}
              </p>
            )}
          </div>
        )}

        <div className={styles.field}>
          <label htmlFor="mobile" className={styles.label}>
            Mobile Number
          </label>
          <input
            id="mobile"
            type="tel"
            className={`${styles.input} ${showMobileError && mobileError ? styles.inputInvalid : ''}`}
            placeholder="10-digit mobile number"
            value={mobile}
            onChange={(e) => {
              setMobile(e.target.value.replace(/\D/g, '').slice(0, 10));
              setShowMobileError(true);
              setFlowError(null);
            }}
            onBlur={() => setShowMobileError(true)}
            autoComplete="tel"
            inputMode="numeric"
            aria-invalid={showMobileError && !!mobileError}
            aria-describedby={
              showMobileError && mobileError ? 'mobile-error' : undefined
            }
          />
          {showMobileError && mobileError && (
            <p id="mobile-error" className={styles.fieldError} role="alert">
              {mobileError}
            </p>
          )}
        </div>

        {flowError && (
          <div className={styles.flowError} role="alert">
            <p>{flowError.message}</p>
            {flowError.switchTo !== mode && (
              <button
                type="button"
                className={styles.switchLink}
                onClick={() => switchMode(flowError.switchTo)}
              >
                Switch to{' '}
                {flowError.switchTo === 'login' ? 'Login' : 'Register'}
              </button>
            )}
          </div>
        )}

        <button
          type="submit"
          className={styles.submit}
          disabled={isSubmitting || !isFormValid}
        >
          {isSubmitting
            ? isRegister
              ? 'Creating account…'
              : 'Signing in…'
            : isRegister
              ? 'Register'
              : 'Login'}
        </button>
      </form>
    </WelcomeLoginLayout>
  );
};

export default StudentAuthForm;
