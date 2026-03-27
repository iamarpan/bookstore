/**
 * ISBN Lookup Service
 * Fetches book data from OpenLibrary and Google Books APIs
 */

interface ISBNBookData {
    title?: string;
    author?: string;
    publisher?: string;
    year?: number;
    pages?: number;
    description?: string;
    imageUrl?: string;
    isbn?: string;
}

/**
 * Lookup book by ISBN from OpenLibrary
 */
async function lookupOpenLibrary(isbn: string): Promise<ISBNBookData | null> {
    try {
        const response = await fetch(`https://openlibrary.org/isbn/${isbn}.json`);
        if (!response.ok) return null;

        const data: any = await response.json();

        // Get cover image
        const imageUrl = `https://covers.openlibrary.org/b/isbn/${isbn}-L.jpg`;

        // Get author name
        let author;
        if (data.authors && data.authors.length > 0) {
            const authorKey = data.authors[0].key;
            const authorResponse = await fetch(`https://openlibrary.org${authorKey}.json`);
            if (authorResponse.ok) {
                const authorData: any = await authorResponse.json();
                author = authorData.name;
            }
        }

        return {
            title: data.title,
            author,
            publisher: data.publishers?.[0],
            year: data.publish_date ? parseInt(data.publish_date) : undefined,
            pages: data.number_of_pages,
            imageUrl,
            isbn,
        };
    } catch (error) {
        console.error('OpenLibrary lookup error:', error);
        return null;
    }
}

/**
 * Lookup book by ISBN from Google Books
 */
async function lookupGoogleBooks(isbn: string): Promise<ISBNBookData | null> {
    try {
        const response = await fetch(
            `https://www.googleapis.com/books/v1/volumes?q=isbn:${isbn}`
        );
        if (!response.ok) return null;

        const data: any = await response.json();
        if (!data.items || data.items.length === 0) return null;

        const book = data.items[0].volumeInfo;

        return {
            title: book.title,
            author: book.authors?.join(', '),
            publisher: book.publisher,
            year: book.publishedDate ? parseInt(book.publishedDate.split('-')[0]) : undefined,
            pages: book.pageCount,
            description: book.description,
            imageUrl: (book.imageLinks?.thumbnail || book.imageLinks?.smallThumbnail)?.replace('http:', 'https:'),
            isbn,
        };
    } catch (error) {
        console.error('Google Books lookup error:', error);
        return null;
    }
}

/**
 * Lookup book by ISBN (tries multiple APIs)
 */
export async function lookupISBN(isbn: string): Promise<ISBNBookData> {
    // Clean ISBN
    const cleanIsbn = isbn.replace(/[-\s]/g, '');

    // Try OpenLibrary first
    let bookData = await lookupOpenLibrary(cleanIsbn);

    // If OpenLibrary fails or returns incomplete data, try Google Books
    if (!bookData || !bookData.description) {
        const googleData = await lookupGoogleBooks(cleanIsbn);
        if (googleData) {
            // Merge data, preferring Google Books for description
            bookData = {
                ...bookData,
                ...googleData,
                // Keep OpenLibrary image if Google Books doesn't have one
                imageUrl: googleData.imageUrl || bookData?.imageUrl,
            };
        }
    }

    if (!bookData) {
        throw new Error('Book not found for this ISBN');
    }

    return bookData;
}
