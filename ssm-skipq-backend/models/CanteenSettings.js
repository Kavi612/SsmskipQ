import mongoose from 'mongoose';

const canteenSettingsSchema = new mongoose.Schema(
  {
    orderingOpenTime: {
      type: String,
      required: true,
      default: '09:30',
      match: [/^([01]\d|2[0-3]):[0-5]\d$/, 'Time must be HH:mm (24h)'],
    },
    orderingCloseTime: {
      type: String,
      required: true,
      default: '11:30',
      match: [/^([01]\d|2[0-3]):[0-5]\d$/, 'Time must be HH:mm (24h)'],
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: true },
  },
);

const CanteenSettings = mongoose.model('CanteenSettings', canteenSettingsSchema);

export default CanteenSettings;
