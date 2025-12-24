import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export default prisma;

// Disconnect on application termination
process.on('beforeExit', async () => {
    await prisma.$disconnect();
});
