import prisma from '../config/database';
import { NotificationType } from '@prisma/client';
import admin from '../config/firebase';

/**
 * Fetch notifications for a user
 */
export async function getNotifications(userId: string, unreadOnly: boolean = false) {
    const where: any = { userId };
    if (unreadOnly) {
        where.isRead = false;
    }

    const notifications = await prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: 50,
    });

    const unreadCount = await prisma.notification.count({
        where: { userId, isRead: false },
    });

    return { notifications, unreadCount };
}

/**
 * Mark a single notification as read
 */
export async function markAsRead(notificationId: string, userId: string) {
    const notification = await prisma.notification.findUnique({
        where: { id: notificationId },
    });

    if (!notification) throw new Error('Notification not found');
    if (notification.userId !== userId) throw new Error('Unauthorized');

    return await prisma.notification.update({
        where: { id: notificationId },
        data: { isRead: true },
    });
}

/**
 * Mark all notifications for a user as read
 */
export async function markAllAsRead(userId: string) {
    const result = await prisma.notification.updateMany({
        where: { userId, isRead: false },
        data: { isRead: true },
    });
    return { updatedCount: result.count };
}

/**
 * Delete a notification
 */
export async function deleteNotification(notificationId: string, userId: string) {
    const notification = await prisma.notification.findUnique({
        where: { id: notificationId },
    });

    if (!notification) throw new Error('Notification not found');
    if (notification.userId !== userId) throw new Error('Unauthorized');

    await prisma.notification.delete({ where: { id: notificationId } });
}

/**
 * Create a notification (internal use by other services)
 */
export async function createNotification(data: {
    userId: string;
    type: NotificationType;
    title: string;
    message: string;
    transactionId?: string;
    bookId?: string;
    groupId?: string;
    relatedUserId?: string;
}) {
    const notification = await prisma.notification.create({ data });

    try {
        const user = await prisma.user.findUnique({
            where: { id: data.userId },
            select: { deviceToken: true }
        });

        if (user?.deviceToken && admin.apps.length > 0) {
            await admin.messaging().send({
                token: user.deviceToken,
                notification: {
                    title: data.title,
                    body: data.message,
                },
                data: {
                    type: data.type,
                    transactionId: data.transactionId || '',
                    bookId: data.bookId || '',
                    groupId: data.groupId || '',
                    relatedUserId: data.relatedUserId || '',
                }
            });
            console.log(`Push notification sent to ${data.userId}`);
        }
    } catch (error) {
        console.error('Failed to send push notification:', error);
    }

    return notification;
}
