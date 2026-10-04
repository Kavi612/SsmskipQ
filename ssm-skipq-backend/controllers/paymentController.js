import crypto from 'crypto';
import Order from '../models/Order.js';
import { formatOrder } from './orderController.js';
import {
  createRazorpayOrder,
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

export const createRazorpayCheckout = async (req, res) => {
  try {
    if (!isRazorpayConfigured()) {
      return res.status(503).json({
        success: false,
        message: 'Razorpay is not configured on the server',
      });
    }

    const order = await Order.findOne({
      _id: req.params.orderId,
      studentId: req.user.id,
    }).populate('studentId', 'name mobile');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    if (order.paymentMethod !== 'RAZORPAY') {
      return res.status(400).json({
        success: false,
        message: 'This order is not configured for online payment',
      });
    }

    if (order.status !== 'CONFIRMED' || order.paymentStatus !== 'PENDING') {
      return res.status(409).json({
        success: false,
        message: 'Payment is available only after the manager accepts the order',
      });
    }

    const razorpayOrder = await createRazorpayOrder({
      amountInr: order.total,
      receipt: order._id.toString(),
      notes: {
        tokenNumber: order.tokenNumber,
        studentId: req.user.id,
      },
    });

    order.razorpayOrderId = razorpayOrder.id;
    await order.save();

    return res.json({
      success: true,
      data: {
        razorpay: {
          orderId: razorpayOrder.id,
          amount: razorpayOrder.amount,
          currency: razorpayOrder.currency,
          keyId: getRazorpayKeyId(),
          testMode: isRazorpayTestMode(),
        },
      },
    });
  } catch (error) {
    console.error('Create Razorpay order error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to start online payment',
    });
  }
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

    if (order.status !== 'CONFIRMED' || order.paymentStatus !== 'PENDING') {
      return res.status(409).json({
        success: false,
        message: 'Payment is available only for accepted, unpaid orders',
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

    if (!order.razorpayOrderId || order.razorpayOrderId !== razorpayOrderId) {
      return res.status(400).json({
        success: false,
        message: 'Razorpay order mismatch',
      });
    }

    const paidOrder = await Order.findOneAndUpdate(
      {
        _id: order._id,
        studentId: req.user.id,
        status: 'CONFIRMED',
        paymentStatus: 'PENDING',
        razorpayOrderId,
      },
      {
        $set: {
          paymentStatus: 'PAID',
          status: 'ACTIVE',
          razorpayPaymentId,
        },
      },
      { new: true },
    ).populate('studentId', 'name mobile');

    if (!paidOrder) {
      return res.status(409).json({
        success: false,
        message: 'Order changed before payment could be confirmed',
      });
    }

    emitOrderUpdate(req, paidOrder);

    return res.json({
      success: true,
      data: { order: formatOrder(paidOrder) },
    });
  } catch (error) {
    console.error('Verify Razorpay payment error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to verify payment',
    });
  }
};
