import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../utils/jwt';

// Extend Express Request type to include user
declare global {
    namespace Express {
        interface Request {
            user?: {
                userId: string;
                phoneNumber: string;
            };
        }
    }
}

/**
 * Authentication middleware - verifies JWT token
 */
export function authenticate(req: Request, res: Response, next: NextFunction) {
    try {
        // Get token from Authorization header
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'No token provided',
            });
        }

        const token = authHeader.substring(7); // Remove 'Bearer ' prefix

        // Verify token
        const payload = verifyAccessToken(token);

        // Attach user info to request
        req.user = {
            userId: payload.userId,
            phoneNumber: payload.phoneNumber,
        };

        next();
    } catch (error) {
        return res.status(401).json({
            error: 'Unauthorized',
            message: error instanceof Error ? error.message : 'Invalid token',
        });
    }
}

/**
 * Optional authentication - attaches user if token exists
 */
export function optionalAuth(req: Request, res: Response, next: NextFunction) {
    try {
        const authHeader = req.headers.authorization;

        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.substring(7);
            const payload = verifyAccessToken(token);
            req.user = {
                userId: payload.userId,
                phoneNumber: payload.phoneNumber,
            };
        }

        next();
    } catch (error) {
        // Ignore errors for optional auth
        next();
    }
}
