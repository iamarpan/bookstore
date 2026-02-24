// Mock Prisma - TransactionService uses its own PrismaClient instance
jest.mock('@prisma/client', () => {
    const mockTransaction = {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
    };
    const mockBook = {
        findUnique: jest.fn(),
        update: jest.fn(),
    };

    const PrismaClient = jest.fn().mockImplementation(() => ({
        transaction: mockTransaction,
        book: mockBook,
    }));

    // Expose mocks for test access
    (PrismaClient as any).__mocks = { transaction: mockTransaction, book: mockBook };

    return { PrismaClient, TransactionStatus: {} };
});

import { PrismaClient } from '@prisma/client';
import { TransactionService } from '../../src/services/transaction.service';

// Access the shared mock instances
const prismaInstance = new PrismaClient();
const transactionMock = (prismaInstance as any).transaction;
const bookMock = (prismaInstance as any).book;

const service = new TransactionService();

const mockBook = {
    id: 'book-1',
    title: 'Great Gatsby',
    imageUrl: null,
    ownerId: 'owner-1',
    isAvailable: true,
    lendingPricePerWeek: 50,
    bookGroups: [{ groupId: 'group-1' }],
};

const mockTransaction = {
    id: 'txn-1',
    bookId: 'book-1',
    borrowerId: 'user-2',
    ownerId: 'owner-1',
    groupId: 'group-1',
    status: 'PENDING',
    duration: 'ONE_WEEK',
    durationDays: 7,
    lendingFee: 50,
    requestMessage: null,
    rejectionReason: null,
    handoverOTP: null,
    handoverOTPExpiry: null,
    returnOTP: null,
    returnOTPExpiry: null,
    borrowerPaymentConfirmed: false,
    ownerPaymentConfirmed: false,
    requestedAt: new Date(),
    approvedAt: null,
    handoverAt: null,
    dueDate: null,
    returnedAt: null,
    ownerRating: null,
    ownerComment: null,
    borrowerRating: null,
    borrowerComment: null,
    bookConditionRating: null,
    book: {
        id: 'book-1',
        title: 'Great Gatsby',
        imageUrl: null,
        ownerId: 'owner-1',
    },
    borrower: { id: 'user-2', name: 'Bob', profileImageUrl: null },
    owner: { id: 'owner-1', name: 'Alice', profileImageUrl: null },
};

describe('TransactionService.createRequest', () => {
    it('throws "Book not found" when the book does not exist', async () => {
        bookMock.findUnique.mockResolvedValue(null);

        await expect(
            service.createRequest({ bookId: 'bad-id', borrowerId: 'user-2', duration: 'ONE_WEEK', durationDays: 7 })
        ).rejects.toThrow('Book not found');
    });

    it('throws "Book is currently not available" when book is unavailable', async () => {
        bookMock.findUnique.mockResolvedValue({ ...mockBook, isAvailable: false });

        await expect(
            service.createRequest({ bookId: 'book-1', borrowerId: 'user-2', duration: 'ONE_WEEK', durationDays: 7 })
        ).rejects.toThrow('Book is currently not available');
    });

    it('throws "You cannot borrow your own book" when borrower is the owner', async () => {
        bookMock.findUnique.mockResolvedValue(mockBook);

        await expect(
            service.createRequest({ bookId: 'book-1', borrowerId: 'owner-1', duration: 'ONE_WEEK', durationDays: 7 })
        ).rejects.toThrow('You cannot borrow your own book');
    });

    it('creates a transaction successfully when all conditions are met', async () => {
        bookMock.findUnique.mockResolvedValue(mockBook);
        transactionMock.create.mockResolvedValue(mockTransaction);

        const result = await service.createRequest({
            bookId: 'book-1',
            borrowerId: 'user-2',
            duration: 'ONE_WEEK',
            durationDays: 7,
            message: 'Please lend me this book!',
        });

        expect(transactionMock.create).toHaveBeenCalled();
        expect(result.status).toBe('PENDING');
    });
});

describe('TransactionService.updateStatus', () => {
    it('throws "Transaction not found" when the transaction does not exist', async () => {
        transactionMock.findUnique.mockResolvedValue(null);

        await expect(
            service.updateStatus('bad-id', 'user-1', 'APPROVED' as any)
        ).rejects.toThrow('Transaction not found');
    });

    it('throws "Unauthorized" when a non-owner tries to APPROVE', async () => {
        transactionMock.findUnique.mockResolvedValue({ ...mockTransaction, ownerId: 'owner-1' });

        await expect(
            service.updateStatus('txn-1', 'other-user', 'APPROVED' as any)
        ).rejects.toThrow('Unauthorized');
    });

    it('sets approvedAt when status is APPROVED', async () => {
        transactionMock.findUnique.mockResolvedValue(mockTransaction);
        transactionMock.update.mockResolvedValue({ ...mockTransaction, status: 'APPROVED' });

        const result = await service.updateStatus('txn-1', 'owner-1', 'APPROVED' as any);

        const updateCall = transactionMock.update.mock.calls[0][0];
        expect(updateCall.data.approvedAt).toBeInstanceOf(Date);
        expect(result.status).toBe('APPROVED');
    });

    it('marks book as unavailable when status is ACTIVE', async () => {
        transactionMock.findUnique.mockResolvedValue({ ...mockTransaction, durationDays: 7 });
        transactionMock.update.mockResolvedValue({ ...mockTransaction, status: 'ACTIVE' });
        bookMock.update.mockResolvedValue({});

        await service.updateStatus('txn-1', 'user-2', 'ACTIVE' as any);

        expect(bookMock.update).toHaveBeenCalledWith(
            expect.objectContaining({
                data: expect.objectContaining({ isAvailable: false }),
            })
        );
    });

    it('marks book as available again when status is RETURNED', async () => {
        transactionMock.findUnique.mockResolvedValue({ ...mockTransaction });
        transactionMock.update.mockResolvedValue({ ...mockTransaction, status: 'RETURNED' });
        bookMock.update.mockResolvedValue({});

        await service.updateStatus('txn-1', 'user-2', 'RETURNED' as any);

        expect(bookMock.update).toHaveBeenCalledWith(
            expect.objectContaining({
                data: expect.objectContaining({ isAvailable: true }),
            })
        );
    });
});

describe('TransactionService.getMyTransactions', () => {
    it('returns paginated transactions for a borrower', async () => {
        transactionMock.findMany.mockResolvedValue([mockTransaction]);
        transactionMock.count.mockResolvedValue(1);

        const result = await service.getMyTransactions('user-2', { role: 'BORROWER' });

        expect(result.transactions).toHaveLength(1);
        expect(result.pagination.total).toBe(1);
    });

    it('filters by status when status is provided', async () => {
        transactionMock.findMany.mockResolvedValue([]);
        transactionMock.count.mockResolvedValue(0);

        await service.getMyTransactions('user-2', { status: 'PENDING' as any });

        const call = transactionMock.findMany.mock.calls[0][0];
        expect(call.where.status).toBe('PENDING');
    });
});
