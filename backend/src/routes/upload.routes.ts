import { Router, Request, Response } from 'express';
import { authenticate } from '../middleware/auth';
import multer, { FileFilterCallback } from 'multer';
import path from 'path';
import { supabaseAdmin } from '../config/supabase';

const router = Router();

const BUCKET_NAME = process.env.SUPABASE_STORAGE_BUCKET || 'bookstore-images';

const storage = multer.memoryStorage();
const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
    fileFilter: (_req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
        const allowed = ['.jpg', '.jpeg', '.png', '.webp'];
        const ext = path.extname(file.originalname).toLowerCase();
        if (allowed.includes(ext)) {
            cb(null, true);
        } else {
            cb(new Error('Only image files are allowed (jpg, jpeg, png, webp)'));
        }
    },
});

/**
 * @swagger
 * /upload:
 *   post:
 *     tags: [Upload]
 *     summary: Upload an image to Supabase Storage
 *     description: |
 *       Upload an image (book cover, profile picture, group cover).
 *       File is stored in the Supabase Storage bucket configured via
 *       SUPABASE_STORAGE_BUCKET (defaults to `bookstore-images`).
 *       Returns a permanent public URL.
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required: [image]
 *             properties:
 *               image:
 *                 type: string
 *                 format: binary
 *                 description: Image file (jpg, jpeg, png, webp — max 5 MB)
 *     responses:
 *       200:
 *         description: Image uploaded successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 url:
 *                   type: string
 *                   example: https://xyz.supabase.co/storage/v1/object/public/bookstore-images/books/abc123.jpg
 *       400:
 *         description: No image provided or invalid file type
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         description: Storage upload failed
 */
router.post('/', authenticate, upload.single('image'), async (req: Request, res: Response) => {
    const file = (req as any).file as Express.Multer.File | undefined;

    if (!file) {
        return res.status(400).json({
            error: 'Bad Request',
            message: 'No image file provided. Use field name "image".',
        });
    }

    try {
        // Build a unique file path scoped to the uploading user
        const userId = req.user!.userId;
        const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
        const filePath = `books/${userId}/${Date.now()}${ext}`;

        const { error: uploadError } = await supabaseAdmin.storage
            .from(BUCKET_NAME)
            .upload(filePath, file.buffer, {
                contentType: file.mimetype,
                upsert: false,
            });

        if (uploadError) {
            console.error('Supabase upload error:', uploadError);
            return res.status(500).json({
                error: 'Upload Failed',
                message: uploadError.message,
            });
        }

        // Retrieve the permanent public URL
        const { data } = supabaseAdmin.storage
            .from(BUCKET_NAME)
            .getPublicUrl(filePath);

        console.log(`✅ Image uploaded to Supabase: ${data.publicUrl}`);
        res.json({ url: data.publicUrl });

    } catch (error) {
        console.error('Upload endpoint error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: error instanceof Error ? error.message : 'Upload failed',
        });
    }
});

export default router;
