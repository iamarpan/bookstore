import {
    generateAccessToken,
    generateRefreshToken,
    verifyAccessToken,
    verifyRefreshToken,
    generateTokenPair,
    TokenPayload,
} from '../../src/utils/jwt';

describe('JWT Utilities', () => {
    const payload: TokenPayload = {
        userId: 'user-123',
        phoneNumber: '+911234567890',
    };

    describe('generateAccessToken', () => {
        it('should generate a non-empty string token', () => {
            const token = generateAccessToken(payload);
            expect(typeof token).toBe('string');
            expect(token.length).toBeGreaterThan(0);
        });

        it('should generate different tokens for different payloads', () => {
            const token1 = generateAccessToken(payload);
            const token2 = generateAccessToken({ userId: 'user-456', phoneNumber: '+910000000000' });
            expect(token1).not.toBe(token2);
        });
    });

    describe('generateRefreshToken', () => {
        it('should generate a non-empty string token', () => {
            const token = generateRefreshToken(payload);
            expect(typeof token).toBe('string');
            expect(token.length).toBeGreaterThan(0);
        });

        it('should generate a different token from access token', () => {
            const access = generateAccessToken(payload);
            const refresh = generateRefreshToken(payload);
            expect(access).not.toBe(refresh);
        });
    });

    describe('verifyAccessToken', () => {
        it('should return the original payload when given a valid access token', () => {
            const token = generateAccessToken(payload);
            const decoded = verifyAccessToken(token);
            expect(decoded.userId).toBe(payload.userId);
            expect(decoded.phoneNumber).toBe(payload.phoneNumber);
        });

        it('should throw an error for an invalid token', () => {
            expect(() => verifyAccessToken('invalid.token.here')).toThrow('Invalid or expired access token');
        });

        it('should throw an error when a refresh token is used as an access token', () => {
            // Refresh tokens are signed with a different secret
            const refreshToken = generateRefreshToken(payload);
            expect(() => verifyAccessToken(refreshToken)).toThrow('Invalid or expired access token');
        });
    });

    describe('verifyRefreshToken', () => {
        it('should return the original payload when given a valid refresh token', () => {
            const token = generateRefreshToken(payload);
            const decoded = verifyRefreshToken(token);
            expect(decoded.userId).toBe(payload.userId);
            expect(decoded.phoneNumber).toBe(payload.phoneNumber);
        });

        it('should throw an error for an invalid token', () => {
            expect(() => verifyRefreshToken('bad.token')).toThrow('Invalid or expired refresh token');
        });

        it('should throw when an access token is used as a refresh token', () => {
            const accessToken = generateAccessToken(payload);
            expect(() => verifyRefreshToken(accessToken)).toThrow('Invalid or expired refresh token');
        });
    });

    describe('generateTokenPair', () => {
        it('should return both accessToken and refreshToken', () => {
            const { accessToken, refreshToken } = generateTokenPair(payload);
            expect(typeof accessToken).toBe('string');
            expect(typeof refreshToken).toBe('string');
        });

        it('should return tokens that decode to the correct payload', () => {
            const { accessToken, refreshToken } = generateTokenPair(payload);
            const decodedAccess = verifyAccessToken(accessToken);
            const decodedRefresh = verifyRefreshToken(refreshToken);
            expect(decodedAccess.userId).toBe(payload.userId);
            expect(decodedRefresh.userId).toBe(payload.userId);
        });
    });
});
