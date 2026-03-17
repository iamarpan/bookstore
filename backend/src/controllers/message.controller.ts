import { Request, Response } from 'express';
import { messageService } from '../services/message.service';

export const getMessages = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }

        const { transactionId } = req.params;
        const messages = await messageService.getMessages(transactionId, userId);
        res.json({ messages });
    } catch (error: any) {
        const status = error.message.includes('not found') ? 404
            : error.message.includes('not a party') ? 403
            : error.message.includes('only available') ? 400
            : 500;
        res.status(status).json({ error: 'Error', message: error.message });
    }
};

export const sendMessage = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }

        const { transactionId } = req.params;
        const { content } = req.body;

        if (!content || content.trim().length === 0) {
            return res.status(400).json({ error: 'Bad Request', message: 'Message content is required' });
        }

        const message = await messageService.sendMessage(transactionId, userId, content.trim());
        res.status(201).json(message);
    } catch (error: any) {
        const status = error.message.includes('not found') ? 404
            : error.message.includes('not a party') ? 403
            : error.message.includes('only available') ? 400
            : 500;
        res.status(status).json({ error: 'Error', message: error.message });
    }
};

export const getUnreadCount = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }

        const { transactionId } = req.params;
        const count = await messageService.getUnreadCount(transactionId, userId);
        res.json({ unreadCount: count });
    } catch (error: any) {
        res.status(500).json({ error: 'Error', message: error.message });
    }
};

export const markAsRead = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }

        const { transactionId } = req.params;
        await messageService.markAsRead(transactionId, userId);
        res.json({ success: true });
    } catch (error: any) {
        res.status(500).json({ error: 'Error', message: error.message });
    }
};
