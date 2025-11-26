# Book Sharing App - API Specifications

## Base URL
```
Production: https://api.bookshare.app/v1
Staging: https://api-staging.bookshare.app/v1
```

## Authentication
All authenticated endpoints require `Authorization: Bearer {jwt_token}` header.

---

## 1. Authentication APIs

### 1.1 Register User
```http
POST /auth/register
```

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+919876543210",
  "password": "SecurePass123!",
  "profile_image": "data:image/jpeg;base64,..." // optional
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "OTP sent to phone",
  "data": {
    "user_id": "usr_1a2b3c4d",
    "verification_required": true
  }
}
```

### 1.2 Verify Phone (OTP)
```http
POST /auth/verify-phone
```

**Request Body:**
```json
{
  "user_id": "usr_1a2b3c4d",
  "otp": "1234"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "usr_1a2b3c4d",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+919876543210",
      "profile_image": "https://cdn.bookshare.app/users/...",
      "verified": true,
      "created_at": "2025-01-15T10:30:00Z"
    },
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 86400
  }
}
```

### 1.3 Login
```http
POST /auth/login
```

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Response (200):** Same as 1.2

### 1.4 Refresh Token
```http
POST /auth/refresh
```

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 86400
  }
}
```

---

## 2. Group Management APIs

### 2.1 Create Group
```http
POST /groups
```

**Request Body:**
```json
{
  "name": "Office Book Club",
  "description": "Share technical and business books",
  "category": "office", // office, friends, neighborhood, book_club, school
  "privacy": "private", // public, private
  "cover_image": "data:image/jpeg;base64,...", // optional
  "rules": "1. Return books on time\n2. Handle with care" // optional
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "group": {
      "id": "grp_9x8y7z6w",
      "name": "Office Book Club",
      "description": "Share technical and business books",
      "category": "office",
      "privacy": "private",
      "cover_image": "https://cdn.bookshare.app/groups/...",
      "rules": "1. Return books on time\n2. Handle with care",
      "invite_link": "https://bookshare.app/join/abc123xyz",
      "created_by": "usr_1a2b3c4d",
      "members_count": 1,
      "books_count": 0,
      "created_at": "2025-01-15T11:00:00Z"
    }
  }
}
```

### 2.2 Get User's Groups
```http
GET /groups/me
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "groups": [
      {
        "id": "grp_9x8y7z6w",
        "name": "Office Book Club",
        "cover_image": "https://cdn.bookshare.app/groups/...",
        "members_count": 15,
        "books_count": 47,
        "role": "admin", // admin, moderator, member
        "joined_at": "2025-01-15T11:00:00Z"
      }
    ]
  }
}
```

### 2.3 Discover Public Groups
```http
GET /groups/discover?category=office&search=tech&page=1&limit=20
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "groups": [
      {
        "id": "grp_5t6y7u8i",
        "name": "Tech Readers",
        "description": "Latest tech books",
        "category": "office",
        "cover_image": "https://cdn.bookshare.app/groups/...",
        "members_count": 42,
        "books_count": 128,
        "privacy": "public"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_count": 52
    }
  }
}
```

### 2.4 Join Group
```http
POST /groups/{group_id}/join
```

**Request Body:**
```json
{
  "invite_code": "abc123xyz" // required for private groups
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Successfully joined Office Book Club",
  "data": {
    "membership": {
      "group_id": "grp_9x8y7z6w",
      "user_id": "usr_1a2b3c4d",
      "role": "member",
      "status": "active", // active, pending (for private groups)
      "joined_at": "2025-01-15T12:00:00Z"
    }
  }
}
```

