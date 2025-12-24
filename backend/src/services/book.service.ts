import prisma from '../config/database';
import { Book, BookCondition } from '@prisma/client';

/**
 * Get books feed with filters and pagination
 */
export async function getBooksFeed(params: {
    groupIds?: string[];
    availability?: 'AVAILABLE' | 'NOT_AVAILABLE';
    genres?: string[];
    minPrice?: number;
    maxPrice?: number;
    search?: string;
    sortBy?: 'RECENT' | 'PRICE_LOW' | 'PRICE_HIGH' | 'RATING';
    page?: number;
    limit?: number;
}) {
    const {
        groupIds,
        availability,
        genres,
        minPrice,
        maxPrice,
        search,
        sortBy = 'RECENT',
        page = 1,
        limit = 20,
    } = params;

    const where: any = {};

    // Filter by availability
    if (availability === 'AVAILABLE') {
        where.isAvailable = true;
    } else if (availability === 'NOT_AVAILABLE') {
        where.isAvailable = false;
    }

    // Filter by genres
    if (genres && genres.length > 0) {
        where.genre = { in: genres };
    }

    // Filter by price range
    if (minPrice !== undefined || maxPrice !== undefined) {
        where.lendingPricePerWeek = {};
        if (minPrice !== undefined) {
            where.lendingPricePerWeek.gte = minPrice;
        }
        if (maxPrice !== undefined) {
            where.lendingPricePerWeek.lte = maxPrice;
        }
    }

    // Search by title, author, or description
    if (search) {
        where.OR = [
            { title: { contains: search, mode: 'insensitive' } },
            { author: { contains: search, mode: 'insensitive' } },
            { description: { contains: search, mode: 'insensitive' } },
        ];
    }

    // Filter by group IDs
    if (groupIds && groupIds.length > 0) {
        where.bookGroups = {
            some: {
                groupId: { in: groupIds },
            },
        };
    }

    // Determine sort order
    let orderBy: any = {};
    switch (sortBy) {
        case 'PRICE_LOW':
            orderBy = { lendingPricePerWeek: 'asc' };
            break;
        case 'PRICE_HIGH':
            orderBy = { lendingPricePerWeek: 'desc' };
            break;
        case 'RATING':
            orderBy = { owner: { averageRating: 'desc' } };
            break;
        case 'RECENT':
        default:
            orderBy = { createdAt: 'desc' };
            break;
    }

    const skip = (page - 1) * limit;

    const [books, total] = await Promise.all([
        prisma.book.findMany({
            where,
            include: {
                owner: {
                    select: {
                        id: true,
                        name: true,
                        averageRating: true,
                        booksShared: true,
                        profileImageUrl: true,
                    },
                },
                bookGroups: {
                    include: {
                        group: {
                            select: {
                                id: true,
                                name: true,
                            },
                        },
                    },
                },
            },
            orderBy,
            skip,
            take: limit,
        }),
        prisma.book.count({ where }),
    ]);

    return {
        books,
        pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
        },
    };
}

/**
 * Get book by ID
 */
export async function getBookById(id: string) {
    return await prisma.book.findUnique({
        where: { id },
        include: {
            owner: {
                select: {
                    id: true,
                    name: true,
                    phoneNumber: true,
                    averageRating: true,
                    booksShared: true,
                    profileImageUrl: true,
                },
            },
            bookGroups: {
                include: {
                    group: {
                        select: {
                            id: true,
                            name: true,
                        },
                    },
                },
            },
        },
    });
}

/**
 * Create new book
 */
