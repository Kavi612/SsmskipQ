import { Router } from 'express';
import {
  getOrderingWindow,
  updateOrderingWindow,
} from '../controllers/settingsController.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = Router();

router.get('/ordering-window', getOrderingWindow);
router.patch(
  '/ordering-window',
  authenticate,
  authorize('manager'),
  updateOrderingWindow,
);

export default router;
