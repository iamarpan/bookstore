import prisma from '../config/database';
import { GroupCategory, PrivacySetting, MemberRole } from '@prisma/client';

/**
 * Generate a unique invite code
 */
function generateInviteCode(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 8; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

/**
 * Create a new group
 */
export async function createGroup(data: {
    name: string;
    description: string;
    category: GroupCategory;
    privacy: PrivacySetting;
    creatorId: string;
    coverImageUrl?: string;
    rules?: string;
}) {
    const { creatorId, ...groupData } = data;

    // Generate unique invite code
    let inviteCode = generateInviteCode();
    let codeExists = await prisma.group.findUnique({ where: { inviteCode } });

    // Ensure uniqueness
    while (codeExists) {
        inviteCode = generateInviteCode();
        codeExists = await prisma.group.findUnique({ where: { inviteCode } });
    }

    // Create group with creator as first member
    const group = await prisma.group.create({
        data: {
            ...groupData,
            creatorId,
            inviteCode,
            members: {
                create: {
                    userId: creatorId,
                    role: MemberRole.CREATOR,
                },
            },
        },
        include: {
            creator: {
                select: {
                    id: true,
                    name: true,
                    profileImageUrl: true,
                },
            },
        },
    });

    return {
        ...group,
        role: MemberRole.CREATOR,
    };
}

/**
 * Get group by ID
 */
export async function getGroupById(groupId: string, userId?: string) {
    const group = await prisma.group.findUnique({
        where: { id: groupId },
        include: {
            creator: {
                select: {
                    id: true,
                    name: true,
                    profileImageUrl: true,
                },
            },
            members: userId ? {
                where: { userId },
                select: {
                    role: true,
                },
            } : false,
        },
    });

    if (!group) {
        return null;
    }

    // Check if user is a member or creator
    const isCreator = group.creatorId === userId;
    const userMembership = userId ? group.members[0] : null;
    const isMember = !!userMembership;
    const userRole = userMembership?.role || (isCreator ? MemberRole.CREATOR : undefined);

    // For private groups, only members or the creator can see details
    if (group.privacy === PrivacySetting.PRIVATE && !isMember && !isCreator) {
        return null;
    }

    return {
        ...group,
        members: undefined, // Remove members array from response
        role: userRole,
        isMember: isMember || isCreator,
    };
}

/**
 * Get user's groups
 */
export async function getUserGroups(userId: string, category?: GroupCategory) {
    const groups = await prisma.group.findMany({
        where: {
            OR: [
                { creatorId: userId },
                { members: { some: { userId } } }
            ],
            ...(category && { category })
        },
        include: {
            creator: {
                select: {
                    id: true,
                    name: true,
                },
            },
            members: {
                where: { userId },
                select: {
                    role: true,
                    joinedAt: true,
                }
            }
        },
        orderBy: {
            createdAt: 'desc',
        },
    });

    return groups.map(g => ({
        ...g,
        role: g.members[0]?.role || (g.creatorId === userId ? MemberRole.CREATOR : MemberRole.MEMBER),
        joinedAt: g.members[0]?.joinedAt || g.createdAt,
        members: undefined,
    }));
}

/**
 * Get all groups visible to user:
 * - All PUBLIC groups
 * - All groups the user is a member of (PUBLIC or PRIVATE)
 * Supports optional category + search filters.
 */
export async function getAllGroups(userId: string, params?: {
    category?: GroupCategory;
    search?: string;
}) {
    const { category, search } = params ?? {};

    const where: any = {
        OR: [
            { privacy: 'PUBLIC' },
            { members: { some: { userId } } },
        ],
    };

    if (category) {
        where.category = category;
    }

    if (search) {
        // Wrap search in AND so it combines with OR above
        where.AND = [
            {
                OR: [
                    { name: { contains: search, mode: 'insensitive' } },
                    { description: { contains: search, mode: 'insensitive' } },
                ],
            },
        ];
    }

    const groups = await prisma.group.findMany({
        where,
        include: {
            creator: {
                select: { id: true, name: true, profileImageUrl: true },
            },
            members: {
                where: { userId },
                select: { role: true, joinedAt: true },
            },
        },
        orderBy: { memberCount: 'desc' },
    });

    return groups.map(g => {
        const membership = g.members[0];
        return {
            ...g,
            role: membership?.role ?? null,
            isMember: !!membership,
            joinedAt: membership?.joinedAt ?? null,
            members: undefined,
        };
    });
}

/**
 * Join a PUBLIC group directly by its ID (no invite code required)
 */
export async function joinGroupById(groupId: string, userId: string) {
    const group = await prisma.group.findUnique({ where: { id: groupId } });

    if (!group) throw new Error('Group not found');
    if (group.privacy !== 'PUBLIC') {
        throw new Error('This group is private — use an invite code to join');
    }

    // Already a member?
    const existing = await prisma.groupMember.findUnique({
        where: { groupId_userId: { groupId, userId } },
    });
    if (existing) throw new Error('You are already a member of this group');

    await prisma.groupMember.create({
        data: { groupId, userId, role: MemberRole.MEMBER },
    });

    await prisma.group.update({
        where: { id: groupId },
        data: { memberCount: { increment: 1 } },
    });

    return { status: 'JOINED' };
}

/**
 * Discover public groups (not already joined by the user)
 */
export async function discoverGroups(userId: string, params: {
    category?: GroupCategory;
    search?: string;
}) {
    const { category, search } = params;

    const where: any = {
        privacy: 'PUBLIC',
        // Exclude groups the user is already a member of
        members: {
            none: { userId },
        },
    };

    if (category) {
        where.category = category;
    }

    if (search) {
        where.OR = [
            { name: { contains: search, mode: 'insensitive' } },
            { description: { contains: search, mode: 'insensitive' } },
        ];
    }

    const groups = await prisma.group.findMany({
        where,
        include: {
            creator: {
                select: { id: true, name: true, profileImageUrl: true },
            },
        },
        orderBy: { memberCount: 'desc' },
        take: 50,
    });

    return groups.map(g => ({
        ...g,
        role: null,
        isMember: false,
    }));
}

/**
 * Get group members
 */
export async function getGroupMembers(groupId: string, userId: string, roleFilter?: MemberRole) {
    // Verify user is a member
    const userMembership = await prisma.groupMember.findUnique({
        where: {
            groupId_userId: {
                groupId,
                userId,
            },
        },
    });

    if (!userMembership) {
        throw new Error('You must be a member to view group members');
    }

    const where: any = { groupId };
    if (roleFilter) {
        where.role = roleFilter;
    }

    const members = await prisma.groupMember.findMany({
        where,
        include: {
            user: {
                select: {
                    id: true,
                    name: true,
                    profileImageUrl: true,
                    booksShared: true,
                    averageRating: true,
                },
            },
        },
        orderBy: [
            { role: 'asc' }, // CREATOR first, then ADMIN, etc.
            { joinedAt: 'asc' },
        ],
    });

    return {
        members,
        total: members.length,
    };
}

/**
 * Get books in a group
 */
export async function getGroupBooks(
    groupId: string,
    userId: string,
    params: {
        page?: number;
        limit?: number;
        availability?: 'AVAILABLE' | 'NOT_AVAILABLE';
        genre?: string;
        sortBy?: 'RECENT' | 'PRICE_LOW' | 'PRICE_HIGH';
    }
) {
    // Verify user is a member
    const userMembership = await prisma.groupMember.findUnique({
        where: {
            groupId_userId: {
                groupId,
                userId,
            },
        },
    });

    if (!userMembership) {
        throw new Error('You must be a member to view group books');
    }

    const {
        page = 1,
        limit = 20,
        availability,
        genre,
        sortBy = 'RECENT',
    } = params;

    const where: any = {
        bookGroups: {
            some: {
                groupId,
            },
        },
    };

    if (availability === 'AVAILABLE') {
        where.isAvailable = true;
    } else if (availability === 'NOT_AVAILABLE') {
        where.isAvailable = false;
    }

    if (genre) {
        where.genre = genre;
    }

    let orderBy: any = {};
    switch (sortBy) {
        case 'PRICE_LOW':
            orderBy = { lendingPricePerWeek: 'asc' };
            break;
        case 'PRICE_HIGH':
            orderBy = { lendingPricePerWeek: 'desc' };
            break;
        case 'RECENT':
        default:
            orderBy = { createdAt: 'desc' };
            break;
    }

    const skip = (page - 1) * limit;

    const [books, total] = await Promise.all([
        prisma.book.findMany({
            where,
            include: {
                owner: {
                    select: {
                        id: true,
                        name: true,
                        profileImageUrl: true,
                    },
                },
                bookGroups: {
                    where: { groupId },
                    select: {
                        addedAt: true,
                    },
                },
            },
            orderBy,
            skip,
            take: limit,
        }),
        prisma.book.count({ where }),
    ]);

    // Format response to include addedAt at top level
    const formattedBooks = books.map(book => ({
        ...book,
        addedAt: book.bookGroups[0]?.addedAt,
        bookGroups: undefined,
    }));

    return {
        books: formattedBooks,
        pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
        },
    };
}

