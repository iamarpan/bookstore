# Book Sharing App - Database Schema

## Technology Stack Recommendation
- **Database:** PostgreSQL (for relational data + JSONB support)
- **Cache:** Redis (for sessions, OTPs, rate limiting)
- **File Storage:** AWS S3 / Cloudinary (for images)
- **Search:** Elasticsearch (for book search - Phase 2)

---

## Schema Design

### 1. users
Primary user information and authentication.

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  profile_image TEXT, -- S3 URL
  bio TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL -- Soft delete
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = TRUE;
```

### 2. user_settings
User preferences and privacy settings.

```sql
CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  notifications JSONB DEFAULT '{
    "push_enabled": true,
    "email_enabled": false,
    "borrow_requests": true,
    "due_reminders": true,
    "group_activity": false
  }',
  privacy JSONB DEFAULT '{
    "phone_visibility": "after_approval"
  }',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. user_stats
Denormalized stats for performance (updated via triggers).

```sql
CREATE TABLE user_stats (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  books_shared INTEGER DEFAULT 0,
  successful_lends INTEGER DEFAULT 0,
  successful_borrows INTEGER DEFAULT 0,
  total_earned DECIMAL(10,2) DEFAULT 0,
  average_rating DECIMAL(3,2) DEFAULT 0,
  total_ratings INTEGER DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4. groups
Communities/libraries where books are shared.

```sql
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  category VARCHAR(50), -- office, friends, neighborhood, book_club, school
  privacy VARCHAR(20) NOT NULL DEFAULT 'private', -- public, private
  cover_image TEXT,
  rules TEXT,
  invite_code VARCHAR(50) UNIQUE NOT NULL, -- For invite links
  created_by UUID NOT NULL REFERENCES users(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_groups_category ON groups(category);
CREATE INDEX idx_groups_privacy ON groups(privacy);
CREATE INDEX idx_groups_invite_code ON groups(invite_code);
CREATE INDEX idx_groups_active ON groups(is_active) WHERE is_active = TRUE;
```

### 5. group_memberships
User-group relationships.

```sql
CREATE TABLE group_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL DEFAULT 'member', -- admin, moderator, member
  status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, pending, removed
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  removed_at TIMESTAMP NULL,
  UNIQUE(group_id, user_id)
);

CREATE INDEX idx_memberships_user ON group_memberships(user_id);
CREATE INDEX idx_memberships_group ON group_memberships(group_id);
CREATE INDEX idx_memberships_status ON group_memberships(status);
```

### 6. group_stats
Denormalized group statistics.

```sql
CREATE TABLE group_stats (
  group_id UUID PRIMARY KEY REFERENCES groups(id) ON DELETE CASCADE,
  members_count INTEGER DEFAULT 1,
  books_count INTEGER DEFAULT 0,
  active_transactions INTEGER DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 7. books
Book inventory owned by users.

```sql
CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  author VARCHAR(255) NOT NULL,
  cover_image TEXT,
  genre VARCHAR(100),
  publisher VARCHAR(255),
  year INTEGER,
  pages INTEGER,
  language VARCHAR(50) DEFAULT 'English',
  isbn VARCHAR(20),
  condition VARCHAR(20) NOT NULL, -- new, like_new, good, fair, poor
  lending_price_weekly DECIMAL(10,2) NOT NULL DEFAULT 0,
  personal_notes TEXT,
  is_available BOOLEAN DEFAULT TRUE,
  status VARCHAR(20) NOT NULL DEFAULT 'available', -- available, lent, unavailable
  current_transaction_id UUID NULL, -- For quick lookup
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_books_owner ON books(owner_id);
CREATE INDEX idx_books_status ON books(status);
CREATE INDEX idx_books_genre ON books(genre);
CREATE INDEX idx_books_isbn ON books(isbn);
CREATE INDEX idx_books_title ON books USING gin(to_tsvector('english', title)); -- Full-text search
CREATE INDEX idx_books_author ON books USING gin(to_tsvector('english', author));
```

### 8. book_group_visibility
Many-to-many: which groups can see which books.

```sql
CREATE TABLE book_group_visibility (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(book_id, group_id)
);

CREATE INDEX idx_visibility_book ON book_group_visibility(book_id);
CREATE INDEX idx_visibility_group ON book_group_visibility(group_id);
```

**Critical Constraint:** When a book is lent, it's unavailable in ALL groups it's visible in.

### 9. transactions
Borrowing/lending transactions.

```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE RESTRICT, -- Don't allow deleting books with active transactions
  borrower_id UUID NOT NULL REFERENCES users(id),
  owner_id UUID NOT NULL REFERENCES users(id),
  group_id UUID NOT NULL REFERENCES groups(id), -- Group where request was made
  status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, active, returned, rejected, cancelled
  duration_weeks INTEGER NOT NULL,
  lending_fee DECIMAL(10,2) NOT NULL,
  borrower_message TEXT,
  owner_response TEXT,
  
  -- Timeline
  requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  approved_at TIMESTAMP NULL,
  borrowed_at TIMESTAMP NULL, -- When handover confirmed
  due_date TIMESTAMP NULL, -- borrowed_at + duration
  returned_at TIMESTAMP NULL,
  
  -- OTPs (stored temporarily, expire in 10 mins)
  handover_otp VARCHAR(4) NULL,
  handover_otp_expires_at TIMESTAMP NULL,
  return_otp VARCHAR(4) NULL,
  return_otp_expires_at TIMESTAMP NULL,
  
  -- Flags
  is_overdue BOOLEAN DEFAULT FALSE,
  overdue_reported BOOLEAN DEFAULT FALSE,
  was_on_time BOOLEAN NULL, -- Set on return
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transactions_book ON transactions(book_id);
CREATE INDEX idx_transactions_borrower ON transactions(borrower_id);
CREATE INDEX idx_transactions_owner ON transactions(owner_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_due_date ON transactions(due_date) WHERE status = 'active';
```

### 10. transaction_ratings
Post-transaction feedback.

```sql
CREATE TABLE transaction_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  rater_id UUID NOT NULL REFERENCES users(id),
  rated_user_id UUID NOT NULL REFERENCES users(id),
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  book_condition_rating INTEGER NULL CHECK (book_condition_rating BETWEEN 1 AND 5), -- Only for owner rating borrower
  comment TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(transaction_id, rater_id) -- Each user can rate once per transaction
);

CREATE INDEX idx_ratings_transaction ON transaction_ratings(transaction_id);
CREATE INDEX idx_ratings_rated_user ON transaction_ratings(rated_user_id);
```

### 11. notifications
User notifications.

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL, -- borrow_request, request_approved, book_due, etc.
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  data JSONB, -- Additional context (IDs, etc.)
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created ON notifications(created_at);
```

### 12. user_badges
Gamification badges earned by users.

```sql
CREATE TABLE user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  badge_type VARCHAR(50) NOT NULL, -- trusted_lender, bookworm, early_adopter, etc.
  earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, badge_type)
);