### 2.5 Get Group Details
```http
GET /groups/{group_id}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "group": {
      "id": "grp_9x8y7z6w",
      "name": "Office Book Club",
      "description": "Share technical and business books",
      "category": "office",
      "privacy": "private",
      "cover_image": "https://cdn.bookshare.app/groups/...",
      "rules": "1. Return books on time\n2. Handle with care",
      "created_by": {
        "id": "usr_1a2b3c4d",
        "name": "John Doe",
        "profile_image": "https://cdn.bookshare.app/users/..."
      },
      "members_count": 15,
      "books_count": 47,
      "created_at": "2025-01-15T11:00:00Z",
      "my_role": "admin" // only if user is a member
    }
  }
}
```

### 2.6 Update Group (Admin/Moderator only)
```http
PATCH /groups/{group_id}
```

**Request Body:** Same fields as Create Group (all optional)

### 2.7 Leave Group
```http
DELETE /groups/{group_id}/leave
```

**Response (200):**
```json
{
  "success": true,
  "message": "You have left Office Book Club"
}
```

### 2.8 Remove Member (Admin/Moderator only)
```http
DELETE /groups/{group_id}/members/{user_id}
```

---

## 3. Book Management APIs

### 3.1 Upload Book (ISBN Scan)
```http
POST /books/scan
```

**Request Body:**
```json
{
  "isbn": "9780137081073"
}
```

**Response (200):** Returns fetched book details for confirmation
```json
{
  "success": true,
  "data": {
    "book_info": {
      "title": "The Pragmatic Programmer",
      "author": "David Thomas, Andrew Hunt",
      "cover_image": "https://covers.openlibrary.org/b/isbn/...",
      "genre": "Technology",
      "publisher": "Addison-Wesley",
      "year": 2019,
      "pages": 352,
      "language": "English",
      "isbn": "9780137081073"
    }
  }
}
```

### 3.2 Create Book
```http
POST /books
```

**Request Body:**
```json
{
  "title": "The Pragmatic Programmer",
  "author": "David Thomas, Andrew Hunt",
  "cover_image": "https://covers.openlibrary.org/b/isbn/...",
  "genre": "Technology",
  "publisher": "Addison-Wesley",
  "year": 2019,
  "pages": 352,
  "language": "English",
  "isbn": "9780137081073", // optional
  "condition": "like_new", // new, like_new, good, fair, poor
  "lending_price_weekly": 50, // in rupees, 0 for free
  "visible_in_groups": ["grp_9x8y7z6w", "grp_5t6y7u8i"],
  "personal_notes": "Excellent condition, hardcover edition",
  "is_available": true
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "book": {
      "id": "book_4f5g6h7j",
      "title": "The Pragmatic Programmer",
      "author": "David Thomas, Andrew Hunt",
      "cover_image": "https://cdn.bookshare.app/books/...",
      "genre": "Technology",
      "condition": "like_new",
      "lending_price_weekly": 50,
      "visible_in_groups": ["grp_9x8y7z6w", "grp_5t6y7u8i"],
      "owner": {
        "id": "usr_1a2b3c4d",
        "name": "John Doe",
        "profile_image": "https://cdn.bookshare.app/users/..."
      },
      "status": "available", // available, lent, unavailable
      "created_at": "2025-01-15T14:00:00Z"
    }
  }
}
```

### 3.3 Get Books Feed (Home Screen)
```http
GET /books/feed?groups=grp_9x8y7z6w,grp_5t6y7u8i&availability=available&genre=Technology&sort=recent&page=1&limit=20
```

