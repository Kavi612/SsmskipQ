import { CartProvider } from '../context/CartContext';
import { OrderingWindowProvider } from '../context/OrderingWindowContext';
import { ToastProvider } from '../context/ToastContext';
import StudentOrderToastListener from '../components/toast/StudentOrderToastListener';
import StudentLayout from './StudentLayout';

const StudentShell = () => (
  <OrderingWindowProvider>
    <CartProvider>
      <ToastProvider>
        <StudentOrderToastListener />
        <StudentLayout />
      </ToastProvider>
    </CartProvider>
  </OrderingWindowProvider>
);

export default StudentShell;