/**
 * Join a group using invite code
 */
export async function joinGroup(inviteCode: string, userId: string) {
    // Find group by invite code
    const group = await prisma.group.findUnique({
        where: { inviteCode },
    });

    if (!group) {
        throw new Error('Invalid invite code');
    }

    // Check if invite code is expired
    if (group.inviteCodeExpiry && group.inviteCodeExpiry < new Date()) {
        throw new Error('Invite code has expired');
    }

    // Check if user is already a member
    const existingMembership = await prisma.groupMember.findUnique({
        where: {
            groupId_userId: {
                groupId: group.id,
                userId,
            },
        },
    });

    if (existingMembership) {
        throw new Error('You are already a member of this group');
    }

    // Add user as member
    await prisma.groupMember.create({
        data: {
            groupId: group.id,
            userId,
            role: MemberRole.MEMBER,
        },
    });

    // Increment member count
    const updatedGroup = await prisma.group.update({
        where: { id: group.id },
        data: {
            memberCount: {
                increment: 1,
            },
        },
    });

    return {
        ...updatedGroup,
        role: MemberRole.MEMBER,
        joinedAt: new Date(),
    };
}

/**
 * Leave a group
 */
export async function leaveGroup(groupId: string, userId: string) {
    // Get user's membership
    const membership = await prisma.groupMember.findUnique({
        where: {
            groupId_userId: {
                groupId,
                userId,
            },
        },
    });

    if (!membership) {
        throw new Error('You are not a member of this group');
    }

    // Prevent creator from leaving
    if (membership.role === MemberRole.CREATOR) {
        throw new Error('Creator cannot leave group. Transfer ownership or delete the group.');
    }

    // Remove user's books from the group
    const userBooks = await prisma.bookGroup.findMany({
        where: {
            groupId,
            book: {
                ownerId: userId,
            },
        },
    });

    if (userBooks.length > 0) {
        await prisma.bookGroup.deleteMany({
            where: {
                groupId,
                book: {
                    ownerId: userId,
                },
            },
        });

        // Update group's books count
        await prisma.group.update({
            where: { id: groupId },
            data: {
                booksCount: {
                    decrement: userBooks.length,
                },
            },
        });
    }

    // Remove membership
    await prisma.groupMember.delete({
        where: {
            groupId_userId: {
                groupId,
                userId,
            },
        },
    });

    // Decrement member count
    await prisma.group.update({
        where: { id: groupId },
        data: {
            memberCount: {
                decrement: 1,
            },
        },
    });
}