**Query Parameters:**
- `groups`: Comma-separated group IDs (empty = all user's groups)
- `availability`: available, lent, all
- `genre`: Filter by genre
- `price`: free, paid, or range (min-max)
- `sort`: recent, price_low, price_high, popular
- `search`: Search in title/author
- `page`, `limit`: Pagination

**Response (200):**
```json
{
  "success": true,
  "data": {
    "books": [
      {
        "id": "book_4f5g6h7j",
        "title": "The Pragmatic Programmer",
        "author": "David Thomas, Andrew Hunt",
        "cover_image": "https://cdn.bookshare.app/books/...",
        "genre": "Technology",
        "condition": "like_new",
        "lending_price_weekly": 50,
        "owner": {
          "id": "usr_1a2b3c4d",
          "name": "John Doe",
          "profile_image": "https://cdn.bookshare.app/users/...",
          "rating": 4.8,
          "books_shared": 12
        },
        "status": "available",
        "group": {
          "id": "grp_9x8y7z6w",
          "name": "Office Book Club"
        },
        "is_my_book": false,
        "created_at": "2025-01-15T14:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 94
    }
  }
}
```

### 3.4 Get Book Details
```http
GET /books/{book_id}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "book": {
      "id": "book_4f5g6h7j",
      "title": "The Pragmatic Programmer",
      "author": "David Thomas, Andrew Hunt",
      "cover_image": "https://cdn.bookshare.app/books/...",
      "genre": "Technology",
      "publisher": "Addison-Wesley",
      "year": 2019,
      "pages": 352,
      "language": "English",
      "isbn": "9780137081073",
      "condition": "like_new",
      "lending_price_weekly": 50,
      "personal_notes": "Excellent condition, hardcover edition",
      "visible_in_groups": [
        {
          "id": "grp_9x8y7z6w",
          "name": "Office Book Club"
        }
      ],
      "owner": {
        "id": "usr_1a2b3c4d",
        "name": "John Doe",
        "profile_image": "https://cdn.bookshare.app/users/...",
        "rating": 4.8,
        "books_shared": 12,
        "successful_lends": 45
      },
      "status": "available",
      "is_my_book": false,
      "current_transaction": null, // if lent, shows transaction details
      "created_at": "2025-01-15T14:00:00Z"
    }
  }
}
```

### 3.5 Update Book
```http
PATCH /books/{book_id}
```

**Request Body:** Same fields as Create Book (all optional)

### 3.6 Delete Book
```http
DELETE /books/{book_id}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Book deleted successfully"
}
```

### 3.7 Get My Books
```http
GET /books/my-library?status=all&page=1&limit=20
```

**Query Parameters:**
- `status`: all, available, lent, unavailable

**Response (200):**
```json
{
  "success": true,
  "data": {
    "books": [
      {
        "id": "book_4f5g6h7j",
        "title": "The Pragmatic Programmer",
        "cover_image": "https://cdn.bookshare.app/books/...",
        "status": "lent",
        "lending_price_weekly": 50,
        "visible_in_groups_count": 2,
        "visible_in_groups": ["Office Book Club", "Friends"],
        "current_transaction": {
          "id": "txn_8k9l0m1n",
          "borrower": {
            "id": "usr_5e6f7g8h",
            "name": "Jane Smith"
          },
          "borrowed_at": "2025-01-10T10:00:00Z",
          "due_date": "2025-01-24T10:00:00Z",
          "days_remaining": 9
        },
        "total_lends": 5,
        "total_earned": 250
      }
    ],
    "analytics": {
      "total_books": 8,
      "currently_lent": 2,
      "total_earned": 1450
    }
  }
}
```

---

## 4. Transaction/Borrowing APIs

### 4.1 Request to Borrow
```http
POST /transactions/request
```

**Request Body:**
```json
{
  "book_id": "book_4f5g6h7j",
  "duration_weeks": 2,
  "message": "Hi! I'd love to read this book for my project."
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Borrow request sent to John Doe",
  "data": {
    "transaction": {
      "id": "txn_8k9l0m1n",
      "book": {
        "id": "book_4f5g6h7j",
        "title": "The Pragmatic Programmer",
        "cover_image": "https://cdn.bookshare.app/books/..."
      },
      "borrower": {
        "id": "usr_5e6f7g8h",
        "name": "Jane Smith"
      },
      "owner": {
        "id": "usr_1a2b3c4d",
        "name": "John Doe"
      },
      "status": "pending", // pending, approved, active, returned, rejected
      "duration_weeks": 2,
      "lending_fee": 100,
      "message": "Hi! I'd love to read this book for my project.",
      "requested_at": "2025-01-15T15:00:00Z"
    }
  }
}
```

### 4.2 Approve/Reject Request (Owner)
```http
POST /transactions/{transaction_id}/respond
```

**Request Body:**
```json
{
  "action": "approve", // approve, reject
  "message": "Sure! Let's meet tomorrow at 3 PM." // optional
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Borrow request approved",
  "data": {
    "transaction": {
      "id": "txn_8k9l0m1n",
      "status": "approved",
      "owner_response": "Sure! Let's meet tomorrow at 3 PM.",
      "approved_at": "2025-01-15T15:30:00Z",
      "contacts_shared": true,
      "owner_contact": "+919876543210",
      "borrower_contact": "+918765432109",
      "handover_otp": null // generated on demand
    }
  }
}
```

### 4.3 Generate Handover OTP
```http
POST /transactions/{transaction_id}/generate-handover-otp
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "otp": "4521",
    "expires_at": "2025-01-15T16:10:00Z" // 10 minutes
  }
}
```

**Note:** 
- Borrower calls this API to get OTP to show owner
- OTP is also sent to owner via notification

### 4.4 Confirm Handover (Owner)
```http
POST /transactions/{transaction_id}/confirm-handover
```

**Request Body:**
```json
{
  "otp": "4521"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Book handover confirmed. Book is now lent out.",
  "data": {
    "transaction": {
      "id": "txn_8k9l0m1n",
      "status": "active",
      "borrowed_at": "2025-01-15T16:00:00Z",
      "due_date": "2025-01-29T16:00:00Z", // borrowed_at + duration_weeks
      "lending_fee": 100
    }
  }
}
```

**Side Effects:**
- Book status changes to "lent"
- Book becomes unavailable in all groups
- Notifications sent to both parties

### 4.5 Generate Return OTP
```http
POST /transactions/{transaction_id}/generate-return-otp
```

**Response (200):** Same format as handover OTP

### 4.6 Confirm Return (Borrower)
```http
POST /transactions/{transaction_id}/confirm-return
```

**Request Body:**
```json
{
  "otp": "8763"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Book return confirmed",
  "data": {
    "transaction": {
      "id": "txn_8k9l0m1n",
      "status": "returned",
      "returned_at": "2025-01-29T14:00:00Z",
      "was_on_time": true
    }
  }
}
```

**Side Effects:**
- Book status changes to "available"
- Book reappears in all visibility groups
- Rating/review prompt triggered

### 4.7 Rate Transaction
```http
POST /transactions/{transaction_id}/rate
```

**Request Body:**
```json
{
  "rating": 5, // 1-5
  "book_condition_rating": 5, // 1-5, owner rates condition on return
  "comment": "Great experience! Book was in perfect condition." // optional
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Thank you for your feedback"
}
```

### 4.8 Get My Transactions
```http
GET /transactions/me?role=borrower&status=active&page=1&limit=20
```

**Query Parameters:**
- `role`: borrower, owner, all
- `status`: pending, approved, active, returned, all

**Response (200):**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "id": "txn_8k9l0m1n",
        "book": {
          "id": "book_4f5g6h7j",
          "title": "The Pragmatic Programmer",
          "cover_image": "https://cdn.bookshare.app/books/..."
        },
        "other_party": {
          "id": "usr_1a2b3c4d",
          "name": "John Doe",
          "phone": "+919876543210"
        },
        "role": "borrower",
        "status": "active",
        "borrowed_at": "2025-01-10T10:00:00Z",
        "due_date": "2025-01-24T10:00:00Z",
        "days_remaining": 9,
        "is_overdue": false,
        "lending_fee": 100
      }
    ]
  }
}
```

### 4.9 Report Overdue (Owner)
```http
POST /transactions/{transaction_id}/report-overdue
```

**Response (200):**
```json
{
  "success": true,
  "message": "Overdue report sent. Borrower will receive urgent notifications."
}
```

---

## 5. Notification APIs

### 5.1 Get Notifications
```http
GET /notifications?status=unread&page=1&limit=20
```

**Query Parameters:**
- `status`: unread, read, all

**Response (200):**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "notif_2n3m4k5l",
        "type": "borrow_request", // borrow_request, request_approved, book_due, book_overdue, return_requested, etc.
        "title": "New borrow request",
        "message": "Jane Smith wants to borrow 'The Pragmatic Programmer'",
        "data": {
          "transaction_id": "txn_8k9l0m1n",
          "book_id": "book_4f5g6h7j",
          "user_id": "usr_5e6f7g8h"
        },
        "is_read": false,
        "created_at": "2025-01-15T15:00:00Z"
      }
    ],
    "unread_count": 5
  }
}
```

