import mongoose from 'mongoose';

const studentSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Student name is required'],
      trim: true,
      maxlength: 100,
    },
    mobile: {
      type: String,
      required: [true, 'Mobile number is required'],
      unique: true,
      trim: true,
      match: [/^[6-9]\d{9}$/, 'Mobile must be a valid 10-digit Indian number'],
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
  },
);

const Student = mongoose.model('Student', studentSchema);

export default Student;
