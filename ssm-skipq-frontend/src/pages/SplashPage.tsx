import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { useAuth } from '../context/AuthContext';
import StudentAuthForm from '../components/auth/StudentAuthForm';
import { LoadingSpinner } from '../components/ui/UiStates';
import splashHero from '../assets/splash-hero.png';
import styles from './SplashPage.module.css';

const slideTransition = { duration: 0.55, ease: [0.32, 0.72, 0, 1] as const };

const SplashPage = () => {
  const { user, isLoading } = useAuth();
  const reduceMotion = useReducedMotion();
  const [showAuth, setShowAuth] = useState(false);

  if (isLoading) {
    return <LoadingSpinner label="Loading…" />;
  }

  if (user?.role === 'student') {
    return <Navigate to="/student" replace />;
  }

  if (user?.role === 'manager') {
    return <Navigate to="/manager" replace />;
  }

  const handleContinue = () => {
    setShowAuth(true);
  };

  return (
    <div className={styles.root}>
      <motion.div
        className={styles.authLayer}
        initial={false}
        animate={
          reduceMotion
            ? { y: showAuth ? 0 : 0 }
            : { y: showAuth ? '0%' : '100%' }
        }
        transition={reduceMotion ? { duration: 0 } : slideTransition}
      >
        <StudentAuthForm />
      </motion.div>

      <AnimatePresence>
        {!showAuth && (
          <motion.button
            type="button"
            key="splash"
            className={styles.splashLayer}
            onClick={handleContinue}
            aria-label="Tap to continue to login"
            initial={reduceMotion ? false : { opacity: 0, scale: 0.94 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={reduceMotion ? { opacity: 0 } : { y: '-100%' }}
            transition={reduceMotion ? { duration: 0 } : slideTransition}
          >
            <div className={styles.content}>
              <motion.div
                className={styles.heroWrap}
                animate={
                  reduceMotion
                    ? undefined
                    : {
                        y: [0, -10, 0],
                      }
                }
                transition={
                  reduceMotion
                    ? undefined
                    : {
                        duration: 5.5,
                        repeat: Infinity,
                        ease: 'easeInOut',
                      }
                }
              >
                <img
                  src={splashHero}
                  alt=""
                  className={styles.hero}
                  aria-hidden="true"
                />
              </motion.div>

              <h1 className={styles.wordmark}>SkipQ@SSM</h1>
              <p className={styles.tagline}>Skip the Queue. Grab Your Meal.</p>
            </div>

            {!reduceMotion ? (
              <motion.p
                className={styles.tapHint}
                initial={{ opacity: 0 }}
                animate={{ opacity: 0.85 }}
                transition={{ delay: 1.5, duration: 0.8 }}
              >
                Tap to continue
              </motion.p>
            ) : (
              <p className={styles.tapHint}>Tap to continue</p>
            )}
          </motion.button>
        )}
      </AnimatePresence>
    </div>
  );
};

export default SplashPage;
