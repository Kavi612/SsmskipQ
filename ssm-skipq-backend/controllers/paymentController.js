import crypto from 'crypto';
import Order from '../models/Order.js';
import { formatOrder } from './orderController.js';
import {
  getRazorpayKeyId,
  isRazorpayConfigured,
  isRazorpayTestMode,
} from '../config/razorpay.js';

const emitOrderUpdate = (req, order) => {
  const formatted = formatOrder(order);
  const io = req.app.get('io');
  io.to('manager').emit('order:updated', formatted);
  io.to(`student:${formatted.studentId}`).emit('order:updated', formatted);
};

export const getPaymentConfig = (_req, res) => {
  return res.json({
    success: true,
    data: {
      razorpay: {
        enabled: isRazorpayConfigured(),
        keyId: isRazorpayConfigured() ? getRazorpayKeyId() : '',
        testMode: isRazorpayConfigured() ? isRazorpayTestMode() : false,
      },
    },
  });
};

export const verifyRazorpayPayment = async (req, res) => {
  try {
    if (!isRazorpayConfigured()) {
      return res.status(503).json({
        success: false,
        message: 'Razorpay is not configured on the server',
      });
    }

    const {
      orderId,
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature,
    } = req.body;

    if (!orderId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({
        success: false,
        message: 'Missing Razorpay payment details',
      });
    }

    const order = await Order.findById(orderId).populate('studentId', 'name mobile');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    if (order.studentId._id.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'You cannot verify payment for this order',
      });
    }

    if (order.paymentMethod !== 'RAZORPAY') {
      return res.status(400).json({
        success: false,
        message: 'This order is not a Razorpay payment',
      });
    }

    if (order.paymentStatus === 'PAID') {
      return res.json({
        success: true,
        data: { order: formatOrder(order) },
      });
    }

    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest('hex');

    if (expectedSignature !== razorpaySignature) {
      return res.status(400).json({
        success: false,
        message: 'Payment verification failed',
      });
    }

    if (order.razorpayOrderId && order.razorpayOrderId !== razorpayOrderId) {
      return res.status(400).json({
        success: false,
        message: 'Razorpay order mismatch',
      });
    }

    order.paymentStatus = 'PAID';
    order.razorpayOrderId = razorpayOrderId;
    order.razorpayPaymentId = razorpayPaymentId;
    await order.save();

    emitOrderUpdate(req, order);

    return res.json({
      success: true,
      data: { order: formatOrder(order) },
    });
  } catch (error) {
    console.error('Verify Razorpay payment error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to verify payment',
    });
  }
};