CREATE INDEX idx_badges_user ON user_badges(user_id);
```

### 13. refresh_tokens
For JWT token management.

```sql
CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(500) UNIQUE NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  revoked_at TIMESTAMP NULL
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
```

---

## Redis Schema (for ephemeral data)

### OTP Storage
```
Key: otp:phone:{phone_number}
Value: {otp_code}
TTL: 300 seconds (5 minutes)
```

### Rate Limiting
```
Key: rate_limit:auth:{ip_address}
Value: {request_count}
TTL: 60 seconds
```

### Session Cache
```
Key: session:{user_id}
Value: {user_data_json}
TTL: 86400 seconds (24 hours)
```

---

## Database Triggers & Functions

### 1. Auto-update timestamps
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Repeat for other tables...
```

### 2. Update group stats on membership change
```sql
CREATE OR REPLACE FUNCTION update_group_members_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'active' THEN
    UPDATE group_stats SET members_count = members_count + 1 WHERE group_id = NEW.group_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.status = 'active' AND NEW.status != 'active' THEN
    UPDATE group_stats SET members_count = members_count - 1 WHERE group_id = NEW.group_id;
  ELSIF TG_OP = 'DELETE' AND OLD.status = 'active' THEN
    UPDATE group_stats SET members_count = members_count - 1 WHERE group_id = OLD.group_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER group_membership_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON group_memberships
FOR EACH ROW EXECUTE FUNCTION update_group_members_count();
```

### 3. Update book status when transaction changes
```sql
CREATE OR REPLACE FUNCTION update_book_status_on_transaction()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    -- When transaction becomes active (borrowed)
    IF NEW.status = 'active' AND OLD.status != 'active' THEN
      UPDATE books SET status = 'lent', current_transaction_id = NEW.id WHERE id = NEW.book_id;
    
    -- When transaction completes (returned)
    ELSIF NEW.status = 'returned' AND OLD.status = 'active' THEN
      UPDATE books SET status = 'available', current_transaction_id = NULL WHERE id = NEW.book_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER transaction_book_status_trigger
AFTER UPDATE ON transactions
FOR EACH ROW EXECUTE FUNCTION update_book_status_on_transaction();
```

