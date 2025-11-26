# AI Development Playbook - Ready-to-Use Prompts

## 🤖 How to Use This Playbook

Copy these prompts directly into ChatGPT, Claude, or Cursor IDE. Each prompt is optimized for AI code generation. Always review and test the generated code.

---

## Week 1: Backend Setup

### Prompt 1: Project Structure
```
I'm building a book-sharing platform using Node.js, Express, PostgreSQL, and Redis. 
Create a professional project structure with:
- Separate folders for routes, controllers, models, services, middleware, utils
- Environment configuration
- Database connection setup
- Error handling middleware
- Request validation middleware
- Logger setup (Winston)

Include package.json with all necessary dependencies.
```

### Prompt 2: Database Schema
```
Create a PostgreSQL schema for a book-sharing app with these tables:
1. users (id, name, email, phone, password_hash, profile_image, is_verified, created_at)
2. groups (id, name, description, category, privacy, invite_code, created_by, created_at)
3. group_memberships (id, group_id, user_id, role, status, joined_at)
4. books (id, owner_id, title, author, cover_image, genre, condition, lending_price_weekly, status)
5. book_group_visibility (id, book_id, group_id)
6. transactions (id, book_id, borrower_id, owner_id, status, duration_weeks, lending_fee, borrowed_at, due_date, returned_at)
7. notifications (id, user_id, type, title, message, is_read, created_at)

Include:
- Primary keys, foreign keys with CASCADE
- Indexes for performance
- Timestamp columns
- Status enums
```

### Prompt 3: User Model (Sequelize)
```
Create a Sequelize model for the users table with:
- All fields from the schema
- Password hashing using bcrypt before save
- Method to compare passwords
- Method to generate JWT token
- Hide password in JSON serialization
- Associations with groups and books
```

---

## Week 2: Authentication

### Prompt 4: Registration API
```
Create an Express.js registration endpoint with:
- POST /auth/register
- Validate: name, email, phone, password
- Hash password with bcrypt
- Generate 4-digit OTP and store in Redis (10 min expiry)
- Send OTP via Twilio
- Return user_id and verification_required flag
- Handle duplicate email/phone errors
- Include unit tests

Use async/await and proper error handling.
```

### Prompt 5: JWT Authentication
```
Create JWT authentication middleware for Express.js with:
- Generate access token (24h expiry) and refresh token (30d expiry)
- Middleware to verify JWT from Authorization header
- Endpoint to refresh access token
- Store refresh tokens in PostgreSQL with expiry
- Blacklist mechanism for logout
- Include rate limiting for auth endpoints
```

### Prompt 6: OTP Verification
```
Create an OTP verification service with:
- Function to generate 4-digit OTP
- Store in Redis with key format: otp:phone:{number}
- 10-minute expiry
- Function to verify OTP
- Delete OTP after successful verification
- Rate limiting: max 5 attempts per phone
- Send SMS via Twilio API
- Handle errors (expired, invalid, rate limit)
```

---

## Week 3: Group & Book APIs

### Prompt 7: Group CRUD
```
Create Express.js endpoints for group management:
1. POST /groups - Create group
   - Validate name, description, category, privacy
   - Generate unique invite_code
   - Set creator as admin
   - Upload cover image to AWS S3

2. GET /groups/me - Get user's groups
   - Include role, members_count, books_count

3. POST /groups/:id/join - Join group
   - Check invite_code if private
   - Create membership with status 'active'

4. GET /groups/:id - Get group details
   - Include members, stats

Include authorization checks (only admins can update/delete).
```

### Prompt 8: Book Upload with ISBN
```
Create a book upload service with:
1. Function to lookup book by ISBN using Google Books API
   - Fallback to Open Library API
   - Return: title, author, cover, genre, publisher, year

2. POST /books endpoint:
   - Accept manual entry or ISBN
   - Upload cover image to S3 if provided
   - Validate required fields
   - Create book_group_visibility entries
   - Set status as 'available'

3. Include image optimization (resize to 800x1200, compress)
```

### Prompt 9: Book Feed Query
```
Create an optimized SQL query for book feed with:
- Get all books from user's joined groups
- Filters: group_ids, availability, genre, price range
- Search: title/author full-text search
- Sort: recent, price_low, price_high
- Pagination (limit, offset)
- Join with users for owner info
- Include owner rating from user_stats
- Mark is_my_book if owner is current user

Return as Sequelize query with eager loading.
```

---

## Week 4: Transaction System

