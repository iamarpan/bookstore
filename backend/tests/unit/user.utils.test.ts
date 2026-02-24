import { formatUserResponse } from '../../src/utils/user.utils';

const makeUser = (overrides = {}) => ({
    id: 'user-1',
    phoneNumber: '+911234567890',
    phoneVerified: true,
    name: 'Alice',
    email: 'alice@example.com',
    bio: 'Loves books',
    profileImageUrl: 'https://example.com/pic.jpg',
    booksShared: 5,
    successfulLends: 3,
    booksBorrowed: 2,
    totalEarned: 150.0,
    averageRating: 4.5,
    phoneVisibility: 'AFTER_APPROVAL',
    pushEnabled: true,
    emailEnabled: false,
    borrowRequestsNotif: true,
    dueDateRemindersNotif: true,
    groupActivityNotif: false,
    deviceToken: 'tok-abc',
    lastTokenUpdate: new Date('2024-01-01'),
    isActive: true,
    createdAt: new Date('2023-01-01'),
    lastLoginAt: new Date('2024-06-01'),
    joinedGroupIds: ['g1'],
    createdGroupIds: ['g2'],
    ...overrides,
});

describe('formatUserResponse', () => {
    it('maps all fields correctly from a Prisma User object', () => {
        const user = makeUser();
        const result = formatUserResponse(user as any);

        expect(result.id).toBe('user-1');
        expect(result.phoneNumber).toBe('+911234567890');
        expect(result.phoneVerified).toBe(true);
        expect(result.name).toBe('Alice');
        expect(result.email).toBe('alice@example.com');
        expect(result.bio).toBe('Loves books');
        expect(result.profileImageUrl).toBe('https://example.com/pic.jpg');
    });

    it('maps stats correctly', () => {
        const user = makeUser();
        const result = formatUserResponse(user as any);

        expect(result.stats.booksShared).toBe(5);
        expect(result.stats.successfulLends).toBe(3);
        expect(result.stats.booksBorrowed).toBe(2);
        expect(result.stats.totalEarned).toBe(150.0);
        expect(result.stats.averageRating).toBe(4.5);
    });

    it('maps privacy settings correctly', () => {
        const user = makeUser();
        const result = formatUserResponse(user as any);

        expect(result.privacySettings.phoneVisibility).toBe('AFTER_APPROVAL');
    });

    it('maps notification preferences correctly', () => {
        const user = makeUser();
        const result = formatUserResponse(user as any);

        expect(result.notificationPreferences.pushEnabled).toBe(true);
        expect(result.notificationPreferences.emailEnabled).toBe(false);
        expect(result.notificationPreferences.borrowRequests).toBe(true);
        expect(result.notificationPreferences.dueDateReminders).toBe(true);
        expect(result.notificationPreferences.groupActivity).toBe(false);
    });

    it('defaults joinedGroupIds and createdGroupIds to empty arrays if not provided', () => {
        const user = makeUser({ joinedGroupIds: undefined, createdGroupIds: undefined });
        const result = formatUserResponse(user as any);

        expect(result.joinedGroupIds).toEqual([]);
        expect(result.createdGroupIds).toEqual([]);
    });

    it('converts Decimal-like totalEarned and averageRating to numbers', () => {
        // Prisma Decimal fields come as objects with valueOf(); Number() handles them
        const user = makeUser({ totalEarned: '99.99', averageRating: '3.75' });
        const result = formatUserResponse(user as any);

        expect(result.stats.totalEarned).toBe(99.99);
        expect(result.stats.averageRating).toBe(3.75);
    });

    it('returns null when user is null (handles bad input gracefully)', () => {
        const result = formatUserResponse(null as any);
        expect(result).toBeNull();
    });
});
