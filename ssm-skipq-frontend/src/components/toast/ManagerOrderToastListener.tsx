import { useEffect } from 'react';
import { useToast } from '../../context/ToastContext';
import { joinManagerRoom } from '../../services/socket';
import type { Order } from '../../types/order';
import { playNewOrderSound } from '../../utils/playNewOrderSound';

const ManagerOrderToastListener = () => {
  const { addToast } = useToast();

  useEffect(() => {
    const socket = joinManagerRoom();

    const handleCreated = (order: Order) => {
      const studentName = order.student?.name;
      addToast({
        variant: 'manager',
        title: 'New Order',
        message: `${order.tokenNumber} · ₹${order.total}${studentName ? ` · ${studentName}` : ''}`,
        durationMs: 6000,
      });
      playNewOrderSound();
    };

    socket.on('order:created', handleCreated);

    return () => {
      socket.off('order:created', handleCreated);
    };
  }, [addToast]);

  return null;
};

export default ManagerOrderToastListener;
