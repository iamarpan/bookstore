import jwt from 'jsonwebtoken';

const ACCESS_SECRET: string = process.env.JWT_ACCESS_SECRET || 'default-access-secret-change-me';
const REFRESH_SECRET: string = process.env.JWT_REFRESH_SECRET || 'default-refresh-secret-change-me';
const ACCESS_EXPIRY: any = process.env.JWT_ACCESS_EXPIRY || '15m';
const REFRESH_EXPIRY: any = process.env.JWT_REFRESH_EXPIRY || '7d';

export interface TokenPayload {
    userId: string;
    phoneNumber: string;
}

/**
 * Generate access token
 */
export function generateAccessToken(payload: TokenPayload): string {
    return jwt.sign(payload as any, ACCESS_SECRET as jwt.Secret, { expiresIn: ACCESS_EXPIRY } as any);
}

/**
 * Generate refresh token
 */
export function generateRefreshToken(payload: TokenPayload): string {
    return jwt.sign(payload as any, REFRESH_SECRET as jwt.Secret, { expiresIn: REFRESH_EXPIRY } as any);
}

/**
 * Verify access token
 */
export function verifyAccessToken(token: string): TokenPayload {
    try {
        return jwt.verify(token, ACCESS_SECRET) as TokenPayload;
    } catch (error) {
        throw new Error('Invalid or expired access token');
    }
}

/**
 * Verify refresh token
 */
export function verifyRefreshToken(token: string): TokenPayload {
    try {
        return jwt.verify(token, REFRESH_SECRET) as TokenPayload;
    } catch (error) {
        throw new Error('Invalid or expired refresh token');
    }
}

/**
 * Generate both tokens
 */
export function generateTokenPair(payload: TokenPayload) {
    return {
        accessToken: generateAccessToken(payload),
        refreshToken: generateRefreshToken(payload),
    };
}