### Prompt 10: Borrow Request
```
Create borrow request workflow:
1. POST /transactions/request
   - Validate book availability (not lent, not unavailable)
   - Create transaction with status 'pending'
   - Send push notification to owner
   - Return transaction details

2. POST /transactions/:id/respond
   - Owner can approve/reject
   - If approved: share contact info, generate handover OTP
   - Update status accordingly
   - Send notifications

Include validation and state machine logic.
```

### Prompt 11: OTP Handover System
```
Create handover confirmation system:
1. POST /transactions/:id/generate-handover-otp
   - Generate 4-digit OTP
   - Store in Redis: otp:{txn_id}:handover (10 min expiry)
   - Return OTP to borrower
   - Send notification to owner

2. POST /transactions/:id/confirm-handover
   - Owner enters OTP
   - Verify OTP from Redis
   - Update transaction: status='active', borrowed_at=now, due_date=calculated
   - Update book: status='lent', current_transaction_id=txn_id
   - Delete OTP
   - Send confirmation notifications

Include comprehensive error handling.
```

### Prompt 12: Transaction State Machine
```
Create a transaction state machine with:
- States: pending, approved, active, returned, rejected, cancelled
- Allowed transitions map
- Function to validate state transitions
- Side effects for each state change:
  - active: mark book as lent
  - returned: mark book as available, check if on_time
  - rejected: send notification
- Trigger notifications on state changes
- Update user stats (successful_lends, etc.)

Use TypeScript for type safety.
```

---

## Week 5: Mobile App Setup

### Prompt 13: React Native Navigation
```
Create React Native navigation structure using React Navigation v6 with:
1. Auth Stack (Welcome, Login, Register, OTP)
2. Main App (Bottom Tab Navigator):
   - Home Tab (Stack: Home, BookDetails, GroupDetails, UserProfile)
   - Groups Tab (Stack: MyGroups, DiscoverGroups, CreateGroup)
   - Library Tab (Stack: MyLibrary with 3 sub-tabs, AddBook, EditBook, TransactionDetails)
   - Notifications Tab
   - Profile Tab (Stack: Profile, Settings, EditProfile)

Include TypeScript types and proper deep linking setup.
```

### Prompt 14: API Service Layer
```
Create an Axios-based API service for React Native with:
- Base URL configuration
- Request interceptor: add JWT token from AsyncStorage
- Response interceptor: handle 401 (refresh token), network errors
- Methods for all API endpoints (auth, books, groups, transactions)
- TypeScript interfaces for request/response types
- Error handling and logging
- Retry logic for failed requests
```

### Prompt 15: Redux Toolkit Setup
```
Set up Redux Toolkit for React Native with slices for:
1. auth (user, token, isAuthenticated)
2. books (items, loading, filters, pagination)
3. groups (myGroups, discoverGroups, selectedGroup)
4. transactions (myTransactions, activeTransactions)
5. notifications (items, unreadCount)

Include:
- Async thunks for API calls
- Selectors
- Persist configuration (redux-persist with AsyncStorage)
- TypeScript types
```

---

## Week 6: Core Screens

### Prompt 16: Book Card Component (v0.dev)
```
Create a React Native book card component with:
- Book cover image (placeholder if missing)
- Title (2 lines, ellipsis)
- Author
- Owner name with small avatar
- Price badge (₹50/week)
- Status badge (Available/Lent) with color coding
- Touchable with onPress handler
- Responsive layout (works in grid and list)

Use Tailwind CSS (NativeWind). Make it beautiful and modern.
```

### Prompt 17: Filter Modal (v0.dev)
```
Create a React Native bottom sheet filter modal with:
- Availability radio buttons (Available, Lent, All)
- Genre multi-select chips (scrollable)
- Price range slider (₹0 to ₹500)
- Sort by dropdown (Recent, Price Low-High, Popular)
- Reset and Apply buttons
- Smooth animations

Use react-native-bottom-sheet and NativeWind. Modern, iOS-like design.
```

### Prompt 18: Home Screen with Filters
```
Create React Native Home screen with:
- Search bar (sticky header)
- Horizontal scrollable group filter chips
- Filter button (opens modal)
- Book grid (2 columns) with FlatList
- Pull-to-refresh
- Infinite scroll pagination
- Loading skeletons
- Empty state
- Connect to Redux for books and filters

Include optimizations (useMemo, useCallback).
```

---

## Week 7: Complex Flows

