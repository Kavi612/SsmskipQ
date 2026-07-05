import mongoose from 'mongoose';
import Order from '../models/Order.js';
import Counter from '../models/Counter.js';
import MenuItem from '../models/MenuItem.js';
import Feedback from '../models/Feedback.js';
import { getTodayDateKey, formatTokenNumber } from '../utils/token.js';
import { assertOrderingOpen } from '../controllers/settingsController.js';

const STATUS_FLOW = {
  PENDING: 'CONFIRMED',
  CONFIRMED: 'PREPARING',
  PREPARING: 'READY',
  READY: 'PICKED_UP',
};

const STATUS_ACTION_LABELS = {
  PENDING: 'Accept',
  CONFIRMED: 'Preparing',
  PREPARING: 'Ready',
  READY: 'Collected',
};

export const formatOrder = (order) => ({
  id: order._id?.toString?.() ?? order.id,
  studentId: order.studentId?._id?.toString?.() ?? order.studentId?.toString?.() ?? order.studentId,
  student: order.studentId?.name
    ? {
        name: order.studentId.name,
        mobile: order.studentId.mobile,
      }
    : order.student ?? undefined,
  items: order.items,
  total: order.total,
  paymentMethod: order.paymentMethod,
  paymentStatus: order.paymentStatus,
  status: order.status,
  tokenNumber: order.tokenNumber,
  createdAt: order.createdAt,
});

const emitOrderUpdate = (req, order) => {
  const formatted = formatOrder(order);
  const io = req.app.get('io');
  io.to('manager').emit('order:updated', formatted);
  io.to(`student:${formatted.studentId}`).emit('order:updated', formatted);
};

export const createOrder = async (req, res) => {
  const session = await mongoose.startSession();

  try {
    const { isOpen } = await assertOrderingOpen();
    if (!isOpen) {
      return res.status(403).json({
        success: false,
        message:
          'Ordering is closed. Please visit the canteen directly.',
      });
    }

    const { items, paymentMethod } = req.body;
    const studentId = req.user.id;

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Order must contain at least one item',
      });
    }

    const validMethods = ['GOOGLE_PAY', 'PHONEPE', 'PAY_AT_COUNTER'];
    if (!validMethods.includes(paymentMethod)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment method',
      });
    }

    const paymentStatus =
      paymentMethod === 'PAY_AT_COUNTER' ? 'PENDING' : 'PAID';

    for (const item of items) {
      if (!item.menuItemId || !item.quantity) {
        return res.status(400).json({
          success: false,
          message: 'Each item must include menuItemId and quantity',
        });
      }

      if (!Number.isInteger(item.quantity) || item.quantity < 1) {
        return res.status(400).json({
          success: false,
          message: 'Each item quantity must be a positive integer',
        });
      }
    }

    const menuItemIds = items.map((item) => item.menuItemId);
    const menuItems = await MenuItem.find({ _id: { $in: menuItemIds } });

    if (menuItems.length !== items.length) {
      return res.status(400).json({
        success: false,
        message: 'One or more menu items are invalid',
      });
    }

    const menuById = new Map(
      menuItems.map((menuItem) => [menuItem._id.toString(), menuItem]),
    );

    const unavailable = menuItems.filter((m) => !m.available);
    if (unavailable.length > 0) {
      return res.status(400).json({
        success: false,
        message: `${unavailable[0].name} is currently sold out`,
      });
    }

    const normalizedItems = items.map((item) => {
      const menuItem = menuById.get(item.menuItemId.toString());
      return {
        menuItemId: menuItem._id,
        name: menuItem.name,
        price: menuItem.price,
        quantity: item.quantity,
      };
    });

    const calculatedTotal = normalizedItems.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0,
    );

    if (
      req.body.total != null &&
      Math.abs(calculatedTotal - Number(req.body.total)) > 0.01
    ) {
      return res.status(400).json({
        success: false,
        message: 'Order total does not match item prices',
      });
    }

    const dateKey = getTodayDateKey();
    let createdOrder;

    await session.withTransaction(async () => {
      const counter = await Counter.findOneAndUpdate(
        { dateKey },
        { $inc: { sequence: 1 } },
        { new: true, upsert: true, session },
      );

      const tokenNumber = formatTokenNumber(counter.sequence);

      const [order] = await Order.create(
        [
          {
            studentId,
            items: normalizedItems,
            total: calculatedTotal,
            paymentMethod,
            paymentStatus,
            status: 'PENDING',
            tokenNumber,
          },
        ],
        { session },
      );

      createdOrder = order;
    });

    const populated = await Order.findById(createdOrder._id)
      .populate('studentId', 'name mobile')
      .lean();

    const formatted = formatOrder(populated);
    const io = req.app.get('io');

    io.to('manager').emit('order:created', formatted);
    io.to(`student:${studentId}`).emit('order:updated', formatted);

    return res.status(201).json({
      success: true,
      data: { order: formatted },
    });
  } catch (error) {
    console.error('Create order error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to place order',
    });
  } finally {
    session.endSession();
  }
};

