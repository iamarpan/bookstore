# Bookstore Backend API

Backend API for the Bookstore iOS Application built with Node.js, Express, TypeScript, and PostgreSQL.

## Tech Stack

- **Runtime:** Node.js 18+
- **Framework:** Express.js
- **Language:** TypeScript
- **Database:** PostgreSQL
- **ORM:** Prisma
- **Authentication:** JWT + OTP (Twilio)

## Getting Started

### Prerequisites

- Node.js 18+ installed
- PostgreSQL database
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Set up the database:
```bash
npm run prisma:migrate
npm run prisma:generate
```

4. Start the development server:
```bash
npm run dev
```

The server will start on `http://localhost:3000`

## Available Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint
- `npm run format` - Format code with Prettier
- `npm run test` - Run tests
- `npm run prisma:migrate` - Run database migrations
- `npm run prisma:generate` - Generate Prisma Client
- `npm run prisma:studio` - Open Prisma Studio

## API Endpoints

Base URL: `/api/v1`

### Authentication
- `POST /auth/send-otp` - Send OTP to phone number
- `POST /auth/verify-otp` - Verify OTP and login/register
- `POST /auth/refresh` - Refresh access token

### Users
- `GET /users/me` - Get current user profile
- `PUT /users/me` - Update user profile
- `GET /users/me/books` - Get user's books

### Books
- `GET /books/feed` - Get books feed with filters
- `GET /books/:id` - Get book details
- `POST /books` - Create new book
- `PUT /books/:id` - Update book
- `DELETE /books/:id` - Delete book
- `POST /books/scan-isbn` - Lookup book by ISBN
- `POST /books/upload-image` - Upload book image

### Groups
- `GET /groups/my` - Get user's groups
- `GET /groups/discover` - Discover public groups
- `GET /groups/:id` - Get group details
- `POST /groups` - Create new group
- `POST /groups/:id/join` - Join a group
- `POST /groups/join-invite/:code` - Join via invite code
- `POST /groups/:id/leave` - Leave a group
- `POST /groups/:id/invite` - Generate invite link

### Transactions
- `GET /transactions/my` - Get user's transactions
- `POST /transactions/request` - Create borrow request
- `POST /transactions/:id/approve` - Approve request
- `POST /transactions/:id/reject` - Reject request
- `POST /transactions/:id/confirm-handover` - Confirm handover with OTP
- `POST /transactions/:id/confirm-return` - Confirm return with OTP
- `POST /transactions/:id/mark-payment` - Mark payment complete
- `POST /transactions/:id/rate` - Rate transaction

### Notifications
- `POST /notifications/register` - Register device token
- `GET /notifications` - Get notifications
- `PUT /notifications/:id/read` - Mark as read
- `PUT /notifications/mark-all-read` - Mark all as read
- `DELETE /notifications/:id` - Delete notification

## Project Structure

```
backend/
├── src/
│   ├── config/         # Configuration files
│   ├── controllers/    # Request handlers
│   ├── middleware/     # Custom middleware
│   ├── routes/         # Route definitions
│   ├── services/       # Business logic
│   ├── utils/          # Helper functions
│   ├── types/          # TypeScript types
│   ├── app.ts          # Express app setup
│   └── server.ts       # Server entry point
├── prisma/
│   ├── schema.prisma   # Database schema
│   └── migrations/     # Database migrations
└── tests/              # Test files
```

## Development

1. Make code changes
2. The dev server will auto-reload
3. Test your endpoints with Postman or curl
4. Run linter before committing: `npm run lint`

## License

ISC