### Prompt 19: Camera QR Scanner
```
Create React Native QR scanner screen using react-native-camera:
- Full-screen camera view
- Overlay with scan area
- Detect EAN13 barcodes
- On scan: call /books/scan API with ISBN
- Show loading state
- Navigate to book details with pre-filled data
- Handle errors (book not found)
- Include flashlight toggle

Support both iOS and Android.
```

### Prompt 20: OTP Input Component
```
Create a React Native OTP input component with:
- 4 separate boxes for each digit
- Auto-focus next box on input
- Auto-submit on 4th digit
- Paste support (auto-fill all boxes)
- Backspace to previous box
- Large, centered digits
- Copy-to-clipboard button (for showing OTP)
- Responsive design

Use NativeWind for styling. Include animations.
```

### Prompt 21: Transaction Detail Screen
```
Create Transaction Detail screen showing:
- Book info card (cover, title, author)
- Transaction status timeline (requested, approved, active, returned)
- Other party info (avatar, name, rating, phone with call button)
- Due date with countdown (days remaining)
- Action buttons based on role and status:
  - Borrower: "Generate Handover OTP", "Arrange Return"
  - Owner: "Enter Handover OTP", "Generate Return OTP"
- Overdue warning (if past due date)

Connect to Redux, handle all states.
```

---

## Week 8: Notifications & Polish

### Prompt 22: Firebase Push Notifications
```
Set up Firebase Cloud Messaging in React Native with:
1. FCM token retrieval on app start
2. Send token to backend (/users/me/device)
3. Foreground notification handler (show in-app banner)
4. Background notification handler
5. Notification tap handler (navigate to relevant screen)
6. Permission request (iOS)
7. Token refresh listener

Include both iOS and Android configurations.
```

### Prompt 23: Notification Screen
```
Create Notification screen with:
- List of notifications (FlatList)
- Notification cards: icon, title, message, timestamp
- Unread indicator (bold, colored dot)
- Tap to mark as read and navigate
- Mark all as read button
- Empty state
- Pull-to-refresh
- Group by date (Today, Yesterday, Earlier)

Connect to Redux for notifications state.
```

### Prompt 24: Profile Screen with Stats
```
Create Profile screen with:
- Large profile picture (editable)
- Name, rating (stars), member since
- Stats cards in grid:
  - Books Shared
  - Successful Lends
  - Books Borrowed
  - Total Earned (₹)
- Badges section (icons with labels)
- Menu items: Edit Profile, Settings, Help, Logout
- Smooth animations

Use NativeWind, make it visually appealing.
```

---

## Testing & Debugging Prompts

### Prompt 25: Unit Tests
```
Generate Jest unit tests for:
1. OTP generation and verification functions
2. Transaction state machine logic
3. Book availability check
4. JWT token generation and verification
5. Input validation functions

Include mocking for Redis, database, external APIs.
Aim for >80% code coverage.
```

### Prompt 26: Integration Tests
```
Create integration tests for the complete borrow-return flow:
1. User A creates a group
2. User B joins the group
3. User A uploads a book
4. User B requests to borrow
5. User A approves
6. Handover OTP flow
7. Book marked as lent
8. Return OTP flow
9. Book marked as available
10. Verify all database states

Use Supertest for API testing.
```

### Prompt 27: Error Handling
```
Add comprehensive error handling to all API endpoints:
- Try-catch blocks for async operations
- Validation errors (400)
- Authentication errors (401)
- Authorization errors (403)
- Not found errors (404)
- Rate limit errors (429)
- Server errors (500)
- Custom error classes
- Error logging (Winston)
- User-friendly error messages

Create a global error handler middleware.
```

---

## Optimization Prompts

### Prompt 28: Database Optimization
```
Optimize the book feed query:
1. Add composite indexes on (status, created_at)
2. Create materialized view for user stats
3. Implement Redis caching for:
   - User's groups (1 hour TTL)
   - Book feed (5 min TTL)
   - User profile (30 min TTL)
4. Use database connection pooling
5. Add query explain analysis

Provide migration scripts for indexes.
```

### Prompt 29: Mobile Performance
```
Optimize React Native app performance:
1. Implement FlatList optimization (getItemLayout, keyExtractor)
2. Use React.memo for expensive components
3. Debounce search input
4. Lazy load images with react-native-fast-image
5. Reduce bundle size (analyze with react-native-bundle-visualizer)
6. Optimize Redux selectors (reselect)
7. Use Hermes engine (Android)
8. Code splitting for large screens

Provide before/after metrics.
```

