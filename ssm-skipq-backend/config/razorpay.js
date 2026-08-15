import Razorpay from 'razorpay';

let client;

export const isRazorpayConfigured = () =>
  Boolean(process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET);

export const getRazorpayKeyId = () => process.env.RAZORPAY_KEY_ID ?? '';

export const isRazorpayTestMode = () =>
  getRazorpayKeyId().startsWith('rzp_test_');

export const getRazorpayClient = () => {
  if (!isRazorpayConfigured()) {
    throw new Error('Razorpay is not configured');
  }

  if (!client) {
    client = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID,
      key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
  }

  return client;
};

export const createRazorpayOrder = async ({ amountInr, receipt, notes = {} }) => {
  const razorpay = getRazorpayClient();
  const amountPaise = Math.round(Number(amountInr) * 100);

  if (amountPaise < 100) {
    throw new Error('Order total must be at least ₹1 for Razorpay');
  }

  return razorpay.orders.create({
    amount: amountPaise,
    currency: 'INR',
    receipt,
    notes,
  });
};
