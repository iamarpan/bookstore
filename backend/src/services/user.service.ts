import prisma from '../config/database';
import { User } from '@prisma/client';
import { FormattedUser, formatUserResponse } from '../utils/user.utils';

// Public-safe subset of a user profile (no phone, email, device tokens, etc.)
export interface PublicUserProfile {
    id: string;
    name: string;
    bio: string | null;
    profileImageUrl: string | null;
    createdAt: Date;
    stats: {
        booksShared: number;
        successfulLends: number;
        booksBorrowed: number;
        averageRating: number;
    };
}

/**
 * Get user by ID
 */
export async function getUserById(userId: string): Promise<FormattedUser | null> {
    const user = await prisma.user.findUnique({
        where: { id: userId },
    });
    return user ? formatUserResponse(user) : null;
}

/**
 * Get user by phone number
 */
export async function getUserByPhone(phoneNumber: string): Promise<FormattedUser | null> {
    const user = await prisma.user.findUnique({
        where: { phoneNumber },
    });
    return user ? formatUserResponse(user) : null;
}

/**
 * Update user profile
 */
export async function updateUserProfile(
    userId: string,
    data: {
        name?: string;
        email?: string;
        bio?: string;
        profileImageUrl?: string;
    }
): Promise<FormattedUser> {
    const user = await prisma.user.update({
        where: { id: userId },
        data: {
            ...data,
            // Update timestamp when profile is modified
            lastLoginAt: new Date(),
        },
    });
    return formatUserResponse(user);
}

/**
 * Update user notification preferences
 */
export async function updateNotificationPreferences(
    userId: string,
    preferences: {
        pushEnabled?: boolean;
        emailEnabled?: boolean;
        borrowRequestsNotif?: boolean;
        dueDateRemindersNotif?: boolean;
        groupActivityNotif?: boolean;
    }
): Promise<FormattedUser> {
    const user = await prisma.user.update({
        where: { id: userId },
        data: preferences,
    });
    return formatUserResponse(user);
}

/**
 * Update user privacy settings
 */
export async function updatePrivacySettings(
    userId: string,
    settings: {
        phoneVisibility?: 'AFTER_APPROVAL' | 'GROUP_MEMBERS' | 'PUBLIC';
    }
): Promise<FormattedUser> {
    const user = await prisma.user.update({
        where: { id: userId },
        data: settings,
    });
    return formatUserResponse(user);
}

/**
 * Update user device token (for push notifications)
 */
export async function updateDeviceToken(
    userId: string,
    deviceToken: string
): Promise<FormattedUser> {
    const user = await prisma.user.update({
        where: { id: userId },
        data: {
            deviceToken,
            lastTokenUpdate: new Date(),
        },
    });
    return formatUserResponse(user);
}

/**
 * Get user's books
 */
export async function getUserBooks(userId: string) {
    return await prisma.book.findMany({
        where: { ownerId: userId },
        include: {
            bookGroups: {
                include: {
                    group: {
                        select: {
                            id: true,
                            name: true,
                        },
                    },
                },
            },
        },
        orderBy: {
            createdAt: 'desc',
        },
    });
}

/**
 * Get user's groups
 */
export async function getUserGroups(userId: string) {
    const memberships = await prisma.groupMember.findMany({
        where: { userId },
        include: {
            group: true,
        },
    });

    return memberships.map(m => m.group);
}

/**
 * Get user statistics
 */
export async function getUserStats(userId: string) {
    const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
            booksShared: true,
            successfulLends: true,
            booksBorrowed: true,
            totalEarned: true,
            averageRating: true,
        },
    });

    return user;
}

/**
 * Get public profile for any user (safe fields only — no phone, email, device token)
 */
export async function getPublicUserProfile(userId: string): Promise<PublicUserProfile | null> {
    const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
            id: true,
            name: true,
            bio: true,
            profileImageUrl: true,
            createdAt: true,
            booksShared: true,
            successfulLends: true,
            booksBorrowed: true,
            averageRating: true,
            isActive: true,
        },
    });

    if (!user || !user.isActive) return null;

    return {
        id: user.id,
        name: user.name,
        bio: user.bio,
        profileImageUrl: user.profileImageUrl,
        createdAt: user.createdAt,
        stats: {
            booksShared: user.booksShared,
            successfulLends: user.successfulLends,
            booksBorrowed: user.booksBorrowed,
            averageRating: Number(user.averageRating),
        },
    };
}

/**
 * Get books listed by any user (for public profile)
 */
export async function getPublicUserBooks(userId: string) {
    return await prisma.book.findMany({
        where: { ownerId: userId },
        include: {
            owner: {
                select: {
                    id: true,
                    name: true,
                    averageRating: true,
                    booksShared: true,
                    profileImageUrl: true,
                },
            },
            bookGroups: {
                include: {
                    group: {
                        select: { id: true, name: true },
                    },
                },
            },
        },
        orderBy: { createdAt: 'desc' },
    });
}