export const getMyOrders = async (req, res) => {
  try {
    const studentId = req.user.id;

    const [orders, feedbackRows] = await Promise.all([
      Order.find({ studentId }).sort({ createdAt: -1 }).lean(),
      Feedback.find({ studentId }).select('orderId').lean(),
    ]);

    const feedbackOrderIds = new Set(
      feedbackRows.map((row) => row.orderId.toString()),
    );

    return res.json({
      success: true,
      data: {
        orders: orders.map((order) => ({
          id: order._id,
          studentId: order.studentId,
          items: order.items,
          total: order.total,
          paymentMethod: order.paymentMethod,
          paymentStatus: order.paymentStatus,
          status: order.status,
          tokenNumber: order.tokenNumber,
          createdAt: order.createdAt,
          hasFeedback: feedbackOrderIds.has(order._id.toString()),
        })),
      },
    });
  } catch (error) {
    console.error('Get orders error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch orders',
    });
  }
};

export const getManagerOrders = async (_req, res) => {
  try {
    const orders = await Order.find()
      .populate('studentId', 'name mobile')
      .sort({ createdAt: -1 })
      .lean();

    return res.json({
      success: true,
      data: {
        orders: orders.map(formatOrder),
        statusFlow: STATUS_FLOW,
        statusActionLabels: STATUS_ACTION_LABELS,
      },
    });
  } catch (error) {
    console.error('Get manager orders error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch orders',
    });
  }
};

export const advanceOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const order = await Order.findById(id).populate('studentId', 'name mobile');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    const nextStatus = STATUS_FLOW[order.status];
    if (!nextStatus) {
      return res.status(400).json({
        success: false,
        message: `Cannot advance order from status ${order.status}`,
      });
    }

    order.status = nextStatus;
    await order.save();

    emitOrderUpdate(req, order);

    return res.json({
      success: true,
      data: { order: formatOrder(order) },
    });
  } catch (error) {
    console.error('Advance order status error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to update order status',
    });
  }
};

export const updateOrderPayment = async (req, res) => {
  try {
    const { id } = req.params;
    const { paymentStatus } = req.body;

    if (!['PENDING', 'PAID'].includes(paymentStatus)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment status',
      });
    }

    const order = await Order.findById(id).populate('studentId', 'name mobile');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    if (order.paymentMethod !== 'PAY_AT_COUNTER') {
      return res.status(400).json({
        success: false,
        message: 'Payment status can only be toggled for counter payments',
      });
    }

    order.paymentStatus = paymentStatus;
    await order.save();

    emitOrderUpdate(req, order);

    return res.json({
      success: true,
      data: { order: formatOrder(order) },
    });
  } catch (error) {
    console.error('Update order payment error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to update payment status',
    });
  }
};
