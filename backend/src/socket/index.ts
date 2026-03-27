import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import { verifyAccessToken, TokenPayload } from '../utils/jwt';

let io: Server | null = null;

interface AuthenticatedSocket extends Socket {
    data: {
        userId: string;
        phoneNumber: string;
    };
}

export function initializeSocketServer(httpServer: HttpServer): Server {
    io = new Server(httpServer, {
        cors: {
            origin: '*',
            methods: ['GET', 'POST'],
        },
        transports: ['websocket', 'polling'],
        pingTimeout: 60000,
        pingInterval: 25000,
    });

    io.use((socket: Socket, next) => {
        try {
            const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
            
            if (!token) {
                return next(new Error('Authentication token required'));
            }

            const decoded: TokenPayload = verifyAccessToken(token);
            socket.data.userId = decoded.userId;
            socket.data.phoneNumber = decoded.phoneNumber;
            next();
        } catch (err) {
            next(new Error('Authentication failed: Invalid or expired token'));
        }
    });

    io.on('connection', (socket: AuthenticatedSocket) => {
        const userId = socket.data.userId;
        console.log(`[Socket] User connected: ${userId}`);

        socket.join(`user:${userId}`);

        socket.on('join_chat', (transactionId: string) => {
            if (transactionId) {
                socket.join(`chat:${transactionId}`);
                console.log(`[Socket] User ${userId} joined chat: ${transactionId}`);
            }
        });

        socket.on('leave_chat', (transactionId: string) => {
            if (transactionId) {
                socket.leave(`chat:${transactionId}`);
                console.log(`[Socket] User ${userId} left chat: ${transactionId}`);
            }
        });

        socket.on('typing', (data: { transactionId: string; isTyping: boolean }) => {
            if (data.transactionId) {
                socket.to(`chat:${data.transactionId}`).emit('user_typing', {
                    userId,
                    transactionId: data.transactionId,
                    isTyping: data.isTyping,
                });
            }
        });

        socket.on('message_read', (data: { transactionId: string }) => {
            if (data.transactionId) {
                socket.to(`chat:${data.transactionId}`).emit('messages_read', {
                    userId,
                    transactionId: data.transactionId,
                });
            }
        });

        socket.on('disconnect', (reason) => {
            console.log(`[Socket] User disconnected: ${userId}, reason: ${reason}`);
        });

        socket.on('error', (error) => {
            console.error(`[Socket] Error for user ${userId}:`, error);
        });
    });

    console.log('[Socket] Socket.IO server initialized');
    return io;
}

export function getIO(): Server {
    if (!io) {
        throw new Error('Socket.IO not initialized. Call initializeSocketServer first.');
    }
    return io;
}

export function emitToChat(transactionId: string, event: string, data: any): void {
    if (io) {
        io.to(`chat:${transactionId}`).emit(event, data);
    }
}

export function emitToUser(userId: string, event: string, data: any): void {
    if (io) {
        io.to(`user:${userId}`).emit(event, data);
    }
}

export function emitNewMessage(transactionId: string, recipientId: string, message: any): void {
    if (io) {
        io.to(`chat:${transactionId}`).emit('new_message', message);
        io.to(`user:${recipientId}`).emit('message_notification', {
            transactionId,
            message,
        });
    }
}