### 5.2 Mark as Read
```http
POST /notifications/{notification_id}/read
```

### 5.3 Mark All as Read
```http
POST /notifications/read-all
```

---

## 6. User Profile APIs

### 6.1 Get User Profile
```http
GET /users/{user_id}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "usr_1a2b3c4d",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+919876543210", // only visible if allowed by privacy settings
      "profile_image": "https://cdn.bookshare.app/users/...",
      "bio": "Tech enthusiast and avid reader",
      "rating": 4.8,
      "stats": {
        "books_shared": 12,
        "successful_lends": 45,
        "successful_borrows": 23,
        "total_earned": 2450
      },
      "badges": ["trusted_lender", "bookworm"],
      "member_since": "2024-06-10T08:00:00Z"
    }
  }
}
```

### 6.2 Update Profile
```http
PATCH /users/me
```

**Request Body:**
```json
{
  "name": "John Doe",
  "bio": "Tech enthusiast and avid reader",
  "profile_image": "data:image/jpeg;base64,..."
}
```

### 6.3 Update Settings
```http
PATCH /users/me/settings
```

**Request Body:**
```json
{
  "notifications": {
    "push_enabled": true,
    "email_enabled": false,
    "borrow_requests": true,
    "due_reminders": true,
    "group_activity": false
  },
  "privacy": {
    "phone_visibility": "after_approval" // after_approval, group_members, public
  }
}
```

