import { Router } from 'express';
import { createManager, listManagers } from '../controllers/superAdminController.js';
import { getManagerOrders } from '../controllers/orderController.js';
import { getManagerFeedback } from '../controllers/feedbackController.js';
import { getMenuItems } from '../controllers/menuController.js';
import { requireSuperAdmin } from '../middleware/superAdminAuth.js';

const router = Router();

router.get('/managers', listManagers);
router.post('/managers', createManager);
router.get('/orders', requireSuperAdmin, getManagerOrders);
router.get('/feedback', requireSuperAdmin, getManagerFeedback);
router.get('/menu-items', requireSuperAdmin, getMenuItems);

export default router;
