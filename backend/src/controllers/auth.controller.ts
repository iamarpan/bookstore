import { Request, Response } from 'express';
import { sendOTPService, verifyOTPService, refreshTokenService, verifyGoogleTokenService } from '../services/auth.service';

/**
 * Send OTP to phone number
 * POST /api/v1/auth/send-otp
 */
export async function sendOTP(req: Request, res: Response) {
    try {
        const { phoneNumber } = req.body;

        if (!phoneNumber) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Phone number is required',
            });
        }

        const result = await sendOTPService(phoneNumber);

        res.json(result);
    } catch (error) {
        console.error('Send OTP error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: error instanceof Error ? error.message : 'Failed to send OTP',
        });
    }
}

/**
 * Verify OTP and login/register
 * POST /api/v1/auth/verify-otp
 */
export async function verifyOTP(req: Request, res: Response) {
    try {
        const { phoneNumber, otp, name, bio } = req.body;

        if (!phoneNumber || !otp) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Phone number and OTP are required',
            });
        }

        const result = await verifyOTPService(phoneNumber, otp, name, bio);

        res.json(result);
    } catch (error) {
        console.error('Verify OTP error:', error);

        if (error instanceof Error && error.message.includes('Name is required')) {
            return res.status(400).json({
                error: 'Bad Request',
                message: error.message,
            });
        }

        res.status(401).json({
            error: 'Unauthorized',
            message: error instanceof Error ? error.message : 'OTP verification failed',
        });
    }
}

/**
 * Refresh access token
 * POST /api/v1/auth/refresh
 */
export async function refreshToken(req: Request, res: Response) {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Refresh token is required',
            });
        }

        const result = await refreshTokenService(refreshToken);

        res.json(result);
    } catch (error) {
        console.error('Refresh token error:', error);
        res.status(401).json({
            error: 'Unauthorized',
            message: error instanceof Error ? error.message : 'Token refresh failed',
        });
    }
}

/**
 * Sign in with Google
 * POST /api/v1/auth/google
 */
export async function googleSignIn(req: Request, res: Response) {
    try {
        const { idToken } = req.body;

        if (!idToken) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Google ID token is required',
            });
        }

        const result = await verifyGoogleTokenService(idToken);

        res.json(result);
    } catch (error) {
        console.error('Google Sign-In error:', error);
        res.status(401).json({
            error: 'Unauthorized',
            message: error instanceof Error ? error.message : 'Google Sign-In failed',
        });
    }
}