/**
 * Update group details
 */
export async function updateGroup(
    groupId: string,
    userId: string,
    data: {
        name?: string;
        description?: string;
        coverImageUrl?: string;
        category?: GroupCategory;
        privacy?: PrivacySetting;
        rules?: string;
    }
) {
    // Verify user has admin or creator role
    const membership = await prisma.groupMember.findUnique({
        where: {
            groupId_userId: {
                groupId,
                userId,
            },
        },
    });

    if (!membership) {
        throw new Error('You are not a member of this group');
    }

    if (membership.role !== MemberRole.ADMIN && membership.role !== MemberRole.CREATOR) {
        throw new Error('Only admins and creators can update group settings');
    }

    // Update group
    const updatedGroup = await prisma.group.update({
        where: { id: groupId },
        data,
        include: {
            creator: {
                select: {
                    id: true,
                    name: true,
                    profileImageUrl: true,
                },
            },
        },
    });

    return {
        ...updatedGroup,
        role: membership.role,
    };
}

/**
 * Delete a group
 */
export async function deleteGroup(groupId: string, userId: string) {
    // Verify user is the creator
    const group = await prisma.group.findUnique({
        where: { id: groupId },
    });

    if (!group) {
        throw new Error('Group not found');
    }

    if (group.creatorId !== userId) {
        throw new Error('Only the creator can delete the group');
    }

    // Delete group (cascade will handle members, bookGroups, transactions)
    await prisma.group.delete({
        where: { id: groupId },
    });
}

/**
 * Update member role
 */
