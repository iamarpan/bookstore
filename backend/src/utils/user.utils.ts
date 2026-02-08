import { User } from '@prisma/client';

export interface FormattedUser {
    id: string;
    phoneNumber: string;
    phoneVerified: boolean;
    name: string;
    email: string | null;
    bio: string | null;
    profileImageUrl: string | null;
    joinedGroupIds: string[];
    createdGroupIds: string[];
    stats: {
        booksShared: number;
        successfulLends: number;
        booksBorrowed: number;
        totalEarned: number;
        averageRating: number;
    };
    privacySettings: {
        phoneVisibility: string;
    };
    notificationPreferences: {
        pushEnabled: boolean;
        emailEnabled: boolean;
        borrowRequests: boolean;
        dueDateReminders: boolean;
        groupActivity: boolean;
    };
    deviceToken: string | null;
    lastTokenUpdate: Date | null;
    isActive: boolean;
    createdAt: Date;
    lastLoginAt: Date | null;
}

/**
 * Formats a Prisma User object into the structured format expected by the iOS app.
 */
export function formatUserResponse(user: User & { joinedGroupIds?: string[], createdGroupIds?: string[] }): FormattedUser {
    if (!user) return null as any;

    return {
        id: user.id,
        phoneNumber: user.phoneNumber,
        phoneVerified: user.phoneVerified,
        name: user.name,
        email: user.email,
        bio: user.bio,
        profileImageUrl: user.profileImageUrl,

        // Group memberships (default to empty if not fetched)
        joinedGroupIds: user.joinedGroupIds || [],
        createdGroupIds: user.createdGroupIds || [],

        // Statistics
        stats: {
            booksShared: user.booksShared,
            successfulLends: user.successfulLends,
            booksBorrowed: user.booksBorrowed,
            totalEarned: Number(user.totalEarned),
            averageRating: Number(user.averageRating),
        },

        // Settings
        privacySettings: {
            phoneVisibility: user.phoneVisibility,
        },

        notificationPreferences: {
            pushEnabled: user.pushEnabled,
            emailEnabled: user.emailEnabled,
            borrowRequests: user.borrowRequestsNotif,
            dueDateReminders: user.dueDateRemindersNotif,
            groupActivity: user.groupActivityNotif,
        },

        // Device and session
        deviceToken: user.deviceToken,
        lastTokenUpdate: user.lastTokenUpdate,

        // Status
        isActive: user.isActive,
        createdAt: user.createdAt,
        lastLoginAt: user.lastLoginAt,
    };
}
