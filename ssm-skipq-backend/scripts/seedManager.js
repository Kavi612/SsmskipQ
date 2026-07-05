import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';
import connectDB from '../config/db.js';
import Manager from '../models/Manager.js';

dotenv.config();

const DEFAULT_MANAGER = {
  managerId: 'SSM001',
  password: 'manager123',
  name: 'Canteen Manager',
};

const seedManager = async () => {
  await connectDB();

  const existing = await Manager.findOne({ managerId: DEFAULT_MANAGER.managerId });

  if (existing) {
    console.log(`Manager ${DEFAULT_MANAGER.managerId} already exists — skipping.`);
  } else {
    const passwordHash = await bcrypt.hash(DEFAULT_MANAGER.password, 12);
    await Manager.create({
      managerId: DEFAULT_MANAGER.managerId,
      passwordHash,
      name: DEFAULT_MANAGER.name,
    });
    console.log(`Manager created: ${DEFAULT_MANAGER.managerId}`);
    console.log(`Default password: ${DEFAULT_MANAGER.password}`);
  }

  await mongoose.disconnect();
};

seedManager().catch((error) => {
  console.error('Seed manager failed:', error.message);
  process.exitCode = 1;
});
