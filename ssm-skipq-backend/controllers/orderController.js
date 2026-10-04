import mongoose from 'mongoose';
import Order from '../models/Order.js';
import Counter from '../models/Counter.js';
import MenuItem from '../models/MenuItem.js';
import Feedback from '../models/Feedback.js';
import { getTodayDateKey, formatTokenNumber, getTodayStartIst } from '../utils/token.js';
import { assertOrderingOpen } from '../controllers/settingsController.js';

const STATUS_FLOW = {
  PENDING: 'CONFIRMED',
  CONFIRMED: 'ACTIVE',
  ACTIVE: 'PICKED_UP',
  PREPARING: 'READY',
  READY: 'PICKED_UP',
};

const STATUS_ACTION_LABELS = {
  PENDING: 'Accept',
  CONFIRMED: 'Collected',
  ACTIVE: 'Collected',
  PREPARING: 'Ready',
  READY: 'Collected',
};

const getDateRange = (range, customStart, customEnd) => {
  const now = new Date();
  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);

  let start = new Date(startOfToday);
  let end = new Date(now);

  switch (range) {
    case 'week':
      start.setDate(start.getDate() - 6);
      break;
    case 'month':
      start.setMonth(start.getMonth() - 1);
      break;
    case 'year':
      start.setFullYear(start.getFullYear() - 1);
      break;
    case 'custom':
      if (customStart) {
        start = new Date(customStart);
      }
      if (customEnd) {
        end = new Date(customEnd);
        end.setHours(23, 59, 59, 999);
      }
      break;
    case 'day':
    default:
      start = new Date(startOfToday);
      break;
  }

  return { start, end };
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
  cancelledBy: order.cancelledBy,
  cancelledAt: order.cancelledAt,
  tokenNumber: order.tokenNumber,
  createdAt: order.createdAt,
  note: order.note ?? '',
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
    const isPreBook = req.body.isPreBook === true;
    if (!isOpen && !isPreBook) {
      return res.status(403).json({
        success: false,
        message: 'Ordering is closed. Choose Pre-book to place a future order.',
      });
    }
    const initialStatus = isPreBook && !isOpen ? 'PRE_BOOKED' : 'PENDING';

    const { items, paymentMethod, note } = req.body;
    const studentId = req.user.id;
    const trimmedNote = typeof note === 'string' ? note.trim() : '';

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Order must contain at least one item',
      });
    }

    const validMethods = ['RAZORPAY'];
    if (!validMethods.includes(paymentMethod)) {
      return res.status(400).json({
        success: false,
        message: 'Only online Razorpay payments are supported',
      });
    }

    const paymentStatus = 'PENDING';

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
            status: initialStatus,
            tokenNumber,
            note: trimmedNote,
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
      data: {
        order: formatted,
      },
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
      Order.find({ studentId })
        .sort({ createdAt: -1 })
        .lean(),
      Feedback.find({ studentId }).select('orderId rating review').lean(),
    ]);

    const feedbackOrderIds = new Set(
      feedbackRows.map((row) => row.orderId.toString()),
    );
    const feedbackByOrderId = new Map(
      feedbackRows.map((row) => [row.orderId.toString(), row]),
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
          note: order.note ?? '',
          hasFeedback: feedbackOrderIds.has(order._id.toString()),
          feedback: feedbackByOrderId.has(order._id.toString())
            ? {
                rating: feedbackByOrderId.get(order._id.toString()).rating,
                review: feedbackByOrderId.get(order._id.toString()).review ?? '',
              }
            : null,
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

export const getMyOrderById = async (req, res) => {
  try {
    const order = await Order.findOne({
      _id: req.params.id,
      studentId: req.user.id,
    }).lean();

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    const hasFeedback = await Feedback.exists({
      orderId: order._id,
      studentId: req.user.id,
    });
    const feedback = hasFeedback
      ? await Feedback.findOne({
          orderId: order._id,
          studentId: req.user.id,
        })
          .select('rating review')
          .lean()
      : null;

    return res.json({
      success: true,
      data: {
        order: {
          ...formatOrder(order),
          hasFeedback: Boolean(hasFeedback),
          feedback: feedback
            ? { rating: feedback.rating, review: feedback.review ?? '' }
            : null,
        },
      },
    });
  } catch (error) {
    if (error instanceof mongoose.Error.CastError) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    console.error('Get student order error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch order',
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

export const getManagerPrebookAnalytics = async (_req, res) => {
  try {
    const orders = await Order.find({ status: 'PRE_BOOKED' })
      .select('items')
      .lean();
    const menuItemIds = [
      ...new Set(
        orders.flatMap((order) =>
          order.items.map((item) => item.menuItemId?.toString()).filter(Boolean),
        ),
      ),
    ];
    const menuItems = await MenuItem.find({ _id: { $in: menuItemIds } })
      .select('name category')
      .populate('category', 'name')
      .lean();
    const menuById = new Map(
      menuItems.map((item) => [item._id.toString(), item]),
    );
    const categoryTotals = new Map();

    for (const order of orders) {
      for (const line of order.items) {
        const menuItem = menuById.get(line.menuItemId?.toString());
        const categoryId = menuItem?.category?._id?.toString() ?? 'uncategorized';
        const categoryName = menuItem?.category?.name ?? 'Other';
        let category = categoryTotals.get(categoryId);
        if (!category) {
          category = {
            id: categoryId,
            name: categoryName,
            totalQuantity: 0,
            items: new Map(),
          };
          categoryTotals.set(categoryId, category);
        }
        const itemId = line.menuItemId?.toString() ?? line.name;
        const item = category.items.get(itemId) ?? {
          id: itemId,
          name: menuItem?.name ?? line.name,
          quantity: 0,
        };
        item.quantity += line.quantity;
        category.items.set(itemId, item);
        category.totalQuantity += line.quantity;
      }
    }

    const categories = [...categoryTotals.values()]
      .map((category) => ({
        ...category,
        items: [...category.items.values()].sort((a, b) =>
          a.name.localeCompare(b.name),
        ),
      }))
      .sort((a, b) => b.totalQuantity - a.totalQuantity);

    return res.json({
      success: true,
      data: { categories },
    });
  } catch (error) {
    console.error('Get pre-book analytics error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch pre-book analytics',
    });
  }
};

export const convertPrebookOrdersIfOpen = async (io) => {
  const { isOpen } = await assertOrderingOpen();
  if (!isOpen) return 0;

  const pendingPrebooks = await Order.find({ status: 'PRE_BOOKED' })
    .select('_id')
    .lean();
  let converted = 0;

  for (const prebook of pendingPrebooks) {
    const order = await Order.findOneAndUpdate(
      { _id: prebook._id, status: 'PRE_BOOKED' },
      { $set: { status: 'PENDING' } },
      { new: true },
    ).populate('studentId', 'name mobile');
    if (!order) continue;

    const formatted = formatOrder(order);
    io.to('manager').emit('order:updated', formatted);
    io.to(`student:${formatted.studentId}`).emit('order:updated', formatted);
    converted++;
  }

  return converted;
};

export const getOrderAnalytics = async (req, res) => {
  try {
    const range = req.query.range || 'day';
    const { start, end } = getDateRange(
      Array.isArray(range) ? range[0] : range,
      req.query.startDate,
      req.query.endDate,
    );

    const orders = await Order.find({
      createdAt: { $gte: start, $lte: end },
    }).lean();

    let totalRevenue = 0;
    let completedOrders = 0;
    const itemMap = new Map();

    for (const order of orders) {
      if (order.status === 'PICKED_UP') {
        totalRevenue += Number(order.total || 0);
        completedOrders += 1;
      }

      for (const item of order.items || []) {
        const itemName = item.name || 'Unknown';
        const current = itemMap.get(itemName) || {
          name: itemName,
          quantity: 0,
          revenue: 0,
        };

        current.quantity += Number(item.quantity || 0);
        current.revenue += Number((item.price || 0) * (item.quantity || 0));
        itemMap.set(itemName, current);
      }
    }

    const topItems = [...itemMap.values()]
      .sort((a, b) => {
        const quantityOrder = b.quantity - a.quantity;
        if (quantityOrder !== 0) return quantityOrder;
        return b.revenue - a.revenue;
      })
      .slice(0, 5)
      .map((item) => ({
        name: item.name,
        quantity: item.quantity,
        revenue: Number(item.revenue.toFixed(2)),
      }));

    return res.json({
      success: true,
      data: {
        analytics: {
          totalOrders: orders.length,
          totalRevenue: Number(totalRevenue.toFixed(2)),
          completedOrders,
          topItems,
        },
      },
    });
  } catch (error) {
    console.error('Get order analytics error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to calculate analytics',
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
    if (order.status === 'CONFIRMED' && order.paymentStatus !== 'PAID') {
      return res.status(409).json({
        success: false,
        message: 'Accepted orders must be paid before preparation can begin',
      });
    }
    if (!nextStatus) {
      return res.status(400).json({
        success: false,
        message: `Cannot advance order from status ${order.status}`,
      });
    }

    const wasPending = order.status === 'PENDING';
    order.status = nextStatus;
    await order.save();

    emitOrderUpdate(req, order);

    if (wasPending && nextStatus === 'CONFIRMED') {
      req.app.get('io').to(`student:${order.studentId._id}`).emit(
        'order:accepted',
        {
          orderId: order._id.toString(),
          title: 'Order accepted',
          body: 'Order accepted — please pay now to confirm.',
        },
      );
    }

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

export const cancelOrder = async (req, res) => {
  try {
    const order = await Order.findOneAndUpdate(
      {
        _id: req.params.id,
        studentId: req.user.id,
        status: { $in: ['PRE_BOOKED', 'PENDING', 'CONFIRMED'] },
        paymentStatus: 'PENDING',
      },
      { $set: { status: 'CANCELLED', cancelledBy: 'STUDENT', cancelledAt: new Date() } },
      { new: true },
    ).populate('studentId', 'name mobile');

    if (order) {
      emitOrderUpdate(req, order);
      return res.json({
        success: true,
        data: { order: formatOrder(order) },
      });
    }

    const existing = await Order.findOne({
      _id: req.params.id,
      studentId: req.user.id,
    }).select('status');

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    return res.status(409).json({
      success: false,
      message: 'Only unpaid orders can be cancelled.',
    });
  } catch (error) {
    console.error('Cancel order error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to cancel order',
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
        message: 'Payment status can only be updated for counter payments',
      });
    }

    if (paymentStatus !== 'PAID') {
      return res.status(400).json({
        success: false,
        message: 'Only payment received is supported',
      });
    }

    if (order.paymentStatus === 'PAID') {
      return res.status(400).json({
        success: false,
        message: 'Payment already received',
      });
    }

    order.paymentStatus = 'PAID';
    if (order.status === 'CONFIRMED') order.status = 'ACTIVE';
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
