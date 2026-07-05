import { useEffect, useRef } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useToast } from '../../context/ToastContext';
import { fetchMyOrders } from '../../services/orders';
import { joinStudentRoom } from '../../services/socket';
import type { Order } from '../../types/order';
import { getStudentStatusToastTitle } from '../../utils/orderStatusToast';

const StudentOrderToastListener = () => {
  const { user } = useAuth();
  const { addToast } = useToast();
  const statusRef = useRef<Map<string, Order['status']>>(new Map());

  useEffect(() => {
    if (!user || user.role !== 'student') return;

    let cancelled = false;

    fetchMyOrders()
      .then((orders) => {
        if (cancelled) return;
        orders.forEach((order) => {
          statusRef.current.set(order.id, order.status);
        });
      })
      .catch(() => {
        // Orders list unavailable — still listen for live updates
      });

    return () => {
      cancelled = true;
    };
  }, [user]);

  useEffect(() => {
    if (!user || user.role !== 'student') return;

    const socket = joinStudentRoom();

    const handleUpdate = (order: Order) => {
      const previousStatus = statusRef.current.get(order.id);
      const isFirstSeen = previousStatus === undefined;
      const statusChanged = !isFirstSeen && previousStatus !== order.status;
      const title = getStudentStatusToastTitle(order.status);

      if (
        title &&
        (statusChanged || (isFirstSeen && order.status !== 'PENDING'))
      ) {
        addToast({
          variant: 'student',
          title,
          message: `Token ${order.tokenNumber}`,
        });
      }

      statusRef.current.set(order.id, order.status);
    };

    socket.on('order:updated', handleUpdate);

    return () => {
      socket.off('order:updated', handleUpdate);
    };
  }, [user, addToast]);

  return null;
};

export default StudentOrderToastListener;