export async function createBook(data: {
    title: string;
    author: string;
    genre: string;
    description: string;
    personalNotes?: string;
    imageUrl?: string;
    isbn?: string;
    publisher?: string;
    year?: number;
    pages?: number;
    language?: string;
    condition: BookCondition;
    lendingPricePerWeek: number;
    ownerId: string;
    visibleInGroups: string[];
}) {
    const { visibleInGroups, ...bookData } = data;

    // Create book with group associations
    const book = await prisma.book.create({
        data: {
            ...bookData,
            bookGroups: {
                create: visibleInGroups.map(groupId => ({
                    groupId,
                })),
            },
        },
        include: {
            bookGroups: {
                include: {
                    group: true,
                },
            },
        },
    });

    // Update group books count
    await Promise.all(
        visibleInGroups.map(groupId =>
            prisma.group.update({
                where: { id: groupId },
                data: {
                    booksCount: {
                        increment: 1,
                    },
                },
            })
        )
    );

    // Update user's books shared count
    await prisma.user.update({
        where: { id: data.ownerId },
        data: {
            booksShared: {
                increment: 1,
            },
        },
    });

    return book;
}

/**
 * Update book
 */
export async function updateBook(
    id: string,
    data: Partial<{
        title: string;
        author: string;
        genre: string;
        description: string;
        personalNotes: string;
        imageUrl: string;
        isbn: string;
        publisher: string;
        year: number;
        pages: number;
        language: string;
        condition: BookCondition;
        lendingPricePerWeek: number;
        isAvailable: boolean;
        visibleInGroups: string[];
    }>
) {
    const { visibleInGroups, ...updateData } = data;

    // If visibleInGroups is provided, update book-group associations
    if (visibleInGroups) {
        // Get current groups
        const currentBookGroups = await prisma.bookGroup.findMany({
            where: { bookId: id },
        });

        const currentGroupIds = currentBookGroups.map(bg => bg.groupId);
        const groupsToAdd = visibleInGroups.filter(gid => !currentGroupIds.includes(gid));
        const groupsToRemove = currentGroupIds.filter(gid => !visibleInGroups.includes(gid));

        // Remove from old groups
        if (groupsToRemove.length > 0) {
            await prisma.bookGroup.deleteMany({
                where: {
                    bookId: id,
                    groupId: { in: groupsToRemove },
                },
            });

            // Decrement books count
            await Promise.all(
                groupsToRemove.map(groupId =>
                    prisma.group.update({
                        where: { id: groupId },
                        data: { booksCount: { decrement: 1 } },
                    })
                )
            );
        }

        // Add to new groups
        if (groupsToAdd.length > 0) {
            await prisma.bookGroup.createMany({
                data: groupsToAdd.map(groupId => ({
                    bookId: id,
                    groupId,
                })),
            });

            // Increment books count
            await Promise.all(
                groupsToAdd.map(groupId =>
                    prisma.group.update({
                        where: { id: groupId },
                        data: { booksCount: { increment: 1 } },
                    })
                )
            );
        }
    }

    return await prisma.book.update({
        where: { id },
        data: updateData,
        include: {
            bookGroups: {
                include: {
                    group: true,
                },
            },
        },
    });
}

/**
 * Delete book
 */
export async function deleteBook(id: string, ownerId: string) {
    // Get book to check ownership and groups
    const book = await prisma.book.findUnique({
        where: { id },
        include: {
            bookGroups: true,
        },
    });

    if (!book) {
        throw new Error('Book not found');
    }

    if (book.ownerId !== ownerId) {
        throw new Error('Unauthorized: You can only delete your own books');
    }

    // Delete book (cascade will handle bookGroups)
    await prisma.book.delete({
        where: { id },
    });

    // Update group books counts
    await Promise.all(
        book.bookGroups.map(bg =>
            prisma.group.update({
                where: { id: bg.groupId },
                data: { booksCount: { decrement: 1 } },
            })
        )
    );

    // Update user's books shared count
    await prisma.user.update({
        where: { id: ownerId },
        data: {
            booksShared: {
                decrement: 1,
            },
        },
    });
}

/**
 * Get available genres (for filtering)
 */
export async function getAvailableGenres() {
    const books = await prisma.book.findMany({
        select: { genre: true },
        distinct: ['genre'],
    });

    return books.map(b => b.genre).sort();
}
