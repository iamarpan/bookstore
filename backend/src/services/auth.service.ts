import prisma from '../config/database';
import { generateTokenPair, verifyRefreshToken } from '../utils/jwt';
import { generateOTP, storeOTP, sendOTPViaWhatsApp, checkOTP, consumeOTP } from './otp.service';
import { formatUserResponse } from '../utils/user.utils';
import { OAuth2Client } from 'google-auth-library';

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

/**
 * Send OTP to phone number
 */
export async function sendOTPService(phoneNumber: string) {
    const otp = generateOTP();

    // Store OTP in database
    await storeOTP(phoneNumber, otp);

    // Send OTP via WhatsApp
    await sendOTPViaWhatsApp(phoneNumber, otp);

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
    // Verify JWT signature first
    try {
        verifyRefreshToken(refreshToken);
    } catch {
        throw new Error('Invalid refresh token');
    }

    const tokenRecord = await prisma.refreshToken.findUnique({
        where: { token: refreshToken },
        include: { user: true },
    });

    if (!tokenRecord) {
        throw new Error('Invalid refresh token');
    }

    if (tokenRecord.expiresAt < new Date()) {
        await prisma.refreshToken.deleteMany({ where: { id: tokenRecord.id } });
        throw new Error('Refresh token expired');
    }

    const { accessToken, refreshToken: newRefreshToken } = generateTokenPair({
        userId: tokenRecord.user.id,
        phoneNumber: tokenRecord.user.phoneNumber,
    });

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    // Atomically delete old token and create new one.
    // If a concurrent request already rotated this token (P2002), we still
    // return the new tokens — both map to the same user and the iOS client
    // will store whichever it receives last.
    try {
        await prisma.$transaction(async (tx) => {
            await tx.refreshToken.deleteMany({ where: { id: tokenRecord.id } });
            await tx.refreshToken.create({
                data: { userId: tokenRecord.user.id, token: newRefreshToken, expiresAt },
            });
        });
    } catch (err: any) {
        if (err?.code !== 'P2002') throw err;
        console.warn('⚠️ Concurrent refresh token rotation — returning tokens anyway');
    }

    return { accessToken, refreshToken: newRefreshToken };
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

/**
 * Verify Google ID token and login/register user
 */
export async function verifyGoogleTokenService(idToken: string) {
    // Verify the ID token with Google
    const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    if (!payload) {
        throw new Error('Invalid Google token');
    }

    const { sub: googleId, email, name, picture } = payload;

    if (!googleId || !email) {
        throw new Error('Google token missing required fields');
    }

    // Check if user exists by googleId
    let user = await prisma.user.findUnique({
        where: { googleId },
    });

    if (!user) {
        // Check if user exists by email (could have signed up with phone first)
        user = await prisma.user.findUnique({
            where: { email },
        });

        if (user) {
            // Link Google account to existing user
            user = await prisma.user.update({
                where: { id: user.id },
                data: {
                    googleId,
                    profileImageUrl: user.profileImageUrl || picture,
                    lastLoginAt: new Date(),
                },
            });
            console.log(`✅ Linked Google account to existing user: ${user.name} (${user.email})`);
        } else {
            // Create new user with Google
            // Generate a unique placeholder phone number for Google users
            const placeholderPhone = `google_${googleId}`;

            user = await prisma.user.create({
                data: {
                    phoneNumber: placeholderPhone,
                    phoneVerified: false,
                    name: name || 'Google User',
                    email,
                    googleId,
                    authProvider: 'GOOGLE',
                    profileImageUrl: picture,
                    lastLoginAt: new Date(),
                },
            });
            console.log(`✅ New user registered via Google: ${user.name} (${user.email})`);
        }
    } else {
        // User exists with Google, update last login
        user = await prisma.user.update({
            where: { id: user.id },
            data: {
                lastLoginAt: new Date(),
                // Update profile image if changed
                ...(picture && !user.profileImageUrl && { profileImageUrl: picture }),
            },
        });
        console.log(`✅ User logged in via Google: ${user.name} (${user.email})`);
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
