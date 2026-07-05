import mongoose from 'mongoose';

const menuItemSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Menu item name is required'],
      trim: true,
      maxlength: 150,
    },
    description: {
      type: String,
      trim: true,
      maxlength: 500,
      default: '',
    },
    price: {
      type: Number,
      required: [true, 'Price is required'],
      min: [0, 'Price cannot be negative'],
    },
    category: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      required: [true, 'Category is required'],
    },
    imageUrl: {
      type: String,
      trim: true,
      default: '',
    },
    isVeg: {
      type: Boolean,
      required: true,
      default: true,
    },
    available: {
      type: Boolean,
      required: true,
      default: true,
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
  },
);

menuItemSchema.index({ category: 1, name: 1 });

const MenuItem = mongoose.model('MenuItem', menuItemSchema);

export default MenuItem;
