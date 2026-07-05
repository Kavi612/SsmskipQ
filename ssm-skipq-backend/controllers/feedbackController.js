import Feedback from '../models/Feedback.js';
import Order from '../models/Order.js';

export const formatFeedback = (feedback) => ({
  id: feedback._id?.toString?.() ?? feedback.id,
  orderId: feedback.orderId?._id?.toString?.() ?? feedback.orderId?.toString?.() ?? feedback.orderId,
  rating: feedback.rating,
  review: feedback.review ?? '',
  createdAt: feedback.createdAt,
  student: feedback.studentId?.name
    ? {
        name: feedback.studentId.name,
        mobile: feedback.studentId.mobile,
      }
    : feedback.student ?? undefined,
  order: feedback.orderId?.items
    ? {
        tokenNumber: feedback.orderId.tokenNumber,
        items: feedback.orderId.items,
        total: feedback.orderId.total,
        createdAt: feedback.orderId.createdAt,
      }
    : feedback.order ?? undefined,
});

export const submitOrderFeedback = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating, review = '' } = req.body;
    const studentId = req.user.id;

    const parsedRating = Number(rating);
    if (
      !Number.isInteger(parsedRating) ||
      parsedRating < 1 ||
      parsedRating > 5
    ) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be an integer between 1 and 5',
      });
    }

    if (typeof review !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Review must be a string',
      });
    }

    const trimmedReview = review.trim();
    if (trimmedReview.length > 1000) {
      return res.status(400).json({
        success: false,
        message: 'Review cannot exceed 1000 characters',
      });
    }

    const order = await Order.findOne({ _id: id, studentId });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    if (order.status !== 'PICKED_UP') {
      return res.status(400).json({
        success: false,
        message: 'Feedback is available after your order is collected',
      });
    }

    const existing = await Feedback.findOne({ orderId: id });
    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'Feedback has already been submitted for this order',
      });
    }

    const feedback = await Feedback.create({
      orderId: id,
      studentId,
      rating: parsedRating,
      review: trimmedReview,
    });

    return res.status(201).json({
      success: true,
      data: {
        feedback: formatFeedback(feedback.toObject()),
      },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: 'Feedback has already been submitted for this order',
      });
    }

    console.error('Submit feedback error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to submit feedback',
    });
  }
};

export const getManagerFeedback = async (_req, res) => {
  try {
    const feedbacks = await Feedback.find()
      .populate('orderId', 'items tokenNumber total createdAt')
      .populate('studentId', 'name mobile')
      .sort({ createdAt: -1 })
      .lean();

    return res.json({
      success: true,
      data: {
        feedback: feedbacks.map(formatFeedback),
      },
    });
  } catch (error) {
    console.error('Get manager feedback error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch feedback',
    });
  }
};
