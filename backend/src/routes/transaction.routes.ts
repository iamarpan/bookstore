import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
    getMyTransactions,
    createBorrowRequest,
    approveRequest,
    rejectRequest,
    confirmHandover,
    confirmReturn
} from '../controllers/transaction.controller';

const router = Router();

/**
 * @swagger
 * /transactions/my:
 *   get:
 *     tags: [Transactions]
 *     summary: Get current user's transactions
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *         name: role
 *         schema:
 *           type: string
 *           enum: [BORROWER, OWNER]
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [PENDING, APPROVED, ACTIVE, RETURNED, REJECTED, CANCELLED]
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 */
router.get('/my', authenticate, getMyTransactions);

/**
 * @swagger
 * /transactions/request:
 *   post:
 *     tags: [Transactions]
 *     summary: Create a new borrow request
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [bookId, duration]
 *             properties:
 *               bookId: { type: string }
 *               duration: { type: string, enum: [1_WEEK, 2_WEEKS, 1_MONTH, CUSTOM] }
 *               durationDays: { type: integer }
 *               message: { type: string }
 */
router.post('/request', authenticate, createBorrowRequest);

router.post('/:id/approve', authenticate, approveRequest);
router.post('/:id/reject', authenticate, rejectRequest);
router.post('/:id/confirm-handover', authenticate, confirmHandover);
router.post('/:id/confirm-return', authenticate, confirmReturn);

export default router;