### Prompt 30: API Rate Limiting
```
Implement rate limiting using Redis:
- General API: 100 req/min per user
- Auth endpoints: 5 req/min per IP
- OTP generation: 3 req/5min per phone
- File uploads: 10 req/hour per user

Use express-rate-limit with Redis store.
Include custom error messages and retry-after headers.
```

---

## DevOps & Deployment Prompts

### Prompt 31: Dockerfile
```
Create production-ready Dockerfile for Node.js API:
- Multi-stage build (build + production)
- Use Node 18 Alpine
- Install only production dependencies
- Non-root user
- Health check endpoint
- Expose port 3000
- Optimize for small image size

Include docker-compose.yml with PostgreSQL, Redis, API.
```

### Prompt 32: CI/CD Pipeline
```
Create GitHub Actions workflow for:
1. Run tests on every PR
2. Build Docker image on merge to main
3. Push to Docker Hub
4. Deploy to AWS ECS/Railway
5. Run database migrations
6. Send Slack notification on deploy

Include separate workflows for staging and production.
```

### Prompt 33: Environment Configuration
```
Create environment configuration system with:
- .env files for different environments (dev, staging, prod)
- Validation for required env variables
- Secrets management (AWS Secrets Manager)
- Configuration for:
  - Database URLs
  - Redis URL
  - JWT secret
  - AWS credentials
  - Twilio credentials
  - Firebase credentials
- Load configs based on NODE_ENV

Include .env.example template.
```

---

## Marketing & Analytics Prompts

### Prompt 34: App Store Description
```
Write an engaging App Store description for our book-sharing app:
- Hook (first 2 lines)
- Key features (5-6 bullet points)
- How it works (3 simple steps)
- Benefits (save money, build community, eco-friendly)
- Call to action
- Keywords for ASO

Create versions for both Google Play and Apple App Store.
Keep it under 4000 characters.
```

### Prompt 35: Social Media Posts
```
Create 10 Instagram post ideas for pre-launch campaign:
- Product teasers
- Feature highlights
- User stories (fictional but relatable)
- Book recommendations
- Community building
- Launch countdown
- Behind-the-scenes

Include captions, hashtags, and visual suggestions.
Target: Hyderabad book lovers aged 18-35.
```

### Prompt 36: Analytics Events
```
Define Firebase Analytics events to track:
- User actions: book_uploaded, borrow_requested, transaction_completed
- Screens: screen_view with screen_name parameter
- Errors: api_error, app_crash
- Business metrics: revenue_from_transaction
- Engagement: time_on_screen, books_browsed

Create a tracking plan with event names, parameters, and when to trigger.
Include implementation code for React Native.
```

---

## Quick Reference: Copy-Paste Prompts

### Express.js Controller Template
```
Create an Express.js controller for [FEATURE] with:
- GET /[endpoint] - List with pagination
- GET /[endpoint]/:id - Get by ID
- POST /[endpoint] - Create
- PATCH /[endpoint]/:id - Update
- DELETE /[endpoint]/:id - Delete (soft delete)

Include:
- Input validation using Joi
- Authorization checks
- Error handling
- Swagger documentation comments
- Unit tests
```

### React Native Screen Template
```
Create a React Native screen for [SCREEN_NAME] with:
- TypeScript
- Functional component with hooks
- Connected to Redux
- Loading state
- Error handling
- Empty state
- Pull-to-refresh
- Navigation props typed
- NativeWind styling
- Responsive design
```

---

## 🎯 Pro Tips for AI-Assisted Development

1. **Be Specific:** Include tech stack, libraries, patterns in every prompt
2. **Iterate:** If result isn't perfect, refine the prompt and regenerate
3. **Review Code:** AI makes mistakes - always review and test
4. **Context Matters:** Provide existing code structure for consistency
5. **Use Comments:** Add // TODO comments for AI to fill in
6. **Test Everything:** AI-generated tests are a great starting point
7. **Keep Prompts:** Save successful prompts for similar tasks
8. **Combine Tools:** Use Claude for architecture, Copilot for completion, v0 for UI

---

## 📚 Recommended AI Tools

### For Backend:
- **Cursor IDE** - Best for full-file generation
- **GitHub Copilot** - Best for line completion
- **ChatGPT/Claude** - Best for architecture decisions

### For Mobile:
- **v0.dev** - Best for React components
- **Cursor IDE** - Best for Flutter/React Native
- **GitHub Copilot** - Best for auto-completion

### For Design:
- **Figma AI plugins** - Best for design automation
- **Midjourney** - Best for custom icons/graphics
- **ChatGPT** - Best for copywriting

---

**You're now equipped with 36 ready-to-use prompts! Start building! 🚀**