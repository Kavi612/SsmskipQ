import dotenv from 'dotenv';
import mongoose from 'mongoose';
import connectDB from '../config/db.js';
import {
  Student,
  Manager,
  Category,
  MenuItem,
  Order,
  Counter,
  Feedback,
} from '../models/index.js';

dotenv.config();

const MODELS = [
  Student,
  Manager,
  Category,
  MenuItem,
  Order,
  Counter,
  Feedback,
];

const testConnection = async () => {
  console.log('Connecting to MongoDB...\n');

  await connectDB();

  console.log('Registered models:');
  MODELS.forEach((model) => {
    console.log(`  - ${model.modelName}`);
  });

  const collections = await mongoose.connection.db.listCollections().toArray();
  const collectionNames = collections.map((c) => c.name).sort();

  console.log('\nExisting collections in database:');
  if (collectionNames.length === 0) {
    console.log('  (none yet — collections are created on first write)');
  } else {
    collectionNames.forEach((name) => console.log(`  - ${name}`));
  }

  const ping = await mongoose.connection.db.admin().ping();
  console.log('\nMongoDB ping:', ping.ok ? 'OK' : 'FAILED');

  console.log('\nConnection test passed.');
};

testConnection()
  .catch((error) => {
    console.error('\nConnection test failed:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB.');
  });
