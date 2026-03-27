import { createServer } from 'http';
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { initializeSocketServer } from './socket';

dotenv.config();

const PORT = process.env.SOCKET_PORT || process.env.PORT || 3001;
const NODE_ENV = process.env.NODE_ENV || 'development';

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        service: 'socket-server',
        timestamp: new Date().toISOString(),
        env: NODE_ENV,
    });
});

app.get('/', (req, res) => {
    res.json({
        service: 'Bookstore WebSocket Server',
        version: '1.0.0',
        status: 'running',
        websocket: `ws://localhost:${PORT}`,
    });
});

const httpServer = createServer(app);

const io = initializeSocketServer(httpServer);

httpServer.listen(PORT, () => {
    console.log('=================================');
    console.log(`🔌 Socket Server running on port ${PORT}`);
    console.log(`📚 Environment: ${NODE_ENV}`);
    console.log(`💚 Health: http://localhost:${PORT}/health`);
    console.log(`🌐 WebSocket: ws://localhost:${PORT}`);
    console.log('=================================');
});

process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing Socket server');
    io.close();
    httpServer.close(() => {
        console.log('Socket server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('SIGINT signal received: closing Socket server');
    io.close();
    httpServer.close(() => {
        console.log('Socket server closed');
        process.exit(0);
    });
});
