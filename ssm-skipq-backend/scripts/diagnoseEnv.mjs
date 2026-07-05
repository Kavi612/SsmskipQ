import dotenv from 'dotenv';
import mongoose from 'mongoose';

dotenv.config();

const uri = process.env.MONGODB_URI;

console.log('=== .env diagnosis (no secrets printed) ===\n');

if (!uri) {
  console.log('FAIL: MONGODB_URI is not set');
  process.exit(1);
}

if (uri !== uri.trim()) {
  console.log('WARN: MONGODB_URI has extra whitespace — trim the line');
}

const match = uri.match(/^mongodb(\+srv)?:\/\/([^:]+):([^@]+)@([^/?]+)(\/[^?]*)?(\?.*)?$/);
if (!match) {
  console.log('FAIL: MONGODB_URI format looks invalid');
  console.log('Expected: mongodb+srv://USER:PASSWORD@cluster.mongodb.net/DATABASE?options');
  process.exit(1);
}

const [, , user, password, host, dbPath] = match;
console.log('Username:', user);
console.log('Password length:', password.length, 'chars');
console.log('Host:', host);
console.log('Database:', dbPath?.slice(1) || '(not set — recommend ssm-skipq)');

console.log('\nConnecting...');
try {
  await mongoose.connect(uri.trim(), { serverSelectionTimeoutMS: 12000 });
  console.log('SUCCESS: MongoDB connected');
  await mongoose.disconnect();
} catch (error) {
  console.log('FAIL:', error.message);
  if (error.message.includes('bad auth')) {
    console.log('\nLikely cause: password in .env does not match Atlas Database Access.');
    console.log('Fix: Atlas → Database Access → reset password → paste ONLY into .env (not .env.example)');
  }
}
