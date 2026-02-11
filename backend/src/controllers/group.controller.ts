import { Request, Response } from 'express';
import {
    createGroup,
    getGroupById,
    getUserGroups,
    getGroupMembers,
    getGroupBooks,
    joinGroup,
    leaveGroup,
    updateGroup,
    deleteGroup,
    updateMemberRole,
    removeMember,
    regenerateInviteCode,
} from '../services/group.service';
import { GroupCategory, MemberRole } from '@prisma/client';

/**
 * Create a new group
 * POST /api/v1/groups
 */
export async function createGroupController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { name, description, category, privacy, coverImageUrl, rules } = req.body;

        // Validate required fields
        if (!name || !description || !category || !privacy) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'name, description, category, and privacy are required',
            });
        }

        const group = await createGroup({
            name,
            description,
            category,
            privacy,
            coverImageUrl,
            rules,
            creatorId: req.user.userId,
        });

        res.status(201).json(group);
    } catch (error) {
        console.error('Create group error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to create group',
        });
    }
}

/**
 * Get user's groups
 * GET /api/v1/groups/my-groups
 */
export async function getMyGroupsController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { category } = req.query;

        const groups = await getUserGroups(
            req.user.userId,
            category as GroupCategory | undefined
        );

        res.json(groups);
    } catch (error) {
        console.error('Get my groups error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to fetch groups',
        });
    }
}

/**
 * Get group details
 * GET /api/v1/groups/:id
 */
export async function getGroupDetailsController(req: Request, res: Response) {
    try {
        const { id } = req.params;
        const userId = req.user?.userId;

        const group = await getGroupById(id, userId);

        if (!group) {
            return res.status(404).json({
                error: 'Not Found',
                message: 'Group not found or you do not have access',
            });
        }

        res.json(group);
    } catch (error) {
        console.error('Get group details error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to fetch group details',
        });
    }
}

/**
 * Get group members
 * GET /api/v1/groups/:id/members
 */
export async function getGroupMembersController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { id } = req.params;
        const { role } = req.query;

        const result = await getGroupMembers(
            id,
            req.user.userId,
            role as MemberRole | undefined
        );

        res.json(result);
    } catch (error: any) {
        console.error('Get group members error:', error);

        if (error.message === 'You must be a member to view group members') {
            return res.status(403).json({
                error: 'Forbidden',
                message: error.message,
            });
        }

        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to fetch group members',
        });
    }
}

/**
 * Get group books
 * GET /api/v1/groups/:id/books
 */
export async function getGroupBooksController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { id } = req.params;
        const { page, limit, availability, genre, sortBy } = req.query;

        const result = await getGroupBooks(id, req.user.userId, {
            page: page ? parseInt(page as string) : undefined,
            limit: limit ? parseInt(limit as string) : undefined,
            availability: availability as 'AVAILABLE' | 'NOT_AVAILABLE' | undefined,
            genre: genre as string | undefined,
            sortBy: sortBy as 'RECENT' | 'PRICE_LOW' | 'PRICE_HIGH' | undefined,
        });

        res.json(result);
    } catch (error: any) {
        console.error('Get group books error:', error);

        if (error.message === 'You must be a member to view group books') {
            return res.status(403).json({
                error: 'Forbidden',
                message: error.message,
            });
        }

        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to fetch group books',
        });
    }
}

/**
 * Join a group
 * POST /api/v1/groups/join
 */
export async function joinGroupController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { inviteCode } = req.body;

        if (!inviteCode) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'inviteCode is required',
            });
        }

        const group = await joinGroup(inviteCode, req.user.userId);

        res.json({
            message: 'Successfully joined group',
            group,
        });
    } catch (error: any) {
        console.error('Join group error:', error);

        if (error.message === 'Invalid invite code') {
            return res.status(404).json({
                error: 'Not Found',
                message: error.message,
            });
        }

        if (error.message === 'Invite code has expired') {
            return res.status(400).json({
                error: 'Bad Request',
                message: error.message,
            });
        }

        if (error.message === 'You are already a member of this group') {
            return res.status(409).json({
                error: 'Conflict',
                message: error.message,
            });
        }

        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to join group',
        });
    }
}

/**
 * Leave a group
 * POST /api/v1/groups/:id/leave
 */
