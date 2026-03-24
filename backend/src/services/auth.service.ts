import prisma from '../config/database';
import { generateTokenPair, verifyRefreshToken, generateAccessToken } from '../utils/jwt';
import { generateOTP, storeOTP, sendOTPViaWhatsApp, checkOTP, consumeOTP } from './otp.service';
import { formatUserResponse } from '../utils/user.utils';
import { OAuth2Client } from 'google-auth-library';

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

/**
 * Send OTP to phone number
 */
export async function sendOTPService(phoneNumber: string) {
    const otp = generateOTP(phoneNumber);

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
    // 1. Verify JWT signature and expiry first
    let payload: any;
    try {
        payload = verifyRefreshToken(refreshToken);
    } catch (error) {
        throw new Error('Invalid or expired refresh token');
    }

    try {
        return await prisma.$transaction(async (tx) => {
            // 2. Find the token record within the transaction
            const tokenRecord = await tx.refreshToken.findUnique({
                where: { token: refreshToken },
                include: { user: true },
            });

            // Helper to find a recently issued token for this user (grace period)
            const findRecentToken = async () => {
                return await tx.refreshToken.findFirst({
                    where: { 
                        userId: payload.userId,
                        createdAt: { gte: new Date(Date.now() - 15000) } // Increased to 15s grace
                    },
                    orderBy: { createdAt: 'desc' }
                });
            };

            if (!tokenRecord) {
                // If not found in DB, it might have been rotated by a concurrent request 
                // in the last few seconds.
                const recentToken = await findRecentToken();

                if (recentToken) {
                    console.log('♻️ Re-using recently rotated token for concurrent request');
                    return { 
                        accessToken: generateAccessToken({ userId: payload.userId, phoneNumber: payload.phoneNumber }),
                        refreshToken: recentToken.token 
                    };
                }
                
                throw new Error('Invalid refresh token');
            }

            // 3. Check database-level expiry
            if (tokenRecord.expiresAt < new Date()) {
                await tx.refreshToken.delete({ where: { id: tokenRecord.id } }).catch(() => {});
                throw new Error('Refresh token expired');
            }

            // 4. Generate new tokens
            const { accessToken, refreshToken: newRefreshToken } = generateTokenPair({
                userId: tokenRecord.user.id,
                phoneNumber: tokenRecord.user.phoneNumber,
            });

            const expiresAt = new Date();
            expiresAt.setDate(expiresAt.getDate() + 7);

            // 5. Rotate: Delete old, create new
            try {
                await tx.refreshToken.delete({ where: { id: tokenRecord.id } });
                await tx.refreshToken.create({
                    data: { 
                        userId: tokenRecord.user.id, 
                        token: newRefreshToken, 
                        expiresAt 
                    },
                });
                return { accessToken, refreshToken: newRefreshToken };
            } catch (err: any) {
                // If deletion fails (P2025), someone else rotated it already after our findUnique
                if (err.code === 'P2025' || err.code === 'P2002') {
                    console.warn(`⚠️ Race condition during rotation (${err.code}) — recovering`);
                    const latest = await findRecentToken();
                    if (latest) {
                        return {
                            accessToken: generateAccessToken({ userId: payload.userId, phoneNumber: payload.phoneNumber }),
                            refreshToken: latest.token
                        };
                    }
                }
                throw err;
            }
        });
    } catch (error: any) {
        console.error('Refresh token service error:', error.message);
        throw error;
    }
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
    const audience = process.env.GOOGLE_CLIENT_ID?.split(',').map(id => id.trim()) || [];

    // Verify the ID token with Google
    const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: audience,
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
