// Mock the Prisma client
jest.mock('../../src/config/database', () => require('../__mocks__/prisma').default);

import prismaMock from '../__mocks__/prisma';
import {
    getBooksFeed,
    getBookById,
    createBook,
    deleteBook,
    getAvailableGenres,
} from '../../src/services/book.service';

const mockBook = {
    id: 'book-1',
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    genre: 'Fiction',
    description: 'A classic novel',
    personalNotes: null,
    imageUrl: null,
    isbn: null,
    publisher: null,
    year: 1925,
    pages: 180,
    language: 'English',
    condition: 'GOOD',
    lendingPricePerWeek: 50,
    isAvailable: true,
    ownerId: 'user-1',
    currentTransactionId: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    bookGroups: [{ groupId: 'group-1', group: { id: 'group-1', name: 'Fiction Lovers' } }],
    owner: { id: 'user-1', name: 'Alice', averageRating: 4.5, booksShared: 5, profileImageUrl: null },
};

describe('getBooksFeed', () => {
    beforeEach(() => {
        (prismaMock.book.findMany as jest.Mock).mockResolvedValue([mockBook]);
        (prismaMock.book.count as jest.Mock).mockResolvedValue(1);
    });

    it('returns paginated books with correct pagination metadata', async () => {
        const result = await getBooksFeed({ page: 1, limit: 10 });

        expect(result.books).toHaveLength(1);
        expect(result.pagination.page).toBe(1);
        expect(result.pagination.total).toBe(1);
        expect(result.pagination.totalPages).toBe(1);
    });

    it('applies availability filter when availability is AVAILABLE', async () => {
        await getBooksFeed({ availability: 'AVAILABLE' });

        const findManyCall = (prismaMock.book.findMany as jest.Mock).mock.calls[0][0];
        expect(findManyCall.where.isAvailable).toBe(true);
    });

    it('applies genre filter when genres are provided', async () => {
        await getBooksFeed({ genres: ['Fiction', 'Mystery'] });

        const findManyCall = (prismaMock.book.findMany as jest.Mock).mock.calls[0][0];
        expect(findManyCall.where.genre).toEqual({ in: ['Fiction', 'Mystery'] });
    });

    it('applies search filter to title, author, and description', async () => {
        await getBooksFeed({ search: 'gatsby' });

        const findManyCall = (prismaMock.book.findMany as jest.Mock).mock.calls[0][0];
        expect(findManyCall.where.OR).toHaveLength(3);
    });

    it('applies groupIds filter when groupIds are provided', async () => {
        await getBooksFeed({ groupIds: ['group-1'] });

        const findManyCall = (prismaMock.book.findMany as jest.Mock).mock.calls[0][0];
        expect(findManyCall.where.bookGroups.some.groupId).toEqual({ in: ['group-1'] });
    });

    it('sorts by price ascending when sortBy is PRICE_LOW', async () => {
        await getBooksFeed({ sortBy: 'PRICE_LOW' });

        const findManyCall = (prismaMock.book.findMany as jest.Mock).mock.calls[0][0];
        expect(findManyCall.orderBy).toEqual({ lendingPricePerWeek: 'asc' });
    });
});

describe('getBookById', () => {
    it('returns the book when found', async () => {
        (prismaMock.book.findUnique as jest.Mock).mockResolvedValue(mockBook);

        const result = await getBookById('book-1');
        expect(result).not.toBeNull();
        expect(result?.title).toBe('The Great Gatsby');
    });

    it('returns null when book is not found', async () => {
        (prismaMock.book.findUnique as jest.Mock).mockResolvedValue(null);

        const result = await getBookById('nonexistent-id');
        expect(result).toBeNull();
    });
});

describe('createBook', () => {
    it('creates a book and updates group/user counts', async () => {
        (prismaMock.book.create as jest.Mock).mockResolvedValue(mockBook);
        (prismaMock.group.update as jest.Mock).mockResolvedValue({});
        (prismaMock.user.update as jest.Mock).mockResolvedValue({});

        const result = await createBook({
            title: 'The Great Gatsby',
            author: 'F. Scott Fitzgerald',
            genre: 'Fiction',
            description: 'A classic novel',
            condition: 'GOOD' as any,
            lendingPricePerWeek: 50,
            ownerId: 'user-1',
            visibleInGroups: ['group-1'],
        });

        expect(prismaMock.book.create).toHaveBeenCalled();
        expect(prismaMock.group.update).toHaveBeenCalledWith(
            expect.objectContaining({ where: { id: 'group-1' } })
        );
        expect(prismaMock.user.update).toHaveBeenCalledWith(
            expect.objectContaining({ where: { id: 'user-1' } })
        );
        expect(result.title).toBe('The Great Gatsby');
    });
});

describe('deleteBook', () => {
    it('throws "Book not found" when the book does not exist', async () => {
        (prismaMock.book.findUnique as jest.Mock).mockResolvedValue(null);

        await expect(deleteBook('bad-id', 'user-1')).rejects.toThrow('Book not found');
    });

    it('throws unauthorized error when the requester is not the owner', async () => {
        (prismaMock.book.findUnique as jest.Mock).mockResolvedValue({
            ...mockBook,
            ownerId: 'another-user',
        });

        await expect(deleteBook('book-1', 'user-1')).rejects.toThrow('Unauthorized');
    });

    it('deletes the book and decrements group/user counts', async () => {
        (prismaMock.book.findUnique as jest.Mock).mockResolvedValue(mockBook);
        (prismaMock.book.delete as jest.Mock).mockResolvedValue({});
        (prismaMock.group.update as jest.Mock).mockResolvedValue({});
        (prismaMock.user.update as jest.Mock).mockResolvedValue({});

        await deleteBook('book-1', 'user-1');

        expect(prismaMock.book.delete).toHaveBeenCalledWith({ where: { id: 'book-1' } });
        expect(prismaMock.group.update).toHaveBeenCalled();
        expect(prismaMock.user.update).toHaveBeenCalledWith(
            expect.objectContaining({
                data: { booksShared: { decrement: 1 } },
            })
        );
    });
});

describe('getAvailableGenres', () => {
    it('returns a sorted list of unique genres', async () => {
        (prismaMock.book.findMany as jest.Mock).mockResolvedValue([
            { genre: 'Mystery' },
            { genre: 'Fiction' },
            { genre: 'Adventure' },
        ]);

        const result = await getAvailableGenres();
        expect(result).toEqual(['Adventure', 'Fiction', 'Mystery']);
    });
});