export async function updateMemberRole(
    groupId: string,
    targetUserId: string,
    requesterId: string,
    newRole: MemberRole
) {
    // Verify requester has admin or creator role
    const requesterMembership = await prisma.groupMember.findUnique({
        where: {
            groupId_userId: {
                groupId,
                userId: requesterId,
            },
        },
    });

    if (!requesterMembership) {
        throw new Error('You are not a member of this group');
    }

    if (requesterMembership.role !== MemberRole.ADMIN && requesterMembership.role !== MemberRole.CREATOR) {
        throw new Error('Only admins and creators can update member roles');
    }

    // Get target member
    const targetMembership = await prisma.groupMember.findUnique({
        where: {
            groupId_userId: {
                groupId,
                userId: targetUserId,
            },
        },
    });

    if (!targetMembership) {
        throw new Error('Target user is not a member of this group');
    }

    // Cannot change creator's role
    if (targetMembership.role === MemberRole.CREATOR) {
        throw new Error('Cannot change creator\'s role');
    }

    // Cannot assign creator role
    if (newRole === MemberRole.CREATOR) {
        throw new Error('Cannot assign creator role');
    }

    // Update role
    const updatedMembership = await prisma.groupMember.update({
        where: {
            groupId_userId: {
                groupId,
                userId: targetUserId,
            },
        },
        data: {
            role: newRole,
        },
        include: {
            user: {
                select: {
                    id: true,
                    name: true,
                    profileImageUrl: true,
                },
            },
        },
    });

    return updatedMembership;
}

/**
 * Remove a member from the group
 */
export async function removeMember(
    groupId: string,
    targetUserId: string,
    requesterId: string
) {
    // Verify requester has admin or creator role
    const requesterMembership = await prisma.groupMember.findUnique({
        where: {
            groupId_userId: {
                groupId,
                userId: requesterId,
            },
        },
    });

    if (!requesterMembership) {
        throw new Error('You are not a member of this group');
    }

    if (requesterMembership.role !== MemberRole.ADMIN && requesterMembership.role !== MemberRole.CREATOR) {
        throw new Error('Only admins and creators can remove members');
    }

    // Get target member
    const targetMembership = await prisma.groupMember.findUnique({
        where: {
            groupId_userId: {
                groupId,
                userId: targetUserId,
            },
        },
    });

    if (!targetMembership) {
        throw new Error('Target user is not a member of this group');
    }

    // Cannot remove creator
    if (targetMembership.role === MemberRole.CREATOR) {
        throw new Error('Cannot remove the creator');
    }

    // Remove user's books from the group
    const userBooks = await prisma.bookGroup.findMany({
        where: {
            groupId,
            book: {
                ownerId: targetUserId,
            },
        },
    });

    if (userBooks.length > 0) {
        await prisma.bookGroup.deleteMany({
            where: {
                groupId,
                book: {
                    ownerId: targetUserId,
                },
            },
        });

        // Update group's books count
        await prisma.group.update({
            where: { id: groupId },
            data: {
                booksCount: {
                    decrement: userBooks.length,
                },
            },
        });
    }

    // Remove membership
    await prisma.groupMember.delete({
        where: {
            groupId_userId: {
                groupId,
                userId: targetUserId,
            },
        },
    });

    // Decrement member count
    await prisma.group.update({
        where: { id: groupId },
        data: {
            memberCount: {
                decrement: 1,
            },
        },
    });
}

/**
 * Regenerate invite code
 */
export async function regenerateInviteCode(
    groupId: string,
    userId: string,
    expiresInDays?: number
) {
    // Verify user has admin or creator role
    const membership = await prisma.groupMember.findUnique({
        where: {
            groupId_userId: {
                groupId,
                userId,
            },
        },
    });

    if (!membership) {
        throw new Error('You are not a member of this group');
    }

    if (membership.role !== MemberRole.ADMIN && membership.role !== MemberRole.CREATOR) {
        throw new Error('Only admins and creators can regenerate invite codes');
    }

    // Generate new unique invite code
    let inviteCode = generateInviteCode();
    let codeExists = await prisma.group.findUnique({ where: { inviteCode } });

    while (codeExists) {
        inviteCode = generateInviteCode();
        codeExists = await prisma.group.findUnique({ where: { inviteCode } });
    }

    // Calculate expiry if provided
    let inviteCodeExpiry: Date | null = null;
    if (expiresInDays) {
        inviteCodeExpiry = new Date();
        inviteCodeExpiry.setDate(inviteCodeExpiry.getDate() + expiresInDays);
    }

    // Update group
    const updatedGroup = await prisma.group.update({
        where: { id: groupId },
        data: {
            inviteCode,
            inviteCodeExpiry,
        },
    });

    return {
        inviteCode: updatedGroup.inviteCode,
        inviteCodeExpiry: updatedGroup.inviteCodeExpiry,
    };
}
