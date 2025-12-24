import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Starting database seed...');

    // Create demo users
    const user1 = await prisma.user.upsert({
        where: { phoneNumber: '+919876543210' },
        update: {},
        create: {
            phoneNumber: '+919876543210',
            phoneVerified: true,
            name: 'Demo User',
            email: 'demo@bookstore.com',
            bio: 'Book enthusiast and avid reader',
            booksShared: 8,
            successfulLends: 15,
            booksBorrowed: 12,
            totalEarned: 650,
            averageRating: 4.7,
        },
    });

    const user2 = await prisma.user.upsert({
        where: { phoneNumber: '+919876543211' },
        update: {},
        create: {
            phoneNumber: '+919876543211',
            phoneVerified: true,
            name: 'John Smith',
            email: 'john@example.com',
            booksShared: 12,
            averageRating: 4.8,
        },
    });

    const user3 = await prisma.user.upsert({
        where: { phoneNumber: '+919876543212' },
        update: {},
        create: {
            phoneNumber: '+919876543212',
            phoneVerified: true,
            name: 'Sarah Johnson',
            booksShared: 8,
            averageRating: 4.9,
        },
    });

    console.log('✅ Created demo users');

    // Create demo group
    const group1 = await prisma.group.upsert({
        where: { inviteCode: 'DEMO123' },
        update: {},
        create: {
            name: 'Office Book Club',
            description: 'Share books among colleagues',
            category: 'OFFICE',
            privacy: 'PRIVATE',
            creatorId: user1.id,
            inviteCode: 'DEMO123',
            rules: '1. Return books on time\n2. Keep books in good condition\n3. Be respectful',
            booksCount: 5,
            memberCount: 3,
        },
    });

    console.log('✅ Created demo group');

    // Add group members
    await prisma.groupMember.createMany({
        data: [
            {
                groupId: group1.id,
                userId: user1.id,
                role: 'CREATOR',
            },
            {
                groupId: group1.id,
                userId: user2.id,
                role: 'MEMBER',
            },
            {
                groupId: group1.id,
                userId: user3.id,
                role: 'MEMBER',
            },
        ],
        skipDuplicates: true,
    });

    console.log('✅ Added group members');

    // Create demo books
    const book1 = await prisma.book.create({
        data: {
            title: 'The Great Gatsby',
            author: 'F. Scott Fitzgerald',
            genre: 'Fiction',
            description: 'A classic American novel about the American Dream and the decadence of the 1920s.',
            imageUrl: 'https://covers.openlibrary.org/b/id/8225261-L.jpg',
            isbn: '9780743273565',
            publisher: 'Scribner',
            year: 1925,
            pages: 180,
            condition: 'GOOD',
            lendingPricePerWeek: 30,
            ownerId: user2.id,
        },
    });

    const book2 = await prisma.book.create({
        data: {
            title: 'Clean Code',
            author: 'Robert C. Martin',
            genre: 'Technology',
            description: 'A handbook of agile software craftsmanship for writing clean, maintainable code.',
            imageUrl: 'https://covers.openlibrary.org/b/id/6999792-L.jpg',
            isbn: '9780132350884',
            publisher: 'Prentice Hall',
            year: 2008,
            pages: 464,
            condition: 'GOOD',
            lendingPricePerWeek: 40,
            ownerId: user1.id,
        },
    });

    const book3 = await prisma.book.create({
        data: {
            title: 'Sapiens',
            author: 'Yuval Noah Harari',
            genre: 'History',
            description: 'A brief history of humankind.',
            imageUrl: 'https://covers.openlibrary.org/b/id/8192456-L.jpg',
            isbn: '9780062316097',
            year: 2015,
            pages: 443,
            condition: 'LIKE_NEW',
            lendingPricePerWeek: 45,
            ownerId: user3.id,
        },
    });

    console.log('✅ Created demo books');

    // Link books to group
    await prisma.bookGroup.createMany({
        data: [
            { bookId: book1.id, groupId: group1.id },
            { bookId: book2.id, groupId: group1.id },
            { bookId: book3.id, groupId: group1.id },
        ],
        skipDuplicates: true,
    });

    console.log('✅ Linked books to group');

    console.log('🎉 Seed completed successfully!');
}

main()
    .catch(e => {
        console.error('❌ Seed failed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
