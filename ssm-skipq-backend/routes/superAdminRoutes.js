import { Router } from 'express';
import { createManager, listManagers } from '../controllers/superAdminController.js';

const router = Router();

router.get('/managers', listManagers);
router.post('/managers', createManager);

export default router;
