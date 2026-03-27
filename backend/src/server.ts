import { createServer } from 'http';
import app from './app';
import { initializeSocketServer } from './socket';

const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

const httpServer = createServer(app);

initializeSocketServer(httpServer);

httpServer.listen(PORT, () => {
    console.log('=================================');
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📚 Environment: ${NODE_ENV}`);
    console.log(`🔗 API: http://localhost:${PORT}/api/v1`);
    console.log(`💚 Health: http://localhost:${PORT}/health`);
    console.log(`🔌 WebSocket: ws://localhost:${PORT}`);
    console.log('=================================');
});

process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    httpServer.close(() => {
        console.log('HTTP server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('SIGINT signal received: closing HTTP server');
    httpServer.close(() => {
        console.log('HTTP server closed');
        process.exit(0);
    });
});
