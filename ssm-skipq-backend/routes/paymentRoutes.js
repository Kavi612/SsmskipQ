import { Router } from 'express';
import {
  createRazorpayCheckout,
  getPaymentConfig,
  verifyRazorpayPayment,
} from '../controllers/paymentController.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = Router();

router.get('/config', getPaymentConfig);
router.post(
  '/razorpay/orders/:orderId',
  authenticate,
  authorize('student'),
  createRazorpayCheckout,
);
router.post(
  '/razorpay/verify',
  authenticate,
  authorize('student'),
  verifyRazorpayPayment,
);

export default router;
