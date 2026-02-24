import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
    createGroupController,
    getMyGroupsController,
    getAllGroupsController,
    discoverGroupsController,
    getGroupDetailsController,
    getGroupMembersController,
    getGroupBooksController,
    joinGroupController,
    joinGroupByIdController,
    leaveGroupController,
    updateGroupController,
    deleteGroupController,
    updateMemberRoleController,
    removeMemberController,
    regenerateInviteCodeController,
} from '../controllers/group.controller';

const router = Router();

/**
 * @swagger
 * /groups:
 *   post:
 *     tags: [Groups]
 *     summary: Create a new group
 *     description: Create a new group and become its creator
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - description
 *               - category
 *               - privacy
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Office Book Club"
 *               description:
 *                 type: string
 *                 example: "Share books with office colleagues"
 *               category:
 *                 type: string
 *                 enum: [FRIENDS, OFFICE, NEIGHBORHOOD, BOOK_CLUB, SCHOOL]
 *                 example: "OFFICE"
 *               privacy:
 *                 type: string
 *                 enum: [PUBLIC, PRIVATE]
 *                 example: "PRIVATE"
 *               coverImageUrl:
 *                 type: string
 *                 format: uri
 *                 example: "https://example.com/cover.jpg"
 *               rules:
 *                 type: string
 *                 example: "1. Return books on time\n2. Keep books in good condition"
 *     responses:
 *       201:
 *         description: Group created successfully
 *       400:
 *         description: Missing required fields
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         description: Server error
 */
router.post('/', authenticate, createGroupController);

/**
 * @swagger
 * /groups:
 *   get:
 *     tags: [Groups]
 *     summary: Get all visible groups
 *     description: Returns all PUBLIC groups plus any groups the authenticated user belongs to. Supports optional category and search filtering.
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *           enum: [FRIENDS, OFFICE, NEIGHBORHOOD, BOOK_CLUB, SCHOOL]
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Array of groups
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/', authenticate, getAllGroupsController);

/**
 * @swagger
 * /groups/my-groups:
 *   get:
 *     tags: [Groups]
 *     summary: Get user's groups
 *     description: Get all groups the authenticated user is a member of
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *           enum: [FRIENDS, OFFICE, NEIGHBORHOOD, BOOK_CLUB, SCHOOL]
 *         description: Filter by category
 *     responses:
 *       200:
 *         description: Groups retrieved successfully
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         description: Server error
 */
router.get('/my-groups', authenticate, getMyGroupsController);

/**
 * @swagger
 * /groups/join:
 *   post:
 *     tags: [Groups]
 *     summary: Join a group
 *     description: Join a group using an invite code
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - inviteCode
 *             properties:
 *               inviteCode:
 *                 type: string
 *                 example: "ABC123XYZ"
 *     responses:
 *       200:
 *         description: Successfully joined group
 *       400:
 *         description: Invalid or expired invite code
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: Group not found
 *       409:
 *         description: Already a member
 *       500:
 *         description: Server error
 */
router.post('/join', authenticate, joinGroupController);

/**
 * @swagger
 * /groups/discover:
 *   get:
 *     tags: [Groups]
 *     summary: Discover public groups
 *     description: Returns PUBLIC groups the authenticated user has not yet joined. Supports optional category and search filters.
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *           enum: [FRIENDS, OFFICE, NEIGHBORHOOD, BOOK_CLUB, SCHOOL]
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Array of discoverable groups wrapped in { groups: [...] }
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/discover', authenticate, discoverGroupsController);

/**
 * @swagger
 * /groups/{id}:
 *   get:
 *     tags: [Groups]
 *     summary: Get group details
 *     description: Get detailed information about a specific group. Requires authentication. Private groups return 404 for non-members.
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *     responses:
 *       200:
 *         description: Group details retrieved successfully
 *       403:
 *         description: Private group and user is not a member
 *       404:
 *         description: Group not found
 *       500:
 *         description: Server error
 */
router.get('/:id', authenticate, getGroupDetailsController);

/**
 * @swagger
 * /groups/{id}:
 *   put:
 *     tags: [Groups]
 *     summary: Update group
 *     description: Update group details (admin/creator only)
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Updated Office Book Club"
 *               description:
 *                 type: string
 *                 example: "Updated description"
 *               coverImageUrl:
 *                 type: string
 *                 format: uri
 *               category:
 *                 type: string
 *                 enum: [FRIENDS, OFFICE, NEIGHBORHOOD, BOOK_CLUB, SCHOOL]
 *               privacy:
 *                 type: string
 *                 enum: [PUBLIC, PRIVATE]
 *               rules:
 *                 type: string
 *     responses:
 *       200:
 *         description: Group updated successfully
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: User must be admin or creator
 *       404:
 *         description: Group not found
 *       500:
 *         description: Server error
 */
