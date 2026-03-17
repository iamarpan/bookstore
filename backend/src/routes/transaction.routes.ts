import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
    getMyTransactions,
    getTransactionById,
    createBorrowRequest,
    approveRequest,
    rejectRequest,
    generateHandoverOTP,
    generateReturnOTP,
    confirmHandover,
    confirmReturn,
    markPayment,
    rateTransaction,
    cancelRequest,
} from '../controllers/transaction.controller';
import {
    getMessages,
    sendMessage,
    getUnreadCount,
    markAsRead,
} from '../controllers/message.controller';

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
 * /transactions/{id}:
 *   get:
 *     tags: [Transactions]
 *     summary: Get a single transaction by ID
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 */
router.get('/:id', authenticate, getTransactionById);

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
/**
 * @swagger
 * /transactions/{id}/generate-handover-otp:
 *   post:
 *     tags: [Transactions]
 *     summary: Generate a handover OTP (owner only)
 *     description: Generates a 6-digit OTP stored in the transaction for 10 minutes. Owner shows this to the borrower in person to confirm handover.
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: OTP generated
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 otp:
 *                   type: string
 *                   example: "382910"
 */
router.post('/:id/generate-handover-otp', authenticate, generateHandoverOTP);

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
/**
 * @swagger
 * /transactions/{id}/generate-return-otp:
 *   post:
 *     tags: [Transactions]
 *     summary: Generate a return OTP (owner only)
 *     description: Generates a 6-digit OTP stored in the transaction for 10 minutes. Owner shows this to the borrower so the borrower can confirm the return.
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: OTP generated
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 otp:
 *                   type: string
 *                   example: "748291"
 */
router.post('/:id/generate-return-otp', authenticate, generateReturnOTP);

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

/**
 * @swagger
 * /transactions/{id}/cancel:
 *   post:
 *     tags: [Transactions]
 *     summary: Cancel a borrow request
 *     description: Borrower cancels a PENDING or APPROVED borrow request
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Transaction cancelled
 *       400:
 *         description: Invalid transaction state
 *       403:
 *         description: Only the borrower can cancel
 *       404:
 *         description: Transaction not found
 */
router.post('/:id/cancel', authenticate, cancelRequest);

/**
 * @swagger
 * /transactions/{id}/messages:
 *   get:
 *     tags: [Transactions]
 *     summary: Get messages for a transaction
 *     description: Retrieves all messages for a transaction. Only available for APPROVED or ACTIVE transactions.
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
 *         description: List of messages
 *       403:
 *         description: Not a party to this transaction
 *       400:
 *         description: Chat not available for this transaction status
 */
router.get('/:transactionId/messages', authenticate, getMessages);

/**
 * @swagger
 * /transactions/{id}/messages:
 *   post:
 *     tags: [Transactions]
 *     summary: Send a message in a transaction chat
 *     description: Sends a message to the other party. Only available for APPROVED or ACTIVE transactions.
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
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [content]
 *             properties:
 *               content:
 *                 type: string
 *                 description: Message content
 *     responses:
 *       201:
 *         description: Message sent successfully
 *       400:
 *         description: Content is required or chat not available
 *       403:
 *         description: Not a party to this transaction
 */
router.post('/:transactionId/messages', authenticate, sendMessage);

/**
 * @swagger
 * /transactions/{id}/messages/unread:
 *   get:
 *     tags: [Transactions]
 *     summary: Get unread message count
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Unread count
 */
router.get('/:transactionId/messages/unread', authenticate, getUnreadCount);

/**
 * @swagger
 * /transactions/{id}/messages/read:
 *   post:
 *     tags: [Transactions]
 *     summary: Mark messages as read
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Messages marked as read
 */
router.post('/:transactionId/messages/read', authenticate, markAsRead);

export default router;
