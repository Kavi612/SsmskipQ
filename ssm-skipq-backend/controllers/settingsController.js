import CanteenSettings from '../models/CanteenSettings.js';
import { isWithinOrderingWindow } from '../utils/orderingWindow.js';

const DEFAULTS = {
  orderingOpenTime: '09:30',
  orderingCloseTime: '11:30',
};

export const getOrCreateSettings = async () => {
  let settings = await CanteenSettings.findOne().lean();
  if (!settings) {
    settings = await CanteenSettings.create(DEFAULTS);
    settings = settings.toObject();
  }
  return settings;
};

export const getOrderingWindow = async (_req, res) => {
  try {
    const settings = await getOrCreateSettings();
    const isOpen = isWithinOrderingWindow(
      settings.orderingOpenTime,
      settings.orderingCloseTime,
    );

    return res.json({
      success: true,
      data: {
        orderingOpenTime: settings.orderingOpenTime,
        orderingCloseTime: settings.orderingCloseTime,
        isOpen,
      },
    });
  } catch (error) {
    console.error('Get ordering window error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch ordering window',
    });
  }
};

export const updateOrderingWindow = async (req, res) => {
  try {
    const { orderingOpenTime, orderingCloseTime } = req.body;

    if (!orderingOpenTime || !orderingCloseTime) {
      return res.status(400).json({
        success: false,
        message: 'Open and close times are required',
      });
    }

    const timeRegex = /^([01]\d|2[0-3]):[0-5]\d$/;
    if (!timeRegex.test(orderingOpenTime) || !timeRegex.test(orderingCloseTime)) {
      return res.status(400).json({
        success: false,
        message: 'Times must be in HH:mm format (24-hour)',
      });
    }

    if (orderingOpenTime >= orderingCloseTime) {
      return res.status(400).json({
        success: false,
        message: 'Open time must be before close time',
      });
    }

    const settings = await CanteenSettings.findOneAndUpdate(
      {},
      { orderingOpenTime, orderingCloseTime },
      { new: true, upsert: true, setDefaultsOnInsert: true },
    ).lean();

    const isOpen = isWithinOrderingWindow(
      settings.orderingOpenTime,
      settings.orderingCloseTime,
    );

    const io = req.app.get('io');
    io.emit('settings:ordering-window', {
      orderingOpenTime: settings.orderingOpenTime,
      orderingCloseTime: settings.orderingCloseTime,
      isOpen,
    });

    return res.json({
      success: true,
      data: {
        orderingOpenTime: settings.orderingOpenTime,
        orderingCloseTime: settings.orderingCloseTime,
        isOpen,
      },
    });
  } catch (error) {
    console.error('Update ordering window error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to update ordering window',
    });
  }
};

export const assertOrderingOpen = async () => {
  const settings = await getOrCreateSettings();
  const isOpen = isWithinOrderingWindow(
    settings.orderingOpenTime,
    settings.orderingCloseTime,
  );
  return { isOpen, settings };
};
