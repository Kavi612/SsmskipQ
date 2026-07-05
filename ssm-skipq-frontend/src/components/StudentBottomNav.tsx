import { NavLink } from 'react-router-dom';
import { Home, ShoppingCart, ClipboardList, User } from 'lucide-react';
import { useCart } from '../context/CartContext';
import styles from './StudentBottomNav.module.css';

const navItems = [
  { to: '/student', label: 'Home', icon: Home, end: true },
  { to: '/student/cart', label: 'Cart', icon: ShoppingCart, end: false },
  { to: '/student/orders', label: 'Orders', icon: ClipboardList, end: false },
  { to: '/student/profile', label: 'Profile', icon: User, end: false },
];

const StudentBottomNav = () => {
  const { totalItems } = useCart();

  return (
    <nav className={styles.nav}>
      {navItems.map(({ to, label, icon: Icon, end }) => (
        <NavLink
          key={to}
          to={to}
          end={end}
          className={({ isActive }) =>
            `${styles.link} ${isActive ? styles.linkActive : ''}`
          }
        >
          {({ isActive }) => (
            <>
              <span className={styles.iconWrap}>
                <Icon size={22} strokeWidth={isActive ? 2.25 : 1.75} />
                {label === 'Cart' && totalItems > 0 && (
                  <span className={styles.badge}>{totalItems}</span>
                )}
              </span>
              <span className={styles.label}>{label}</span>
            </>
          )}
        </NavLink>
      ))}
    </nav>
  );
};

export default StudentBottomNav;