export async function leaveGroupController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { id } = req.params;

        await leaveGroup(id, req.user.userId);

        res.json({
            message: 'Successfully left group',
        });
    } catch (error: any) {
        console.error('Leave group error:', error);

        if (error.message === 'You are not a member of this group') {
            return res.status(403).json({
                error: 'Forbidden',
                message: error.message,
            });
        }

        if (error.message.includes('Creator cannot leave')) {
            return res.status(400).json({
                error: 'Bad Request',
                message: error.message,
            });
        }

        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to leave group',
        });
    }
}

/**
 * Update group
 * PUT /api/v1/groups/:id
 */
export async function updateGroupController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { id } = req.params;
        const { name, description, coverImageUrl, category, privacy, rules } = req.body;

        const updatedGroup = await updateGroup(id, req.user.userId, {
            name,
            description,
            coverImageUrl,
            category,
            privacy,
            rules,
        });

        res.json(updatedGroup);
    } catch (error: any) {
        console.error('Update group error:', error);

        if (error.message === 'You are not a member of this group') {
            return res.status(404).json({
                error: 'Not Found',
                message: 'Group not found',
            });
        }

        if (error.message.includes('Only admins and creators')) {
            return res.status(403).json({
                error: 'Forbidden',
                message: error.message,
            });
        }

        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to update group',
        });
    }
}

/**
 * Delete group
 * DELETE /api/v1/groups/:id
 */
export async function deleteGroupController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { id } = req.params;

        await deleteGroup(id, req.user.userId);

        res.json({
            message: 'Group deleted successfully',
        });
    } catch (error: any) {
        console.error('Delete group error:', error);

        if (error.message === 'Group not found') {
            return res.status(404).json({
                error: 'Not Found',
                message: error.message,
            });
        }

        if (error.message === 'Only the creator can delete the group') {
            return res.status(403).json({
                error: 'Forbidden',
                message: error.message,
            });
        }

        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to delete group',
        });
    }
}

/**
 * Update member role
 * PUT /api/v1/groups/:id/members/:userId
 */
export async function updateMemberRoleController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { id, userId } = req.params;
        const { role } = req.body;

        if (!role) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'role is required',
            });
        }

        const updatedMember = await updateMemberRole(
            id,
            userId,
            req.user.userId,
            role as MemberRole
        );

        res.json({
            message: 'Member role updated successfully',
            member: updatedMember,
        });
    } catch (error: any) {
        console.error('Update member role error:', error);

        if (error.message.includes('not a member')) {
            return res.status(404).json({
                error: 'Not Found',
                message: error.message,
            });
        }

        if (error.message.includes('Only admins and creators') ||
            error.message.includes('Cannot change creator') ||
            error.message.includes('Cannot assign creator')) {
            return res.status(403).json({
                error: 'Forbidden',
                message: error.message,
            });
        }

        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to update member role',
        });
    }
}

/**
 * Remove member
 * DELETE /api/v1/groups/:id/members/:userId
 */
export async function removeMemberController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { id, userId } = req.params;

        await removeMember(id, userId, req.user.userId);

        res.json({
            message: 'Member removed successfully',
        });
    } catch (error: any) {
        console.error('Remove member error:', error);

        if (error.message.includes('not a member')) {
            return res.status(404).json({
                error: 'Not Found',
                message: error.message,
            });
        }

        if (error.message.includes('Only admins and creators') ||
            error.message.includes('Cannot remove the creator')) {
            return res.status(403).json({
                error: 'Forbidden',
                message: error.message,
            });
        }

        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to remove member',
        });
    }
}

/**
 * Regenerate invite code
 * POST /api/v1/groups/:id/regenerate-invite
 */
export async function regenerateInviteCodeController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { id } = req.params;
        const { expiresInDays } = req.body;

        const result = await regenerateInviteCode(
            id,
            req.user.userId,
            expiresInDays ? parseInt(expiresInDays) : undefined
        );

        res.json(result);
    } catch (error: any) {
        console.error('Regenerate invite code error:', error);

        if (error.message === 'You are not a member of this group') {
            return res.status(404).json({
                error: 'Not Found',
                message: 'Group not found',
            });
        }

        if (error.message.includes('Only admins and creators')) {
            return res.status(403).json({
                error: 'Forbidden',
                message: error.message,
            });
        }

        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to regenerate invite code',
        });
    }
}
