import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
    getMyTransactions,
    createBorrowRequest,
    approveRequest,
    rejectRequest,
    confirmHandover,
    confirmReturn,
    markPayment,
    rateTransaction,
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


/**
 * @swagger
 * /transactions/{id}/approve:
 *   post:
 *     tags: [Transactions]
 *     summary: Approve a borrow request
 *     description: Owner approves a pending borrow request
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Transaction ID
 *     responses:
 *       200:
 *         description: Request approved successfully
 *       400:
 *         description: Transaction not found or invalid state
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: Only the book owner can approve requests
 */
router.post('/:id/approve', authenticate, approveRequest);

/**
 * @swagger
 * /transactions/{id}/reject:
 *   post:
 *     tags: [Transactions]
 *     summary: Reject a borrow request
 *     description: Owner rejects a pending borrow request with an optional reason
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Transaction ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               reason:
 *                 type: string
 *                 example: "Book is currently reserved for another request"
 *     responses:
 *       200:
 *         description: Request rejected successfully
 *       400:
 *         description: Transaction not found or invalid state
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: Only the book owner can reject requests
 */
router.post('/:id/reject', authenticate, rejectRequest);

/**
 * @swagger
 * /transactions/{id}/confirm-handover:
 *   post:
 *     tags: [Transactions]
 *     summary: Confirm book handover
 *     description: Confirms the physical handover of the book, transitioning status to ACTIVE and marking the book as unavailable
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Transaction ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               otp:
 *                 type: string
 *                 description: Handover OTP (future use)
 *     responses:
 *       200:
 *         description: Handover confirmed, transaction is now ACTIVE
 *       400:
 *         description: Transaction not found or invalid state
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.post('/:id/confirm-handover', authenticate, confirmHandover);

/**
 * @swagger
 * /transactions/{id}/confirm-return:
 *   post:
 *     tags: [Transactions]
 *     summary: Confirm book return
 *     description: Confirms the book has been returned, transitioning status to RETURNED and marking the book as available again
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Transaction ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               otp:
 *                 type: string
 *                 description: Return OTP (future use)
 *     responses:
 *       200:
 *         description: Return confirmed, book is now available
 *       400:
 *         description: Transaction not found or invalid state
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.post('/:id/confirm-return', authenticate, confirmReturn);

/**
 * @swagger
 * /transactions/{id}/mark-payment:
 *   post:
 *     tags: [Transactions]
 *     summary: Mark payment as confirmed (offline payment)
 *     description: Borrower or owner confirms offline payment. Both must confirm for payment to be fully complete.
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [role]
 *             properties:
 *               role:
 *                 type: string
 *                 enum: [BORROWER, OWNER]
 *     responses:
 *       200:
 *         description: Payment confirmation recorded
 *       400:
 *         description: Invalid role or transaction state
 *       403:
 *         description: Role mismatch
 */
router.post('/:id/mark-payment', authenticate, markPayment);

/**
 * @swagger
 * /transactions/{id}/rate:
 *   post:
 *     tags: [Transactions]
 *     summary: Rate a completed transaction
 *     description: Leave a rating (1-5) for a returned transaction. Borrower rates the owner; owner rates the borrower.
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [rating]
 *             properties:
 *               rating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               comment:
 *                 type: string
 *               bookConditionRating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *                 description: Only applicable when the owner is rating
 *     responses:
 *       200:
 *         description: Rating saved successfully
 *       400:
 *         description: Transaction not returned yet or invalid rating
 *       403:
 *         description: Not a party to this transaction
 */
router.post('/:id/rate', authenticate, rateTransaction);

export default router;
