import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
    getCurrentUser,
    updateCurrentUser,
    updateNotifications,
    updatePrivacy,
    registerDeviceToken,
    getCurrentUserBooks,
} from '../controllers/user.controller';

const router = Router();

// All user routes require authentication
router.use(authenticate);

/**
 * @swagger
 * /users/me:
 *   get:
 *     tags: [Users]
 *     summary: Get current user profile
 *     description: Returns the authenticated user's complete profile information
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: User profile retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: User not found
 *       500:
 *         description: Server error
 */
router.get('/me', getCurrentUser);

/**
 * @swagger
 * /users/me:
 *   put:
 *     tags: [Users]
 *     summary: Update user profile
 *     description: Update current user's profile information (all fields optional)
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "John Doe"
 *               email:
 *                 type: string
 *                 format: email
 *                 example: "john@example.com"
 *               bio:
 *                 type: string
 *                 example: "Book enthusiast and avid reader"
 *               profileImageUrl:
 *                 type: string
 *                 format: uri
 *                 example: "https://example.com/image.jpg"
 *     responses:
 *       200:
 *         description: Profile updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       400:
 *         description: At least one field must be provided
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         description: Server error
 */
router.put('/me', updateCurrentUser);

/**
 * @swagger
 * /users/me/notifications:
 *   put:
 *     tags: [Users]
 *     summary: Update notification preferences
 *     description: Update user's notification settings
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               pushEnabled:
 *                 type: boolean
 *                 example: true
 *               emailEnabled:
 *                 type: boolean
 *                 example: false
 *               borrowRequestsNotif:
 *                 type: boolean
 *                 example: true
 *               dueDateRemindersNotif:
 *                 type: boolean
 *                 example: true
 *               groupActivityNotif:
 *                 type: boolean
 *                 example: false
 *     responses:
 *       200:
 *         description: Notification preferences updated
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 preferences:
 *                   type: object
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         description: Server error
 */
router.put('/me/notifications', updateNotifications);

/**
 * @swagger
 * /users/me/privacy:
 *   put:
 *     tags: [Users]
 *     summary: Update privacy settings
 *     description: Update user's privacy settings
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phoneVisibility
 *             properties:
 *               phoneVisibility:
 *                 type: string
 *                 enum: [AFTER_APPROVAL, GROUP_MEMBERS, PUBLIC]
 *                 example: "GROUP_MEMBERS"
 *     responses:
 *       200:
 *         description: Privacy settings updated
 *       400:
 *         description: phoneVisibility is required
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         description: Server error
 */
router.put('/me/privacy', updatePrivacy);

/**
 * @swagger
 * /users/me/device-token:
 *   post:
 *     tags: [Users]
 *     summary: Register device token for push notifications
 *     description: Register Apple Push Notification Service (APNs) device token
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - deviceToken
 *             properties:
 *               deviceToken:
 *                 type: string
 *                 example: "abc123def456..."
 *     responses:
 *       200:
 *         description: Device token registered successfully
 *       400:
 *         description: deviceToken is required
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         description: Server error
 */
router.post('/me/device-token', registerDeviceToken);

/**
 * @swagger
 * /users/me/books:
 *   get:
 *     tags: [Users]
 *     summary: Get current user's books
 *     description: Get all books owned by the authenticated user
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Books retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Book'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         description: Server error
 */
router.get('/me/books', getCurrentUserBooks);

export default router;
