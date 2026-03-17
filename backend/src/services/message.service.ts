import { prisma } from '../config/database';
import { NotificationType, TransactionStatus } from '@prisma/client';
import { notificationService } from './notification.service';

export const messageService = {
    async getMessages(transactionId: string, userId: string) {
        const transaction = await prisma.transaction.findUnique({
            where: { id: transactionId },
        });

        if (!transaction) {
            throw new Error('Transaction not found');
        }

        if (transaction.borrowerId !== userId && transaction.ownerId !== userId) {
            throw new Error('You are not a party to this transaction');
        }

        if (transaction.status !== TransactionStatus.APPROVED && transaction.status !== TransactionStatus.ACTIVE) {
            throw new Error('Chat is only available for approved or active transactions');
        }

        const messages = await prisma.message.findMany({
            where: { transactionId },
            orderBy: { createdAt: 'asc' },
            include: {
                sender: {
                    select: {
                        id: true,
                        name: true,
                        profileImageUrl: true,
                    },
                },
            },
        });

        await prisma.message.updateMany({
            where: {
                transactionId,
                senderId: { not: userId },
                isRead: false,
            },
            data: { isRead: true },
        });

        return messages;
    },

    async sendMessage(transactionId: string, senderId: string, content: string) {
        const transaction = await prisma.transaction.findUnique({
            where: { id: transactionId },
            include: {
                book: { select: { title: true } },
                borrower: { select: { id: true, name: true } },
                owner: { select: { id: true, name: true } },
            },
        });

        if (!transaction) {
            throw new Error('Transaction not found');
        }

        if (transaction.borrowerId !== senderId && transaction.ownerId !== senderId) {
            throw new Error('You are not a party to this transaction');
        }

        if (transaction.status !== TransactionStatus.APPROVED && transaction.status !== TransactionStatus.ACTIVE) {
            throw new Error('Chat is only available for approved or active transactions');
        }

        const message = await prisma.message.create({
            data: {
                transactionId,
                senderId,
                content,
            },
            include: {
                sender: {
                    select: {
                        id: true,
                        name: true,
                        profileImageUrl: true,
                    },
                },
            },
        });

        const recipientId = senderId === transaction.borrowerId ? transaction.ownerId : transaction.borrowerId;
        const senderName = senderId === transaction.borrowerId ? transaction.borrower.name : transaction.owner.name;

        await notificationService.createNotification({
            userId: recipientId,
            type: NotificationType.NEW_MESSAGE,
            title: `New message from ${senderName}`,
            message: content.length > 50 ? content.substring(0, 50) + '...' : content,
            transactionId,
            bookId: transaction.bookId,
            relatedUserId: senderId,
        });

        return message;
    },

    async getUnreadCount(transactionId: string, userId: string) {
        const count = await prisma.message.count({
            where: {
                transactionId,
                senderId: { not: userId },
                isRead: false,
            },
        });
        return count;
    },

    async markAsRead(transactionId: string, userId: string) {
        await prisma.message.updateMany({
            where: {
                transactionId,
                senderId: { not: userId },
                isRead: false,
            },
            data: { isRead: true },
        });
    },
};
