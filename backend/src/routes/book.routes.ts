import { Router } from 'express';
import { authenticate, optionalAuth } from '../middleware/auth';
import {
    getBooksController,
    getBook,
    createBookController,
    updateBookController,
    deleteBookController,
    scanISBN,
    getGenres,
} from '../controllers/book.controller';

const router = Router();

/**
 * @swagger
 * /books/feed:
 *   get:
 *     tags: [Books]
 *     summary: Get books feed with filters and pagination
 *     description: Retrieve books with optional filters, search, sorting, and pagination
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *         name: groupIds
 *         schema:
 *           type: string
 *         description: Comma-separated list of group IDs to filter by
 *         example: "group1,group2"
 *       - in: query
 *         name: availability
 *         schema:
 *           type: string
 *           enum: [AVAILABLE, NOT_AVAILABLE]
 *         description: Filter by availability status
 *       - in: query
 *         name: genres
 *         schema:
 *           type: string
 *         description: Comma-separated list of genres
 *         example: "Fiction,Technology"
 *       - in: query
 *         name: minPrice
 *         schema:
 *           type: number
 *         description: Minimum lending price per week
 *       - in: query
 *         name: maxPrice
 *         schema:
 *           type: number
 *         description: Maximum lending price per week
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search in title, author, or description
 *       - in: query
 *         name: sortBy
 *         schema:
 *           type: string
 *           enum: [RECENT, PRICE_LOW, PRICE_HIGH, RATING]
 *           default: RECENT
 *         description: Sort order
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Items per page
 *     responses:
 *       200:
 *         description: Books retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 books:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Book'
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     page:
 *                       type: integer
 *                     limit:
 *                       type: integer
 *                     total:
 *                       type: integer
 *                     totalPages:
 *                       type: integer
 *       500:
 *         description: Server error
 */
router.get('/feed', optionalAuth, getBooksController);

/**
 * @swagger
 * /books/genres:
 *   get:
 *     tags: [Books]
 *     summary: Get available book genres
 *     description: Get list of all unique genres from books in database
 *     responses:
 *       200:
 *         description: Genres retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: string
 *               example: ["Fiction", "Technology", "Science", "History"]
 *       500:
 *         description: Server error
 */
router.get('/genres', getGenres);

/**
 * @swagger
 * /books/scan-isbn:
 *   post:
 *     tags: [Books]
 *     summary: Lookup book by ISBN
 *     description: Fetch book information from OpenLibrary and Google Books APIs using ISBN
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - isbn
 *             properties:
 *               isbn:
 *                 type: string
 *                 example: "9780743273565"
 *                 description: ISBN-10 or ISBN-13 (with or without hyphens)
 *     responses:
 *       200:
 *         description: Book information retrieved
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 title:
 *                   type: string
 *                 author:
 *                   type: string
 *                 publisher:
 *                   type: string
 *                 year:
 *                   type: integer
 *                 pages:
 *                   type: integer
 *                 description:
 *                   type: string
 *                 imageUrl:
 *                   type: string
 *                 isbn:
 *                   type: string
 *       400:
 *         description: ISBN is required
 *       404:
 *         description: Book not found for this ISBN
 *       500:
 *         description: Server error
 */
router.post('/scan-isbn', scanISBN);

/**
 * @swagger
 * /books/{id}:
 *   get:
 *     tags: [Books]
 *     summary: Get book details by ID
 *     description: Retrieve complete book information including owner details
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Book ID
 *     responses:
 *       200:
 *         description: Book details retrieved
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Book'
 *       404:
 *         description: Book not found
 *       500:
 *         description: Server error
 */
router.get('/:id', getBook);

/**
 * @swagger
 * /books:
 *   post:
 *     tags: [Books]
 *     summary: Create new book
 *     description: Add a new book to your library (authentication required)
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - author
 *               - genre
 *               - description
 *               - condition
 *               - visibleInGroups
 *             properties:
 *               title:
 *                 type: string
 *                 example: "The Great Gatsby"
 *               author:
 *                 type: string
 *                 example: "F. Scott Fitzgerald"
 *               genre:
 *                 type: string
 *                 example: "Fiction"
 *               description:
 *                 type: string
 *                 example: "A classic American novel"
 *               personalNotes:
 *                 type: string
 *                 example: "Gift from grandmother"
 *               imageUrl:
 *                 type: string
 *                 format: uri
 *               isbn:
 *                 type: string
 *                 example: "9780743273565"
 *               publisher:
 *                 type: string
 *               year:
 *                 type: integer
 *                 example: 1925
 *               pages:
 *                 type: integer
 *                 example: 180
 *               language:
 *                 type: string
 *                 default: "English"
 *               condition:
 *                 type: string
 *                 enum: [NEW, LIKE_NEW, GOOD, FAIR, POOR]
 *                 example: "GOOD"
 *               lendingPricePerWeek:
 *                 type: number
 *                 default: 0
 *                 example: 30
 *               visibleInGroups:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["group-id-1", "group-id-2"]
 *                 description: At least one group ID required
 *     responses:
 *       201:
 *         description: Book created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Book'
 *       400:
 *         description: Missing required fields or validation error
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         description: Server error
 */
router.post('/', authenticate, createBookController);

/**
 * @swagger
 * /books/{id}:
 *   put:
 *     tags: [Books]
 *     summary: Update book
 *     description: Update book details (owner only, all fields optional)
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Book ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               author:
 *                 type: string
 *               genre:
 *                 type: string
 *               description:
 *                 type: string
 *               personalNotes:
 *                 type: string
 *               imageUrl:
 *                 type: string
 *               condition:
 *                 type: string
 *                 enum: [NEW, LIKE_NEW, GOOD, FAIR, POOR]
 *               lendingPricePerWeek:
 *                 type: number
 *               isAvailable:
 *                 type: boolean
 *               visibleInGroups:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       200:
 *         description: Book updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Book'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: You can only update your own books
 *       404:
 *         description: Book not found
 *       500:
 *         description: Server error
 */
router.put('/:id', authenticate, updateBookController);

/**
 * @swagger
 * /books/{id}:
 *   delete:
 *     tags: [Books]
 *     summary: Delete book
 *     description: Delete a book from your library (owner only)
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Book ID
 *     responses:
 *       200:
 *         description: Book deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Book deleted successfully"
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: You can only delete your own books
 *       404:
 *         description: Book not found
 *       500:
 *         description: Server error
 */
router.delete('/:id', authenticate, deleteBookController);

export default router;
