import { PrismaClient } from '@prisma/client';

// Singleton pattern for Prisma Client in serverless environments
// This prevents multiple instances and connection pool issues
declare global {
    // eslint-disable-next-line no-var
    var prisma: PrismaClient | undefined;
}

const prisma =
    global.prisma ||
    new PrismaClient({
        log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
        datasources: {
            db: {
                url: process.env.DATABASE_URL,
            },
        },
    });

// Note: Prisma connects lazily on the first request.
// In serverless, top-level $connect() can lead to timeouts.

if (process.env.NODE_ENV !== 'production') {
    global.prisma = prisma;
}

export default prisma;

// Graceful shutdown - disconnect on application termination
// Note: In serverless, connections are automatically cleaned up
if (process.env.NODE_ENV !== 'production') {
    process.on('beforeExit', async () => {
        await prisma.$disconnect();
    });
}
