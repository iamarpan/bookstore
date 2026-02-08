import prisma from '../config/database';
import { generateTokenPair } from '../utils/jwt';
import { generateOTP, storeOTP, sendOTPViaSMS, checkOTP, consumeOTP } from './otp.service';
import { formatUserResponse } from '../utils/user.utils';

/**
 * Send OTP to phone number
 */
export async function sendOTPService(phoneNumber: string) {
    const otp = generateOTP();

    // Store OTP in database
    await storeOTP(phoneNumber, otp);

    // Send OTP via SMS
    await sendOTPViaSMS(phoneNumber, otp);

    const expiryMinutes = parseInt(process.env.OTP_EXPIRY_MINUTES || '5');

    return {
        message: 'OTP sent successfully',
        expiresIn: expiryMinutes * 60, // in seconds
    };
}

/**
 * Verify OTP and login/register user
 */
export async function verifyOTPService(
    phoneNumber: string,
    otp: string,
    name?: string,
    bio?: string
) {
    // Check if OTP is valid
    const otpId = await checkOTP(phoneNumber, otp);

    if (!otpId) {
        throw new Error('Invalid or expired OTP');
    }

    // Check if user exists
    let user = await prisma.user.findUnique({
        where: { phoneNumber },
    });

    // If user doesn't exist, create new user (registration)
    if (!user) {
        if (!name) {
            // DO NOT consume the OTP yet, allow them to come back with a name
            throw new Error('Name is required for new users');
        }

        // OTP is valid and name provided, proceed with registration
        await consumeOTP(otpId);

        user = await prisma.user.create({
            data: {
                phoneNumber,
                phoneVerified: true,
                name,
                bio: bio || null,
                lastLoginAt: new Date(),
            },
        });

        console.log(`✅ New user registered: ${user.name} (${user.phoneNumber})`);
    } else {
        // User exists, they are logging in
        // Consume OTP and proceed
        await consumeOTP(otpId);

        // Update existing user
        user = await prisma.user.update({
            where: { id: user.id },
            data: {
                phoneVerified: true,
                lastLoginAt: new Date(),
                // Update name/bio if provided
                ...(name && { name }),
                ...(bio && { bio }),
            },
        });

        console.log(`✅ User logged in: ${user.name} (${user.phoneNumber})`);
    }

    // Generate tokens
    const { accessToken, refreshToken } = generateTokenPair({
        userId: user.id,
        phoneNumber: user.phoneNumber,
    });

    // Store refresh token in database
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

    await prisma.refreshToken.create({
        data: {
            userId: user.id,
            token: refreshToken,
            expiresAt,
        },
    });

    return {
        accessToken,
        refreshToken,
        user: formatUserResponse(user),
    };
}

/**
 * Refresh access token using refresh token
 */
export async function refreshTokenService(refreshToken: string) {
    // Find refresh token in database
    const tokenRecord = await prisma.refreshToken.findUnique({
        where: { token: refreshToken },
        include: { user: true },
    });

    if (!tokenRecord) {
        throw new Error('Invalid refresh token');
    }

    // Check if token is expired
    if (tokenRecord.expiresAt < new Date()) {
        // Delete expired token
        await prisma.refreshToken.delete({
            where: { id: tokenRecord.id },
        });
        throw new Error('Refresh token expired');
    }

    // Generate new tokens
    const { accessToken, refreshToken: newRefreshToken } = generateTokenPair({
        userId: tokenRecord.user.id,
        phoneNumber: tokenRecord.user.phoneNumber,
    });

    // Delete old refresh token and create new one
    await prisma.refreshToken.delete({
        where: { id: tokenRecord.id },
    });

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await prisma.refreshToken.create({
        data: {
            userId: tokenRecord.user.id,
            token: newRefreshToken,
            expiresAt,
        },
    });

    return {
        accessToken,
        refreshToken: newRefreshToken,
    };
}

/**
 * Logout user (invalidate refresh token)
 */
export async function logoutService(userId: string, refreshToken?: string) {
    if (refreshToken) {
        // Delete specific refresh token
        await prisma.refreshToken.deleteMany({
            where: {
                userId,
                token: refreshToken,
            },
        });
    } else {
        // Delete all refresh tokens for user
        await prisma.refreshToken.deleteMany({
            where: { userId },
        });
    }
}
