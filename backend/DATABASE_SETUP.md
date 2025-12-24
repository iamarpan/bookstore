# Database Setup Guide

## Prerequisites

Make sure you have PostgreSQL installed and running.

### Install PostgreSQL on macOS

```bash
# Using Homebrew
brew install postgresql@15
brew services start postgresql@15
```

## Configuration

1. **Create Database:**

```bash
# Connect to PostgreSQL
psql postgres

# Create database
CREATE DATABASE bookstore_dev;

# Create user (optional)
CREATE USER bookstore_user WITH PASSWORD 'bookstore_pass';
GRANT ALL PRIVILEGES ON DATABASE bookstore_dev TO bookstore_user;

# Exit
\q
```

2. **Update .env file:**

The `.env` file should already exist with the correct `DATABASE_URL`. If not, copy from `.env.example` and update:

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/bookstore_dev?schema=public"
```

Or if you created a custom user:

```env
DATABASE_URL="postgresql://bookstore_user:bookstore_pass@localhost:5432/bookstore_dev?schema=public"
```

## Running Migrations

```bash
# Generate Prisma Client (already done)
npm run prisma:generate

# Create and run migrations
npm run prisma:migrate

# Name your migration when prompted, e.g., "init"
```

## Seeding the Database

```bash
# Run seed script
npm run prisma:seed
```

This will create:
- 3 demo users
- 1 demo group (Office Book Club)
- 3 demo books
- Group memberships

## Prisma Studio

To view and edit your database with a GUI:

```bash
npm run prisma:studio
```

This will open Prisma Studio at http://localhost:5555

## Common Commands

```bash
# Generate Prisma Client after schema changes
npx prisma generate

# Create a new migration
npx prisma migrate dev --name migration_name

# Reset database (WARNING: deletes all data)
npx prisma migrate reset

# Format schema file
npx prisma format
```

## Database Schema

The schema includes:

- **users** - User accounts with phone authentication
- **books** - Book catalog
- **groups** - Book sharing groups
- **group_members** - Group membership
- **book_groups** - Books visible in groups
- **transactions** - Borrowing transactions
- **notifications** - User notifications
- **otp_codes** - OTP verification codes
- **refresh_tokens** - JWT refresh tokens

## Testing Connection

You can test the database connection by running:

```bash
npm run dev
```

Then visit: http://localhost:3000/health

If you see `{"status":"ok",...}`, the server is running (database connection will be tested when you make API calls).
