import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

const options: swaggerJsdoc.Options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'Bookstore API',
            version: '1.0.0',
            description: 'REST API for Bookstore iOS application - book sharing platform with groups, transactions, and notifications',
            contact: {
                name: 'API Support',
                email: 'support@bookstore.com',
            },
        },
        servers: [
            {
                url: 'http://localhost:3000/api/v1',
                description: 'Development server',
            },
            {
                url: 'https://bookapp-iota-nine.vercel.app/api/v1',
                description: 'Production server (Vercel)',
            },
        ],
        components: {
            securitySchemes: {
                BearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                    description: 'Enter your JWT access token',
                },
            },
            schemas: {
                User: {
                    type: 'object',
                    properties: {
                        id: { type: 'string', format: 'uuid' },
                        phoneNumber: { type: 'string', example: '+919876543210' },
                        phoneVerified: { type: 'boolean' },
                        name: { type: 'string', example: 'John Doe' },
                        email: { type: 'string', format: 'email', nullable: true },
                        bio: { type: 'string', nullable: true },
                        profileImageUrl: { type: 'string', format: 'uri', nullable: true },
                        booksShared: { type: 'integer' },
                        successfulLends: { type: 'integer' },
                        booksBorrowed: { type: 'integer' },
                        totalEarned: { type: 'number', format: 'decimal' },
                        averageRating: { type: 'number', format: 'decimal' },
                        phoneVisibility: {
                            type: 'string',
                            enum: ['AFTER_APPROVAL', 'GROUP_MEMBERS', 'PUBLIC'],
                        },
                        pushEnabled: { type: 'boolean' },
                        emailEnabled: { type: 'boolean' },
                        createdAt: { type: 'string', format: 'date-time' },
                        lastLoginAt: { type: 'string', format: 'date-time', nullable: true },
                    },
                },
                Book: {
                    type: 'object',
                    properties: {
                        id: { type: 'string', format: 'uuid' },
                        title: { type: 'string', example: 'The Great Gatsby' },
                        author: { type: 'string', example: 'F. Scott Fitzgerald' },
                        genre: { type: 'string', example: 'Fiction' },
                        description: { type: 'string' },
                        imageUrl: { type: 'string', format: 'uri', nullable: true },
                        isbn: { type: 'string', nullable: true },
                        publisher: { type: 'string', nullable: true },
                        year: { type: 'integer', nullable: true },
                        pages: { type: 'integer', nullable: true },
                        language: { type: 'string', default: 'English' },
                        condition: {
                            type: 'string',
                            enum: ['NEW', 'LIKE_NEW', 'GOOD', 'FAIR', 'POOR'],
                        },
                        lendingPricePerWeek: { type: 'number', format: 'decimal' },
                        isAvailable: { type: 'boolean' },
                        ownerId: { type: 'string', format: 'uuid' },
                        ownerName: { type: 'string' },
                        createdAt: { type: 'string', format: 'date-time' },
                        updatedAt: { type: 'string', format: 'date-time' },
                    },
                },
                Error: {
                    type: 'object',
                    properties: {
                        error: { type: 'string', example: 'Bad Request' },
                        message: { type: 'string', example: 'Invalid input data' },
                    },
                },
            },
            responses: {
                UnauthorizedError: {
                    description: 'Access token is missing or invalid',
                    content: {
                        'application/json': {
                            schema: { $ref: '#/components/schemas/Error' },
                            example: {
                                error: 'Unauthorized',
                                message: 'No token provided',
                            },
                        },
                    },
                },
                NotFoundError: {
                    description: 'Resource not found',
                    content: {
                        'application/json': {
                            schema: { $ref: '#/components/schemas/Error' },
                            example: {
                                error: 'Not Found',
                                message: 'Resource not found',
                            },
                        },
                    },
                },
                ValidationError: {
                    description: 'Validation error',
                    content: {
                        'application/json': {
                            schema: { $ref: '#/components/schemas/Error' },
                            example: {
                                error: 'Bad Request',
                                message: 'Missing required fields',
                            },
                        },
                    },
                },
            },
        },
        tags: [
            {
                name: 'Authentication',
                description: 'Phone OTP-based authentication endpoints',
            },
            {
                name: 'Users',
                description: 'User profile and settings management',
            },
            {
                name: 'Books',
                description: 'Book catalog, CRUD operations, and ISBN lookup',
            },
        ],
    },
    apis: ['./src/routes/*.ts'], // Path to API route files
};

export const swaggerSpec = swaggerJsdoc(options);
export { swaggerUi };
