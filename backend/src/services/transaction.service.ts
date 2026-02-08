import { PrismaClient, TransactionStatus } from '@prisma/client';

const prisma = new PrismaClient();

export class TransactionService {
    /**
     * Get transactions for current user with filters
     */
    async getMyTransactions(userId: string, filters: {
        role?: 'BORROWER' | 'OWNER';
        status?: TransactionStatus;
        page?: number;
        limit?: number;
    }) {
        const { role, status, page = 1, limit = 20 } = filters;
        const skip = (page - 1) * limit;

        const where: any = {};

        if (role === 'BORROWER') {
            where.borrowerId = userId;
        } else if (role === 'OWNER') {
            where.ownerId = userId;
        } else {
            // All transactions where user is either borrower or owner
            where.OR = [
                { borrowerId: userId },
                { ownerId: userId }
            ];
        }

        if (status) {
            where.status = status;
        }

        const [transactions, total] = await Promise.all([
            prisma.transaction.findMany({
                where,
                include: {
                    book: {
                        select: {
                            id: true,
                            title: true,
                            imageUrl: true,
                            ownerId: true
                        }
                    },
                    borrower: {
                        select: {
                            id: true,
                            name: true,
                            profileImageUrl: true
                        }
                    },
                    owner: {
                        select: {
                            id: true,
                            name: true,
                            profileImageUrl: true
                        }
                    }
                },
                orderBy: { requestedAt: 'desc' },
                skip,
                take: limit
            }),
            prisma.transaction.count({ where })
        ]);

        // Map to match iOS model expectations
        const mappedTransactions = transactions.map(t => ({
            id: t.id,
            bookId: t.bookId,
            bookTitle: t.book.title,
            bookImageUrl: t.book.imageUrl,
            borrowerId: t.borrowerId,
            borrowerName: t.borrower.name,
            borrowerProfileImageUrl: t.borrower.profileImageUrl,
            ownerId: t.ownerId,
            ownerName: t.owner.name,
            ownerProfileImageUrl: t.owner.profileImageUrl,
            groupId: t.groupId,
            status: t.status,
            duration: t.duration,
            durationDays: t.durationDays,
            lendingFee: Number(t.lendingFee),
            requestMessage: t.requestMessage,
            rejectionReason: t.rejectionReason,
            handoverOTP: t.handoverOTP,
            handoverOTPExpiry: t.handoverOTPExpiry,
            returnOTP: t.returnOTP,
            returnOTPExpiry: t.returnOTPExpiry,
            paymentStatus: {
                borrowerConfirmed: t.borrowerPaymentConfirmed,
                ownerConfirmed: t.ownerPaymentConfirmed
            },
            requestedAt: t.requestedAt,
            approvedAt: t.approvedAt,
            handoverAt: t.handoverAt,
            dueDate: t.dueDate,
            returnedAt: t.returnedAt,
            ownerRating: t.ownerRating,
            ownerComment: t.ownerComment,
            borrowerRating: t.borrowerRating,
            borrowerComment: t.borrowerComment,
            bookConditionRating: t.bookConditionRating
        }));

        return {
            transactions: mappedTransactions,
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit)
            }
        };
    }

    /**
     * Create a new borrow request
     */
    async createRequest(data: {
        bookId: String;
        borrowerId: string;
        duration: any;
        durationDays: number;
        message?: string;
    }) {
        const book = await prisma.book.findUnique({
            where: { id: data.bookId as string },
            include: { bookGroups: true }
        });

        if (!book) throw new Error('Book not found');
        if (!book.isAvailable) throw new Error('Book is currently not available');
        if (book.ownerId === data.borrowerId) throw new Error('You cannot borrow your own book');

        // For now, use the first group the book is in
        const groupId = book.bookGroups[0]?.groupId;
        if (!groupId) throw new Error('Book must belong to at least one group');

        return await prisma.transaction.create({
            data: {
                bookId: data.bookId as string,
                borrowerId: data.borrowerId,
                ownerId: book.ownerId,
                groupId,
                status: 'PENDING',
                duration: data.duration,
                durationDays: data.durationDays,
                lendingFee: book.lendingPricePerWeek,
                requestMessage: data.message,
                requestedAt: new Date()
            }
        });
    }

    async updateStatus(id: string, userId: string, status: TransactionStatus, data?: any) {
        const transaction = await prisma.transaction.findUnique({
            where: { id },
            include: { book: true }
        });

        if (!transaction) throw new Error('Transaction not found');

        // Ownership check for certain statuses
        if (['APPROVED', 'REJECTED'].includes(status) && transaction.ownerId !== userId) {
            throw new Error('Unauthorized');
        }

        const updateData: any = { status };

        if (status === 'APPROVED') {
            updateData.approvedAt = new Date();
        } else if (status === 'REJECTED') {
            updateData.rejectionReason = data?.reason;
        } else if (status === 'ACTIVE') {
            updateData.handoverAt = new Date();
            const dueDate = new Date();
            dueDate.setDate(dueDate.getDate() + transaction.durationDays);
            updateData.dueDate = dueDate;

            // Mark book as unavailable
            await prisma.book.update({
                where: { id: transaction.bookId },
                data: { isAvailable: false, currentTransactionId: id }
            });
        } else if (status === 'RETURNED') {
            updateData.returnedAt = new Date();
            // Mark book as available
            await prisma.book.update({
                where: { id: transaction.bookId },
                data: { isAvailable: true, currentTransactionId: null }
            });
        }

        return await prisma.transaction.update({
            where: { id },
            data: updateData,
            include: {
                book: true,
                borrower: { select: { id: true, name: true, profileImageUrl: true } },
                owner: { select: { id: true, name: true, profileImageUrl: true } }
            }
        });
    }

    // Map a single transaction to iOS format
    mapTransaction(t: any) {
        return {
            id: t.id,
            bookId: t.bookId,
            bookTitle: t.book.title,
            bookImageUrl: t.book.imageUrl,
            borrowerId: t.borrowerId,
            borrowerName: t.borrower?.name || '',
            borrowerProfileImageUrl: t.borrower?.profileImageUrl,
            ownerId: t.ownerId,
            ownerName: t.owner?.name || '',
            ownerProfileImageUrl: t.owner?.profileImageUrl,
            groupId: t.groupId,
            status: t.status,
            duration: t.duration,
            durationDays: t.durationDays,
            lendingFee: Number(t.lendingFee),
            requestMessage: t.requestMessage,
            rejectionReason: t.rejectionReason,
            handoverOTP: t.handoverOTP,
            handoverOTPExpiry: t.handoverOTPExpiry,
            returnOTP: t.returnOTP,
            returnOTPExpiry: t.returnOTPExpiry,
            paymentStatus: {
                borrowerConfirmed: t.borrowerPaymentConfirmed,
                ownerConfirmed: t.ownerPaymentConfirmed
            },
            requestedAt: t.requestedAt,
            approvedAt: t.approvedAt,
            handoverAt: t.handoverAt,
            dueDate: t.dueDate,
            returnedAt: t.returnedAt,
            ownerRating: t.ownerRating,
            ownerComment: t.ownerComment,
            borrowerRating: t.borrowerRating,
            borrowerComment: t.borrowerComment,
            bookConditionRating: t.bookConditionRating
        };
    }
}
