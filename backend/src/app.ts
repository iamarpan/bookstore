import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';

// Swagger
import { swaggerUi, getSwaggerSpec } from './config/swagger';

// Routes
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import bookRoutes from './routes/book.routes';
import transactionRoutes from './routes/transaction.routes';
import groupRoutes from './routes/group.routes';

// Load environment variables
dotenv.config();

console.log('🚀 Bookstore Backend Initializing...');

const app: Application = express();

// Security & Parsing Middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net"],
            styleSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net"],
            imgSrc: ["'self'", "data:", "https://cdn.jsdelivr.net"],
        },
    },
}));
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Swagger Documentation - Using CDN for Vercel compatibility
app.get('/api-docs', (req: Request, res: Response) => {
    console.log('Generating API Docs...');
    // Generate dynamic spec with correct server URL
    const protocol = req.protocol;
    const host = req.get('host');
    const baseUrl = `${protocol}://${host}/api/v1`;

    const swaggerSpec = getSwaggerSpec();

    // Clone the spec and update servers dynamically
    const dynamicSpec = {
        ...swaggerSpec,
        servers: [
            {
                url: baseUrl,
                description: process.env.NODE_ENV === 'production' ? 'Production server' : 'Development server',
            },
        ],
    };

    const html = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Bookstore API Documentation</title>
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css" />
        <style>
            .swagger-ui .topbar { display: none }
        </style>
    </head>
    <body>
        <div id="swagger-ui"></div>
        <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-standalone-preset.js"></script>
        <script>
            window.onload = function() {
                window.ui = SwaggerUIBundle({
                    spec: ${JSON.stringify(dynamicSpec)},
                    dom_id: '#swagger-ui',
                    deepLinking: true,
                    presets: [
                        SwaggerUIBundle.presets.apis,
                        SwaggerUIStandalonePreset
                    ],
                    plugins: [
                        SwaggerUIBundle.plugins.DownloadUrl
                    ],
                    layout: "StandaloneLayout",
                    persistAuthorization: true
                });
            };
        </script>
    </body>
    </html>
    `;
    res.send(html);
});

// JSON spec endpoint
app.get('/api-docs/swagger.json', (req: Request, res: Response) => {
    // Generate dynamic spec with correct server URL
    const protocol = req.protocol;
    const host = req.get('host');
    const baseUrl = `${protocol}://${host}/api/v1`;

    const swaggerSpec = getSwaggerSpec();

    const dynamicSpec = {
        ...swaggerSpec,
        servers: [
            {
                url: baseUrl,
                description: process.env.NODE_ENV === 'production' ? 'Production server' : 'Development server',
            },
        ],
    };

    res.json(dynamicSpec);
});

// Health check
app.get('/health', (req: Request, res: Response) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        env: process.env.NODE_ENV,
        initialized: true
    });
});

// API info
app.get('/api/v1', (req: Request, res: Response) => {
    res.json({
        message: 'Bookstore API v1',
        version: '1.0.0',
        endpoints: {
            auth: '/api/v1/auth',
            users: '/api/v1/users',
            books: '/api/v1/books',
            transactions: '/api/v1/transactions',
            groups: '/api/v1/groups',
        },
        documentation: '/api-docs',
    });
});

// Mount API routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/books', bookRoutes);
app.use('/api/v1/transactions', transactionRoutes);
app.use('/api/v1/groups', groupRoutes);

// 404 handler
app.use((req: Request, res: Response) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.method} ${req.path} not found`,
    });
});

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error('Error:', err);
    res.status(500).json({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
    });
});

export default app;
