import { Request, Response } from 'express';
import {
    getUserById,
    updateUserProfile,
    updateNotificationPreferences,
    updatePrivacySettings,
    updateDeviceToken,
    getUserBooks,
} from '../services/user.service';

/**
 * Get current user profile
 * GET /api/v1/users/me
 */
export async function getCurrentUser(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const user = await getUserById(req.user.userId);

        if (!user) {
            return res.status(404).json({
                error: 'Not Found',
                message: 'User not found',
            });
        }

        res.json(user);
    } catch (error) {
        console.error('Get current user error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to fetch user profile',
        });
    }
}

/**
 * Update current user profile
 * PUT /api/v1/users/me
 */
export async function updateCurrentUser(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { name, email, bio, profileImageUrl } = req.body;

        // Validate at least one field is provided
        if (!name && !email && !bio && !profileImageUrl) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'At least one field must be provided',
            });
        }

        const updatedUser = await updateUserProfile(req.user.userId, {
            name,
            email,
            bio,
            profileImageUrl,
        });

        res.json(updatedUser);
    } catch (error) {
        console.error('Update current user error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to update user profile',
        });
    }
}

/**
 * Update notification preferences
 * PUT /api/v1/users/me/notifications
 */
export async function updateNotifications(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const {
            pushEnabled,
            emailEnabled,
            borrowRequestsNotif,
            dueDateRemindersNotif,
            groupActivityNotif,
        } = req.body;

        const updatedUser = await updateNotificationPreferences(req.user.userId, {
            pushEnabled,
            emailEnabled,
            borrowRequestsNotif,
            dueDateRemindersNotif,
            groupActivityNotif,
        });

        res.json({
            message: 'Notification preferences updated',
            preferences: {
                pushEnabled: updatedUser.notificationPreferences.pushEnabled,
                emailEnabled: updatedUser.notificationPreferences.emailEnabled,
                borrowRequestsNotif: updatedUser.notificationPreferences.borrowRequests,
                dueDateRemindersNotif: updatedUser.notificationPreferences.dueDateReminders,
                groupActivityNotif: updatedUser.notificationPreferences.groupActivity,
            },
        });
    } catch (error) {
        console.error('Update notifications error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to update notification preferences',
        });
    }
}

/**
 * Update privacy settings
 * PUT /api/v1/users/me/privacy
 */
export async function updatePrivacy(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { phoneVisibility } = req.body;

        if (!phoneVisibility) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'phoneVisibility is required',
            });
        }

        const updatedUser = await updatePrivacySettings(req.user.userId, {
            phoneVisibility,
        });

        res.json({
            message: 'Privacy settings updated',
            phoneVisibility: updatedUser.privacySettings.phoneVisibility,
        });
    } catch (error) {
        console.error('Update privacy error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to update privacy settings',
        });
    }
}

/**
 * Register device token for push notifications
 * POST /api/v1/users/me/device-token
 */
export async function registerDeviceToken(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { deviceToken } = req.body;

        if (!deviceToken) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'deviceToken is required',
            });
        }

        await updateDeviceToken(req.user.userId, deviceToken);

        res.json({
            message: 'Device token registered successfully',
        });
    } catch (error) {
        console.error('Register device token error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to register device token',
        });
    }
}

/**
 * Get current user's books
 * GET /api/v1/users/me/books
 */
export async function getCurrentUserBooks(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const books = await getUserBooks(req.user.userId);

        res.json(books);
    } catch (error) {
        console.error('Get current user books error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to fetch user books',
        });
    }
}
