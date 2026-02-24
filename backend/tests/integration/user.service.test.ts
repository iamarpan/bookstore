// Mock the Prisma client
jest.mock('../../src/config/database', () => require('../__mocks__/prisma').default);

import prismaMock from '../__mocks__/prisma';
import {
    getUserById,
    updateUserProfile,
    getUserBooks,
    getUserStats,
    getUserGroups,
} from '../../src/services/user.service';

const baseUser = {
    id: 'user-1',
    phoneNumber: '+911234567890',
    phoneVerified: true,
    name: 'Alice',
    email: null,
    bio: 'Loves books',
    profileImageUrl: null,
    booksShared: 3,
    successfulLends: 2,
    booksBorrowed: 1,
    totalEarned: 100,
    averageRating: 4.2,
    phoneVisibility: 'AFTER_APPROVAL',
    pushEnabled: true,
    emailEnabled: false,
    borrowRequestsNotif: true,
    dueDateRemindersNotif: true,
    groupActivityNotif: false,
    deviceToken: null,
    lastTokenUpdate: null,
    isActive: true,
    createdAt: new Date('2023-01-01'),
    lastLoginAt: new Date('2024-06-01'),
    joinedGroupIds: [],
    createdGroupIds: [],
};

describe('getUserById', () => {
    it('returns null when the user is not found', async () => {
        (prismaMock.user.findUnique as jest.Mock).mockResolvedValue(null);

        const result = await getUserById('nonexistent-id');
        expect(result).toBeNull();
    });

    it('returns a formatted user when found', async () => {
        (prismaMock.user.findUnique as jest.Mock).mockResolvedValue(baseUser);

        const result = await getUserById('user-1');

        expect(result).not.toBeNull();
        expect(result?.id).toBe('user-1');
        expect(result?.name).toBe('Alice');
        expect(result?.stats.booksShared).toBe(3);
    });
});

describe('updateUserProfile', () => {
    it('updates and returns the formatted user', async () => {
        const updatedUser = { ...baseUser, name: 'Alice Updated', bio: 'New bio' };
        (prismaMock.user.update as jest.Mock).mockResolvedValue(updatedUser);

        const result = await updateUserProfile('user-1', { name: 'Alice Updated', bio: 'New bio' });

        expect(prismaMock.user.update).toHaveBeenCalledWith(
            expect.objectContaining({ where: { id: 'user-1' } })
        );
        expect(result.name).toBe('Alice Updated');
        expect(result.bio).toBe('New bio');
    });
});

describe('getUserBooks', () => {
    it('returns an array of books owned by the user', async () => {
        const mockBooks = [
            { id: 'book-1', title: 'Great Gatsby', ownerId: 'user-1', bookGroups: [] },
            { id: 'book-2', title: 'Dune', ownerId: 'user-1', bookGroups: [] },
        ];
        (prismaMock.book.findMany as jest.Mock).mockResolvedValue(mockBooks);

        const result = await getUserBooks('user-1');

        expect(result).toHaveLength(2);
        expect(prismaMock.book.findMany).toHaveBeenCalledWith(
            expect.objectContaining({ where: { ownerId: 'user-1' } })
        );
    });

    it('returns an empty array when user has no books', async () => {
        (prismaMock.book.findMany as jest.Mock).mockResolvedValue([]);

        const result = await getUserBooks('user-1');
        expect(result).toEqual([]);
    });
});

describe('getUserStats', () => {
    it('returns user statistics', async () => {
        const stats = {
            booksShared: 3,
            successfulLends: 2,
            booksBorrowed: 1,
            totalEarned: 100,
            averageRating: 4.2,
        };
        (prismaMock.user.findUnique as jest.Mock).mockResolvedValue(stats);

        const result = await getUserStats('user-1');

        expect(result?.booksShared).toBe(3);
        expect(result?.averageRating).toBe(4.2);
    });

    it('returns null when user is not found', async () => {
        (prismaMock.user.findUnique as jest.Mock).mockResolvedValue(null);

        const result = await getUserStats('bad-id');
        expect(result).toBeNull();
    });
});

describe('getUserGroups (user.service)', () => {
    it('returns groups via group memberships', async () => {
        (prismaMock.groupMember.findMany as jest.Mock).mockResolvedValue([
            { group: { id: 'group-1', name: 'Fiction Lovers' } },
            { group: { id: 'group-2', name: 'Sci-Fi Club' } },
        ]);

        const result = await getUserGroups('user-1');

        expect(result).toHaveLength(2);
        expect(result[0].name).toBe('Fiction Lovers');
    });
});
