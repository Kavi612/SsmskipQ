import mongoose from 'mongoose';

const counterSchema = new mongoose.Schema({
  dateKey: {
    type: String,
    required: [true, 'Date key is required'],
    unique: true,
    trim: true,
    match: [/^\d{4}-\d{2}-\d{2}$/, 'Date key must be YYYY-MM-DD'],
  },
  sequence: {
    type: Number,
    required: true,
    default: 0,
    min: 0,
  },
});

const Counter = mongoose.model('Counter', counterSchema);

export default Counter;
