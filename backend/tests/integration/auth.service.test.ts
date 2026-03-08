// Mock the Prisma client used by auth.service.ts
jest.mock('../../src/config/database', () => require('../__mocks__/prisma').default);

// Mock the JWT utils
jest.mock('../../src/utils/jwt', () => ({
    generateTokenPair: () => ({
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
    }),
    verifyRefreshToken: () => ({ userId: 'user-1' }),
}));

// Mock the OTP service to avoid real Twilio calls
jest.mock('../../src/services/otp.service', () => ({
    generateOTP: jest.fn().mockReturnValue('123456'),
    storeOTP: jest.fn().mockResolvedValue(undefined),
    sendOTPViaWhatsApp: jest.fn().mockResolvedValue(undefined),
    checkOTP: jest.fn(),
    consumeOTP: jest.fn().mockResolvedValue(undefined),
}));

import prismaMock from '../__mocks__/prisma';
import * as otpService from '../../src/services/otp.service';
import {
    verifyOTPService,
    refreshTokenService,
    logoutService,
} from '../../src/services/auth.service';

const mockCheckOTP = otpService.checkOTP as jest.Mock;

const baseUser = {
    id: 'user-1',
    phoneNumber: '+911234567890',
    name: 'Alice',
    phoneVerified: true,
    email: null,
    bio: null,
    profileImageUrl: null,
    booksShared: 0,
    successfulLends: 0,
    booksBorrowed: 0,
    totalEarned: 0,
    averageRating: 0,
    phoneVisibility: 'AFTER_APPROVAL',
    pushEnabled: true,
    emailEnabled: false,
    borrowRequestsNotif: true,
    dueDateRemindersNotif: true,
    groupActivityNotif: false,
    deviceToken: null,
    lastTokenUpdate: null,
    isActive: true,
    createdAt: new Date(),
    lastLoginAt: null,
    joinedGroupIds: [],
    createdGroupIds: [],
};

describe('verifyOTPService', () => {
    it('throws "Invalid or expired OTP" when checkOTP returns null', async () => {
        mockCheckOTP.mockResolvedValue(null);

        await expect(
            verifyOTPService('+911234567890', 'wrong')
        ).rejects.toThrow('Invalid or expired OTP');
    });

    it('throws "Name is required for new users" when user does not exist and no name is supplied', async () => {
        mockCheckOTP.mockResolvedValue('otp-id-1');
        (prismaMock.user.findUnique as jest.Mock).mockResolvedValue(null);

        await expect(
            verifyOTPService('+911234567890', '123456')
        ).rejects.toThrow('Name is required for new users');
    });

    it('creates a new user and returns tokens when OTP is valid and name is provided', async () => {
        mockCheckOTP.mockResolvedValue('otp-id-1');
        (prismaMock.user.findUnique as jest.Mock).mockResolvedValue(null);
        (prismaMock.user.create as jest.Mock).mockResolvedValue(baseUser);
        (prismaMock.refreshToken.create as jest.Mock).mockResolvedValue({});

        const result = await verifyOTPService('+911234567890', '123456', 'Alice');

        expect(prismaMock.user.create).toHaveBeenCalled();
        expect(result).toHaveProperty('accessToken');
        expect(result).toHaveProperty('refreshToken');
        expect(result.user.name).toBe('Alice');
    });

    it('logs in an existing user and returns tokens', async () => {
        mockCheckOTP.mockResolvedValue('otp-id-2');
        (prismaMock.user.findUnique as jest.Mock).mockResolvedValue(baseUser);
        (prismaMock.user.update as jest.Mock).mockResolvedValue(baseUser);
        (prismaMock.refreshToken.create as jest.Mock).mockResolvedValue({});

        const result = await verifyOTPService('+911234567890', '123456');

        expect(prismaMock.user.update).toHaveBeenCalled();
        expect(result).toHaveProperty('accessToken');
        expect(result.user.id).toBe('user-1');
    });
});

describe('refreshTokenService', () => {
    it('throws "Invalid refresh token" when token is not found', async () => {
        (prismaMock.refreshToken.findUnique as jest.Mock).mockResolvedValue(null);

        await expect(refreshTokenService('bad-token')).rejects.toThrow('Invalid refresh token');
    });

    it('throws "Refresh token expired" and deletes the token when it is expired', async () => {
        (prismaMock.refreshToken.findUnique as jest.Mock).mockResolvedValue({
            id: 'rt-1',
            token: 'old-token',
            expiresAt: new Date('2000-01-01'), // expired
            user: baseUser,
        });
        (prismaMock.refreshToken.delete as jest.Mock).mockResolvedValue({});

        await expect(refreshTokenService('old-token')).rejects.toThrow('Refresh token expired');
        expect(prismaMock.refreshToken.deleteMany).toHaveBeenCalledWith({ where: { id: 'rt-1' } });
    });

    it('returns new access and refresh tokens on success', async () => {
        const futureDate = new Date();
        futureDate.setDate(futureDate.getDate() + 7);

        (prismaMock.refreshToken.findUnique as jest.Mock).mockResolvedValue({
            id: 'rt-2',
            token: 'valid-token',
            expiresAt: futureDate,
            user: baseUser,
        });
        (prismaMock.refreshToken.deleteMany as jest.Mock).mockResolvedValue({ count: 1 });
        (prismaMock.refreshToken.create as jest.Mock).mockResolvedValue({});

        const result = await refreshTokenService('valid-token');

        expect(result).toHaveProperty('accessToken');
        expect(result).toHaveProperty('refreshToken');
    });
});

describe('logoutService', () => {
    it('deletes only the specified refresh token when token is provided', async () => {
        (prismaMock.refreshToken.deleteMany as jest.Mock).mockResolvedValue({ count: 1 });

        await logoutService('user-1', 'specific-token');

        expect(prismaMock.refreshToken.deleteMany).toHaveBeenCalledWith({
            where: { userId: 'user-1', token: 'specific-token' },
        });
    });

    it('deletes all refresh tokens for the user when no token is provided', async () => {
        (prismaMock.refreshToken.deleteMany as jest.Mock).mockResolvedValue({ count: 3 });

        await logoutService('user-1');

        expect(prismaMock.refreshToken.deleteMany).toHaveBeenCalledWith({
            where: { userId: 'user-1' },
        });
    });
});
