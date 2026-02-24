import { Request, Response } from 'express';
import { TransactionService } from '../services/transaction.service';
import { PrismaClient, TransactionStatus } from '@prisma/client';

const transactionService = new TransactionService();

export const getMyTransactions = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }
        const { role, status, page, limit } = req.query;

        const result = await transactionService.getMyTransactions(userId, {
            role: role as any,
            status: status as TransactionStatus,
            page: page ? parseInt(page as string) : undefined,
            limit: limit ? parseInt(limit as string) : undefined
        });

        res.json(result);
    } catch (error: any) {
        console.error('Error in getMyTransactions:', error);
        res.status(500).json({ error: 'Server Error', message: error.message });
    }
};

export const createBorrowRequest = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }
        const { bookId, duration, durationDays, message } = req.body;

        if (!bookId || !duration) {
            return res.status(400).json({ error: 'Bad Request', message: 'bookId and duration are required' });
        }

        const transaction = await transactionService.createRequest({
            bookId,
            borrowerId: userId,
            duration,
            durationDays,
            message
        });

        res.status(201).json(transaction);
    } catch (error: any) {
        console.error('Error in createBorrowRequest:', error);
        res.status(400).json({ error: 'Bad Request', message: error.message });
    }
};

export const approveRequest = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId as string;
        const { id } = req.params;
        const transaction = await transactionService.updateStatus(id, userId, 'APPROVED');
        res.json(transactionService.mapTransaction(transaction));
    } catch (error: any) {
        res.status(400).json({ error: 'Bad Request', message: error.message });
    }
};

export const rejectRequest = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId as string;
        const { id } = req.params;
        const { reason } = req.body;
        const transaction = await transactionService.updateStatus(id, userId, 'REJECTED', { reason });
        res.json(transactionService.mapTransaction(transaction));
    } catch (error: any) {
        res.status(400).json({ error: 'Bad Request', message: error.message });
    }
};

export const confirmHandover = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId as string;
        const { id } = req.params;
        const { otp } = req.body; // In a real app we'd verify OTP here
        const transaction = await transactionService.updateStatus(id, userId, 'ACTIVE');
        res.json(transactionService.mapTransaction(transaction));
    } catch (error: any) {
        res.status(400).json({ error: 'Bad Request', message: error.message });
    }
};

export const confirmReturn = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId as string;
        const { id } = req.params;
        const { otp } = req.body;
        const transaction = await transactionService.updateStatus(id, userId, 'RETURNED');
        res.json(transactionService.mapTransaction(transaction));
    } catch (error: any) {
        res.status(400).json({ error: 'Bad Request', message: error.message });
    }
};

export const markPayment = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }
        const { id } = req.params;
        const { role } = req.body;

        if (!role || !['BORROWER', 'OWNER'].includes(role)) {
            return res.status(400).json({ error: 'Bad Request', message: 'role must be BORROWER or OWNER' });
        }

        const transaction = await transactionService.markPaymentComplete(id, userId, role);
        res.json(transaction);
    } catch (error: any) {
        const status = error.message.includes('Unauthorized') ? 403
            : error.message.includes('not found') ? 404
                : 400;
        res.status(status).json({ error: 'Bad Request', message: error.message });
    }
};

export const rateTransaction = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({ error: 'Unauthorized', message: 'User not authenticated' });
        }
        const { id } = req.params;
        const { rating, comment, bookConditionRating } = req.body;

        if (rating === undefined || rating === null) {
            return res.status(400).json({ error: 'Bad Request', message: 'rating is required' });
        }

        const transaction = await transactionService.rateTransaction(id, userId, {
            rating: parseInt(rating),
            comment,
            bookConditionRating: bookConditionRating !== undefined ? parseInt(bookConditionRating) : undefined,
        });
        res.json(transaction);
    } catch (error: any) {
        const status = error.message.includes('Unauthorized') ? 403
            : error.message.includes('not found') ? 404
                : 400;
        res.status(status).json({ error: 'Bad Request', message: error.message });
    }
};