---

## 7. Error Responses

All errors follow this format:

```json
{
  "success": false,
  "error": {
    "code": "BOOK_NOT_AVAILABLE",
    "message": "This book is currently lent out",
    "details": {
      "available_from": "2025-01-29T16:00:00Z"
    }
  }
}
```

### Common Error Codes:
- `UNAUTHORIZED` (401): Invalid or missing token
- `FORBIDDEN` (403): User doesn't have permission
- `NOT_FOUND` (404): Resource not found
- `VALIDATION_ERROR` (400): Invalid input
- `BOOK_NOT_AVAILABLE` (400): Book is lent or unavailable
- `ALREADY_MEMBER` (400): User already in group
- `INVALID_OTP` (400): OTP incorrect or expired
- `RATE_LIMIT_EXCEEDED` (429): Too many requests

---

## 8. Webhooks (For Admin/Analytics)

### Events:
- `user.registered`
- `group.created`
- `book.uploaded`
- `transaction.requested`
- `transaction.completed`
- `transaction.overdue`

**Payload Format:**
```json
{
  "event": "transaction.completed",
  "timestamp": "2025-01-29T14:00:00Z",
  "data": {
    "transaction_id": "txn_8k9l0m1n",
    "book_id": "book_4f5g6h7j",
    "borrower_id": "usr_5e6f7g8h",
    "owner_id": "usr_1a2b3c4d",
    "lending_fee": 100
  }
}
```

---

## 9. Rate Limiting

- Authentication endpoints: 5 requests/minute per IP
- All other endpoints: 100 requests/minute per user
- Exceeded: Returns 429 with `Retry-After` header

---

## 10. Pagination

All list endpoints support pagination:
- Default `limit`: 20
- Max `limit`: 100
- Response includes `pagination` object with `current_page`, `total_pages`, `total_count`