router.put('/:id', authenticate, updateGroupController);

/**
 * @swagger
 * /groups/{id}:
 *   delete:
 *     tags: [Groups]
 *     summary: Delete group
 *     description: Delete a group (creator only)
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *     responses:
 *       200:
 *         description: Group deleted successfully
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: Only creator can delete group
 *       404:
 *         description: Group not found
 *       500:
 *         description: Server error
 */
router.delete('/:id', authenticate, deleteGroupController);

/**
 * @swagger
 * /groups/{id}/join:
 *   post:
 *     tags: [Groups]
 *     summary: Join a public group by ID
 *     description: Join a PUBLIC group directly without an invite code. For PRIVATE groups use POST /groups/join with an invite code.
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *     responses:
 *       200:
 *         description: '{ status: "JOINED" }'
 *       403:
 *         description: Group is private — use invite code
 *       404:
 *         description: Group not found
 *       409:
 *         description: Already a member
 *       500:
 *         description: Server error
 */
router.post('/:id/join', authenticate, joinGroupByIdController);

/**
 * @swagger
 * /groups/{id}/members:
 *   get:
 *     tags: [Groups]
 *     summary: Get group members
 *     description: Get all members of a group (must be a member to view)
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *       - in: query
 *         name: role
 *         schema:
 *           type: string
 *           enum: [MEMBER, MODERATOR, ADMIN, CREATOR]
 *         description: Filter by role
 *     responses:
 *       200:
 *         description: Members retrieved successfully
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: User is not a member
 *       404:
 *         description: Group not found
 *       500:
 *         description: Server error
 */
router.get('/:id/members', authenticate, getGroupMembersController);

/**
 * @swagger
 * /groups/{id}/members/{userId}:
 *   put:
 *     tags: [Groups]
 *     summary: Update member role
 *     description: Update a member's role (admin/creator only)
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - role
 *             properties:
 *               role:
 *                 type: string
 *                 enum: [MEMBER, MODERATOR, ADMIN]
 *                 description: MODERATOR role exists in DB but does not grant elevated service permissions (only ADMIN/CREATOR can perform privileged actions)
 *                 example: "ADMIN"
 *     responses:
 *       200:
 *         description: Member role updated successfully
 *       400:
 *         description: Cannot change creator's role
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: User must be admin or creator
 *       404:
 *         description: Group or member not found
 *       500:
 *         description: Server error
 */
router.put('/:id/members/:userId', authenticate, updateMemberRoleController);

/**
 * @swagger
 * /groups/{id}/members/{userId}:
 *   delete:
 *     tags: [Groups]
 *     summary: Remove member
 *     description: Remove a member from the group (admin/creator only)
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     responses:
 *       200:
 *         description: Member removed successfully
 *       400:
 *         description: Cannot remove creator
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: User must be admin or creator
 *       404:
 *         description: Group or member not found
 *       500:
 *         description: Server error
 */
router.delete('/:id/members/:userId', authenticate, removeMemberController);

/**
 * @swagger
 * /groups/{id}/books:
 *   get:
 *     tags: [Groups]
 *     summary: Get group books
 *     description: Get all books visible in a specific group
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *       - in: query
 *         name: availability
 *         schema:
 *           type: string
 *           enum: [AVAILABLE, NOT_AVAILABLE]
 *       - in: query
 *         name: genre
 *         schema:
 *           type: string
 *       - in: query
 *         name: sortBy
 *         schema:
 *           type: string
 *           enum: [RECENT, PRICE_LOW, PRICE_HIGH]
 *           default: RECENT
 *     responses:
 *       200:
 *         description: Books retrieved successfully
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: User is not a member
 *       404:
 *         description: Group not found
 *       500:
 *         description: Server error
 */
router.get('/:id/books', authenticate, getGroupBooksController);

/**
 * @swagger
 * /groups/{id}/leave:
 *   post:
 *     tags: [Groups]
 *     summary: Leave group
 *     description: Leave a group (creator cannot leave)
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *     responses:
 *       200:
 *         description: Successfully left group
 *       400:
 *         description: Creator cannot leave group
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: User is not a member
 *       404:
 *         description: Group not found
 *       500:
 *         description: Server error
 */
router.post('/:id/leave', authenticate, leaveGroupController);

/**
 * @swagger
 * /groups/{id}/regenerate-invite:
 *   post:
 *     tags: [Groups]
 *     summary: Regenerate invite code
 *     description: Generate a new invite code (admin/creator only)
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Group ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               expiresInDays:
 *                 type: integer
 *                 example: 7
 *     responses:
 *       200:
 *         description: Invite code regenerated successfully
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: User must be admin or creator
 *       404:
 *         description: Group not found
 *       500:
 *         description: Server error
 */
router.post('/:id/regenerate-invite', authenticate, regenerateInviteCodeController);

export default router;
