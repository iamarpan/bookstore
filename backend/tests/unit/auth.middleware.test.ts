import { Request, Response, NextFunction } from 'express';
import { authenticate, optionalAuth } from '../../src/middleware/auth';
import { generateAccessToken } from '../../src/utils/jwt';

/**
 * Helper to build a minimal mock Express Request.
 */
function makeReq(authHeader?: string): Partial<Request> {
    return {
        headers: authHeader ? { authorization: authHeader } : {},
    };
}

/**
 * Mock Response with chainable status().json().
 */
function makeRes() {
    const res: any = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res;
}

const makeNext = (): NextFunction => jest.fn();

const validPayload = { userId: 'user-1', phoneNumber: '+911234567890' };

describe('authenticate middleware', () => {
    it('returns 401 when Authorization header is missing', () => {
        const req = makeReq() as Request;
        const res = makeRes();
        const next = makeNext();

        authenticate(req, res as Response, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.json).toHaveBeenCalledWith(
            expect.objectContaining({ message: 'No token provided' })
        );
        expect(next).not.toHaveBeenCalled();
    });

    it('returns 401 when Authorization header does not start with "Bearer "', () => {
        const req = makeReq('Basic sometoken') as Request;
        const res = makeRes();
        const next = makeNext();

        authenticate(req, res as Response, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(next).not.toHaveBeenCalled();
    });

    it('returns 401 when the token is invalid', () => {
        const req = makeReq('Bearer invalid.token.here') as Request;
        const res = makeRes();
        const next = makeNext();

        authenticate(req, res as Response, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(next).not.toHaveBeenCalled();
    });

    it('calls next() and attaches user to req when token is valid', () => {
        const token = generateAccessToken(validPayload);
        const req = makeReq(`Bearer ${token}`) as Request;
        const res = makeRes();
        const next = makeNext();

        authenticate(req, res as Response, next);

        expect(next).toHaveBeenCalledTimes(1);
        expect(req.user).toEqual(validPayload);
        expect(res.status).not.toHaveBeenCalled();
    });
});

describe('optionalAuth middleware', () => {
    it('calls next() without attaching user when no Authorization header', () => {
        const req = makeReq() as Request;
        const res = makeRes();
        const next = makeNext();

        optionalAuth(req, res as Response, next);

        expect(next).toHaveBeenCalledTimes(1);
        expect((req as any).user).toBeUndefined();
    });

    it('attaches user to req when a valid token is provided', () => {
        const token = generateAccessToken(validPayload);
        const req = makeReq(`Bearer ${token}`) as Request;
        const res = makeRes();
        const next = makeNext();

        optionalAuth(req, res as Response, next);

        expect(next).toHaveBeenCalledTimes(1);
        expect(req.user).toEqual(validPayload);
    });

    it('ignores an invalid token and still calls next()', () => {
        const req = makeReq('Bearer bad.token') as Request;
        const res = makeRes();
        const next = makeNext();

        optionalAuth(req, res as Response, next);

        expect(next).toHaveBeenCalledTimes(1);
        expect((req as any).user).toBeUndefined();
    });
});