### 4. Update user stats on transaction completion
```sql
CREATE OR REPLACE FUNCTION update_user_stats_on_transaction()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'returned' AND OLD.status = 'active' THEN
    -- Update owner stats
    UPDATE user_stats 
    SET successful_lends = successful_lends + 1,
        total_earned = total_earned + NEW.lending_fee
    WHERE user_id = NEW.owner_id;
    
    -- Update borrower stats
    UPDATE user_stats 
    SET successful_borrows = successful_borrows + 1
    WHERE user_id = NEW.borrower_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_stats_on_return
AFTER UPDATE ON transactions
FOR EACH ROW EXECUTE FUNCTION update_user_stats_on_transaction();
```

### 5. Update user rating on new rating
```sql
CREATE OR REPLACE FUNCTION update_user_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE user_stats
  SET 
    total_ratings = total_ratings + 1,
    average_rating = (
      SELECT AVG(rating) FROM transaction_ratings WHERE rated_user_id = NEW.rated_user_id
    )
  WHERE user_id = NEW.rated_user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER rating_stats_trigger
AFTER INSERT ON transaction_ratings
FOR EACH ROW EXECUTE FUNCTION update_user_rating();
```

---

## Critical Queries for Performance

### 1. Home Feed Query (Most Complex)
Get all available books from user's groups with filters.

```sql
SELECT 
  b.id, b.title, b.author, b.cover_image, b.genre, b.condition,
  b.lending_price_weekly, b.status,
  u.id as owner_id, u.name as owner_name, u.profile_image as owner_image,
  us.average_rating as owner_rating, us.books_shared,
  g.id as group_id, g.name as group_name,
  (b.owner_id = $current_user_id) as is_my_book
FROM books b
JOIN book_group_visibility bgv ON b.id = bgv.book_id
JOIN groups g ON bgv.group_id = g.id
JOIN group_memberships gm ON g.id = gm.group_id
JOIN users u ON b.owner_id = u.id
LEFT JOIN user_stats us ON u.id = us.user_id
WHERE 
  gm.user_id = $current_user_id
  AND gm.status = 'active'
  AND b.deleted_at IS NULL
  AND ($filter_groups IS NULL OR g.id = ANY($filter_groups))
  AND ($filter_status IS NULL OR b.status = $filter_status)
  AND ($filter_genre IS NULL OR b.genre = $filter_genre)
  AND ($search_query IS NULL OR 
    to_tsvector('english', b.title || ' ' || b.author) @@ plainto_tsquery('english', $search_query)
  )
ORDER BY b.created_at DESC
LIMIT $limit OFFSET $offset;
```

### 2. Check Book Global Availability
Before allowing borrow request, ensure book isn't lent anywhere.

```sql
SELECT 
  b.status,
  t.id as active_transaction_id,
  t.due_date
FROM books b
LEFT JOIN transactions t ON b.current_transaction_id = t.id
WHERE b.id = $book_id;
```

### 3. User's Transactions Dashboard
```sql
SELECT 
  t.id, t.status, t.borrowed_at, t.due_date, t.lending_fee,
  b.id as book_id, b.title, b.cover_image,
  CASE 
    WHEN t.owner_id = $user_id THEN u_borrower.id
    ELSE u_owner.id
  END as other_party_id,
  CASE 
    WHEN t.owner_id = $user_id THEN u_borrower.name
    ELSE u_owner.name
  END as other_party_name,
  CASE 
    WHEN t.owner_id = $user_id THEN u_borrower.phone
    ELSE u_owner.phone
  END as other_party_phone,
  CASE 
    WHEN t.owner_id = $user_id THEN 'owner'
    ELSE 'borrower'
  END as my_role,
  (EXTRACT(EPOCH FROM (t.due_date - CURRENT_TIMESTAMP)) / 86400)::INTEGER as days_remaining
FROM transactions t
JOIN books b ON t.book_id = b.id
JOIN users u_owner ON t.owner_id = u_owner.id
JOIN users u_borrower ON t.borrower_id = u_borrower.id
WHERE 
  (t.owner_id = $user_id OR t.borrower_id = $user_id)
  AND ($status_filter IS NULL OR t.status = $status_filter)
ORDER BY t.created_at DESC;
```

---

## Backup & Maintenance

### Daily Tasks
- Automated backup of PostgreSQL database
- Clear expired OTPs from Redis
- Archive old notifications (>30 days)

### Weekly Tasks
- Vacuum and analyze tables
- Check for overdue transactions and send reminders
- Generate analytics reports

### Monthly Tasks
- Archive completed transactions (>6 months old)
- Review and optimize slow queries
- Update user badges based on activity

---

## Data Retention Policy

- **Active Data:** Kept indefinitely
- **Completed Transactions:** Archived after 6 months
- **Deleted Accounts:** Personal data deleted after 30 days (transactions anonymized)
- **Notifications:** Deleted after 30 days
- **Logs:** Retained for 90 days