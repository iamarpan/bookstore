import { PrismaClient, TransactionStatus } from '@prisma/client';
import { createNotification } from './notification.service';

const prisma = new PrismaClient();

// 6-digit OTP valid for 10 minutes
const OTP_EXPIRY_MINUTES = 10;

function generateOTP(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

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
     * Get a single transaction by ID (either party may access)
     */
    async getTransactionById(id: string, userId: string) {
        const transaction = await prisma.transaction.findUnique({
            where: { id },
            include: {
                book: {
                    select: { id: true, title: true, imageUrl: true, ownerId: true }
                },
                borrower: { select: { id: true, name: true, profileImageUrl: true } },
                owner: { select: { id: true, name: true, profileImageUrl: true } }
            }
        });

        if (!transaction) throw new Error('Transaction not found');
        if (transaction.borrowerId !== userId && transaction.ownerId !== userId) {
            throw new Error('Unauthorized');
        }

        return this.mapTransaction(transaction);
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

        // Fetch borrower name for notification message
        const borrower = await prisma.user.findUnique({
            where: { id: data.borrowerId },
            select: { name: true }
        });

        const created = await prisma.transaction.create({
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
            },
            include: {
                book: true,
                borrower: { select: { id: true, name: true, profileImageUrl: true } },
                owner: { select: { id: true, name: true, profileImageUrl: true } }
            }
        });

        // Notify owner of the new borrow request
        createNotification({
            userId: book.ownerId,
            type: 'BORROW_REQUEST',
            title: 'New Borrow Request',
            message: `${borrower?.name ?? 'Someone'} wants to borrow "${book.title}"`,
            transactionId: created.id,
            bookId: book.id as string,
            relatedUserId: data.borrowerId
        }).catch(err => console.error('Failed to create BORROW_REQUEST notification:', err));

        return this.mapTransaction(created);
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

        // OTP validation for handover (ACTIVE transition)
        if (status === 'ACTIVE') {
            const otp = data?.otp as string | undefined;
            if (!transaction.handoverOTP) {
                throw new Error('Handover OTP has not been generated yet. Generate it first.');
            }
            if (!otp || otp !== transaction.handoverOTP) {
                throw new Error('Invalid handover OTP');
            }
            if (transaction.handoverOTPExpiry && transaction.handoverOTPExpiry < new Date()) {
                throw new Error('Handover OTP has expired. Please generate a new one.');
            }
        }

        // OTP validation for return (RETURNED transition)
        if (status === 'RETURNED') {
            const otp = data?.otp as string | undefined;
            if (!transaction.returnOTP) {
                throw new Error('Return OTP has not been generated yet. Generate it first.');
            }
            if (!otp || otp !== transaction.returnOTP) {
                throw new Error('Invalid return OTP');
            }
            if (transaction.returnOTPExpiry && transaction.returnOTPExpiry < new Date()) {
                throw new Error('Return OTP has expired. Please generate a new one.');
            }
        }

        const updateData: any = { status };

        if (status === 'APPROVED') {
            updateData.approvedAt = new Date();
        } else if (status === 'REJECTED') {
            updateData.rejectionReason = data?.reason;
        } else if (status === 'ACTIVE') {
            updateData.handoverAt = new Date();
            // Clear the used OTP
            updateData.handoverOTP = null;
            updateData.handoverOTPExpiry = null;
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
            // Clear the used OTP
            updateData.returnOTP = null;
            updateData.returnOTPExpiry = null;
            // Mark book as available
            await prisma.book.update({
                where: { id: transaction.bookId },
                data: { isAvailable: true, currentTransactionId: null }
            });
        }

        const updated = await prisma.transaction.update({
            where: { id },
            data: updateData,
            include: {
                book: true,
                borrower: { select: { id: true, name: true, profileImageUrl: true } },
                owner: { select: { id: true, name: true, profileImageUrl: true } }
            }
        });

        // Send notifications after status change
        if (status === 'APPROVED') {
            createNotification({
                userId: updated.borrowerId,
                type: 'REQUEST_APPROVED',
                title: 'Request Approved! 🎉',
                message: `${updated.owner?.name ?? 'The owner'} approved your request to borrow "${updated.book.title}"`,
                transactionId: id,
                bookId: updated.bookId,
                relatedUserId: updated.ownerId
            }).catch(err => console.error('Failed to create REQUEST_APPROVED notification:', err));
        } else if (status === 'REJECTED') {
            createNotification({
                userId: updated.borrowerId,
                type: 'REQUEST_REJECTED',
                title: 'Request Declined',
                message: `Your request to borrow "${updated.book.title}" was declined${data?.reason ? `: ${data.reason}` : ''}`,
                transactionId: id,
                bookId: updated.bookId,
                relatedUserId: updated.ownerId
            }).catch(err => console.error('Failed to create REQUEST_REJECTED notification:', err));
        }

        return updated;
    }

    /**
     * Generate a handover OTP for an APPROVED transaction (owner only).
     * Stores OTP + expiry in the transaction row and returns the OTP.
     */
    async generateHandoverOTP(id: string, userId: string): Promise<string> {
        const transaction = await prisma.transaction.findUnique({ where: { id } });

        if (!transaction) throw new Error('Transaction not found');
        if (transaction.ownerId !== userId) throw new Error('Unauthorized: only the owner can generate the handover OTP');
        if (transaction.status !== 'APPROVED') throw new Error('Transaction must be APPROVED before generating handover OTP');

        const otp = generateOTP();
        const expiry = new Date();
        expiry.setMinutes(expiry.getMinutes() + OTP_EXPIRY_MINUTES);

        await prisma.transaction.update({
            where: { id },
            data: { handoverOTP: otp, handoverOTPExpiry: expiry }
        });

        console.log(`🔐 Handover OTP generated for transaction ${id}: ${otp} (expires ${expiry.toISOString()})`);
        return otp;
    }

    /**
     * Generate a return OTP for an ACTIVE transaction (owner only).
     * Stores OTP + expiry in the transaction row and returns the OTP.
     */
    async generateReturnOTP(id: string, userId: string): Promise<string> {
        const transaction = await prisma.transaction.findUnique({ where: { id } });

        if (!transaction) throw new Error('Transaction not found');
        if (transaction.ownerId !== userId) throw new Error('Unauthorized: only the owner can generate the return OTP');
        if (transaction.status !== 'ACTIVE') throw new Error('Transaction must be ACTIVE before generating return OTP');

        const otp = generateOTP();
        const expiry = new Date();
        expiry.setMinutes(expiry.getMinutes() + OTP_EXPIRY_MINUTES);

        await prisma.transaction.update({
            where: { id },
            data: { returnOTP: otp, returnOTPExpiry: expiry }
        });

        console.log(`🔐 Return OTP generated for transaction ${id}: ${otp} (expires ${expiry.toISOString()})`);
        return otp;
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

    /**
     * Mark payment as confirmed by one party (offline payment flow).
     * Both borrower and owner must confirm before the payment is fully complete.
     */
    async markPaymentComplete(id: string, userId: string, role: 'BORROWER' | 'OWNER') {
        const transaction = await prisma.transaction.findUnique({
            where: { id },
            include: {
                book: true,
                borrower: { select: { id: true, name: true, profileImageUrl: true } },
                owner: { select: { id: true, name: true, profileImageUrl: true } },
            },
        });

        if (!transaction) throw new Error('Transaction not found');
        if (transaction.status !== 'RETURNED') {
            throw new Error('Payment can only be confirmed after the book has been returned');
        }

        // Verify the caller matches the declared role
        if (role === 'BORROWER' && transaction.borrowerId !== userId) {
            throw new Error('Unauthorized: only the borrower can confirm as BORROWER');
        }
        if (role === 'OWNER' && transaction.ownerId !== userId) {
            throw new Error('Unauthorized: only the owner can confirm as OWNER');
        }

        const updateData: any =
            role === 'BORROWER'
                ? { borrowerPaymentConfirmed: true }
                : { ownerPaymentConfirmed: true };

        const updated = await prisma.transaction.update({
            where: { id },
            data: updateData,
            include: {
                book: true,
                borrower: { select: { id: true, name: true, profileImageUrl: true } },
                owner: { select: { id: true, name: true, profileImageUrl: true } },
            },
        });

        return this.mapTransaction(updated);
    }

    /**
     * Rate a completed transaction.
     * - Borrower rates the owner (and optionally leaves a comment).
     * - Owner rates the borrower and can add a book-condition rating.
     */
    async rateTransaction(id: string, userId: string, data: {
        rating: number;
        comment?: string;
        bookConditionRating?: number;
    }) {
        const transaction = await prisma.transaction.findUnique({
            where: { id },
            include: {
                book: true,
                borrower: { select: { id: true, name: true, profileImageUrl: true } },
                owner: { select: { id: true, name: true, profileImageUrl: true } },
            },
        });

        if (!transaction) throw new Error('Transaction not found');
        if (transaction.status !== 'RETURNED') {
            throw new Error('Transaction must be completed (RETURNED) before rating');
        }

        const isBorrower = transaction.borrowerId === userId;
        const isOwner = transaction.ownerId === userId;

        if (!isBorrower && !isOwner) {
            throw new Error('Unauthorized: you are not a party to this transaction');
        }

        const { rating, comment, bookConditionRating } = data;

        if (rating < 1 || rating > 5) throw new Error('Rating must be between 1 and 5');

        const updateData: any = {};
        if (isBorrower) {
            updateData.borrowerRating = rating;
            updateData.borrowerComment = comment ?? null;
        } else {
            updateData.ownerRating = rating;
            updateData.ownerComment = comment ?? null;
            if (bookConditionRating !== undefined) {
                if (bookConditionRating < 1 || bookConditionRating > 5) {
                    throw new Error('bookConditionRating must be between 1 and 5');
                }
                updateData.bookConditionRating = bookConditionRating;
            }
        }

        const updated = await prisma.transaction.update({
            where: { id },
            data: updateData,
            include: {
                book: true,
                borrower: { select: { id: true, name: true, profileImageUrl: true } },
                owner: { select: { id: true, name: true, profileImageUrl: true } },
            },
        });

        return this.mapTransaction(updated);
    }

    /**
     * Cancel a pending borrow request (borrower only).
     */
    async cancelTransaction(id: string, userId: string) {
        const transaction = await prisma.transaction.findUnique({
            where: { id },
            include: {
                book: true,
                borrower: { select: { id: true, name: true, profileImageUrl: true } },
                owner: { select: { id: true, name: true, profileImageUrl: true } },
            },
        });

        if (!transaction) throw new Error('Transaction not found');
        if (transaction.borrowerId !== userId) {
            throw new Error('Unauthorized: only the borrower can cancel a request');
        }
        if (!['PENDING', 'APPROVED'].includes(transaction.status)) {
            throw new Error('Only PENDING or APPROVED transactions can be cancelled');
        }

        const updated = await prisma.transaction.update({
            where: { id },
            data: { status: 'CANCELLED' },
            include: {
                book: true,
                borrower: { select: { id: true, name: true, profileImageUrl: true } },
                owner: { select: { id: true, name: true, profileImageUrl: true } },
            },
        });

        // If APPROVED, also re-mark the book as available
        if (transaction.status === 'APPROVED') {
            await prisma.book.update({
                where: { id: transaction.bookId },
                data: { isAvailable: true, currentTransactionId: null },
            });
        }

        return this.mapTransaction(updated);
    }
}
