import { Request, Response } from 'express';
import {
    getBooksFeed,
    getBookById,
    createBook,
    updateBook,
    deleteBook,
    getAvailableGenres,
} from '../services/book.service';
import { lookupISBN } from '../services/isbn.service';
import { BookCondition } from '@prisma/client';

/**
 * Get books feed with filters
 * GET /api/v1/books/feed
 */
export async function getBooksController(req: Request, res: Response) {
    try {
        const {
            groupIds,
            availability,
            genres,
            minPrice,
            maxPrice,
            search,
            sortBy,
            page,
            limit,
        } = req.query;

        const result = await getBooksFeed({
            groupIds: groupIds ? String(groupIds).split(',') : undefined,
            availability: availability as 'AVAILABLE' | 'NOT_AVAILABLE' | undefined,
            genres: genres ? String(genres).split(',') : undefined,
            minPrice: minPrice ? parseFloat(String(minPrice)) : undefined,
            maxPrice: maxPrice ? parseFloat(String(maxPrice)) : undefined,
            search: search ? String(search) : undefined,
            sortBy: sortBy as 'RECENT' | 'PRICE_LOW' | 'PRICE_HIGH' | 'RATING' | undefined,
            page: page ? parseInt(String(page)) : undefined,
            limit: limit ? parseInt(String(limit)) : undefined,
        });

        res.json(result);
    } catch (error) {
        console.error('Get books feed error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to fetch books',
        });
    }
}

/**
 * Get book by ID
 * GET /api/v1/books/:id
 */
export async function getBook(req: Request, res: Response) {
    try {
        const { id } = req.params;

        const book = await getBookById(id);

        if (!book) {
            return res.status(404).json({
                error: 'Not Found',
                message: 'Book not found',
            });
        }

        res.json(book);
    } catch (error) {
        console.error('Get book error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to fetch book',
        });
    }
}

/**
 * Create new book
 * POST /api/v1/books
 */
export async function createBookController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const {
            title,
            author,
            genre,
            description,
            personalNotes,
            imageUrl,
            isbn,
            publisher,
            year,
            pages,
            language,
            condition,
            lendingPricePerWeek,
            visibleInGroups,
        } = req.body;

        // Validate required fields
        if (!title || !author || !genre || !description || !condition) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Missing required fields: title, author, genre, description, condition',
            });
        }

        if (!visibleInGroups || visibleInGroups.length === 0) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'Book must be visible in at least one group',
            });
        }

        const book = await createBook({
            title,
            author,
            genre,
            description,
            personalNotes,
            imageUrl,
            isbn,
            publisher,
            year,
            pages,
            language: language || 'English',
            condition: condition as BookCondition,
            lendingPricePerWeek: lendingPricePerWeek || 0,
            ownerId: req.user.userId,
            visibleInGroups,
        });

        res.status(201).json(book);
    } catch (error) {
        console.error('Create book error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: error instanceof Error ? error.message : 'Failed to create book',
        });
    }
}

/**
 * Update book
 * PUT /api/v1/books/:id
 */
export async function updateBookController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { id } = req.params;

        // Check if book exists and user owns it
        const existingBook = await getBookById(id);
        if (!existingBook) {
            return res.status(404).json({
                error: 'Not Found',
                message: 'Book not found',
            });
        }

        if (existingBook.ownerId !== req.user.userId) {
            return res.status(403).json({
                error: 'Forbidden',
                message: 'You can only update your own books',
            });
        }

        const book = await updateBook(id, req.body);

        res.json(book);
    } catch (error) {
        console.error('Update book error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to update book',
        });
    }
}

/**
 * Delete book
 * DELETE /api/v1/books/:id
 */
export async function deleteBookController(req: Request, res: Response) {
    try {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not authenticated',
            });
        }

        const { id } = req.params;

        await deleteBook(id, req.user.userId);

        res.json({
            message: 'Book deleted successfully',
        });
    } catch (error) {
        console.error('Delete book error:', error);

        if (error instanceof Error) {
            if (error.message.includes('Unauthorized')) {
                return res.status(403).json({
                    error: 'Forbidden',
                    message: error.message,
                });
            }
            if (error.message.includes('not found')) {
                return res.status(404).json({
                    error: 'Not Found',
                    message: error.message,
                });
            }
        }

        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to delete book',
        });
    }
}

/**
 * Lookup book by ISBN
 * POST /api/v1/books/scan-isbn
 */
export async function scanISBN(req: Request, res: Response) {
    try {
        const { isbn } = req.body;

        if (!isbn) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'ISBN is required',
            });
        }

        const bookData = await lookupISBN(isbn);

        res.json(bookData);
    } catch (error) {
        console.error('ISBN lookup error:', error);
        res.status(404).json({
            error: 'Not Found',
            message: error instanceof Error ? error.message : 'Book not found for this ISBN',
        });
    }
}

/**
 * Get available genres
 * GET /api/v1/books/genres
 */
export async function getGenres(req: Request, res: Response) {
    try {
        const genres = await getAvailableGenres();
        res.json(genres);
    } catch (error) {
        console.error('Get genres error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'Failed to fetch genres',
        });
    }
}
