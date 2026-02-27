import { Request, Response } from 'express';
import {
    getNotifications,
    markAsRead,
    markAllAsRead,
    deleteNotification,
} from '../services/notification.service';

/**
 * GET /api/v1/notifications
 * Fetch current user's notifications
 */
export async function getNotificationsController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }

        const unreadOnly = req.query.unreadOnly === 'true';
        const result = await getNotifications(req.user.userId, unreadOnly);
        res.json(result);
    } catch (error) {
        console.error('Get notifications error:', error);
        res.status(500).json({ error: 'Internal Server Error', message: 'Failed to fetch notifications' });
    }
}

/**
 * PUT /api/v1/notifications/:id/read
 * Mark a single notification as read
 */
export async function markAsReadController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }

        const { id } = req.params;
        const notification = await markAsRead(id, req.user.userId);
        res.json({ message: 'Notification marked as read', notification });
    } catch (error) {
        console.error('Mark as read error:', error);
        if (error instanceof Error) {
            if (error.message === 'Notification not found') {
                return res.status(404).json({ error: 'Not Found', message: error.message });
            }
            if (error.message === 'Unauthorized') {
                return res.status(403).json({ error: 'Forbidden', message: error.message });
            }
        }
        res.status(500).json({ error: 'Internal Server Error', message: 'Failed to mark notification' });
    }
}

/**
 * PUT /api/v1/notifications/mark-all-read
 * Mark all notifications as read
 */
export async function markAllAsReadController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }

        const result = await markAllAsRead(req.user.userId);
        res.json({ message: 'All notifications marked as read', ...result });
    } catch (error) {
        console.error('Mark all as read error:', error);
        res.status(500).json({ error: 'Internal Server Error', message: 'Failed to mark all notifications' });
    }
}

/**
 * DELETE /api/v1/notifications/:id
 * Delete a notification
 */
export async function deleteNotificationController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }

        const { id } = req.params;
        await deleteNotification(id, req.user.userId);
        res.json({ message: 'Notification deleted successfully' });
    } catch (error) {
        console.error('Delete notification error:', error);
        if (error instanceof Error) {
            if (error.message === 'Notification not found') {
                return res.status(404).json({ error: 'Not Found', message: error.message });
            }
            if (error.message === 'Unauthorized') {
                return res.status(403).json({ error: 'Forbidden', message: error.message });
            }
        }
        res.status(500).json({ error: 'Internal Server Error', message: 'Failed to delete notification' });
    }
}
