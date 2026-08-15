import { Router } from 'express';
import {
  getPaymentConfig,
  verifyRazorpayPayment,
} from '../controllers/paymentController.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = Router();

router.get('/config', getPaymentConfig);
router.post(
  '/razorpay/verify',
  authenticate,
  authorize('student'),
  verifyRazorpayPayment,
);

export default router;
