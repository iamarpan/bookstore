# Vercel Environment Variables Configuration

## Required Environment Variables

Add these to your Vercel project settings:

### DATABASE_URL (Connection Pooling - for queries)
```
postgresql://postgres.iyffnwujmbwdeqvqkgqe:FVu9%268b9kDqGP8%2A@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1
```

**Key points:**
- Uses port **6543** (Supabase pooler)
- Includes `?pgbouncer=true` to disable prepared statements
- Includes `connection_limit=1` for serverless (each Lambda gets 1 connection)

### DIRECT_URL (Direct Connection - for migrations)
```
postgresql://postgres.iyffnwujmbwdeqvqkgqe:FVu9%268b9kDqGP8%2A@aws-1-ap-south-1.pooler.supabase.com:5432/postgres
```

**Key points:**
- Uses port **5432** (direct PostgreSQL connection)
- No `pgbouncer=true` parameter
- Used only for migrations, not runtime queries

## How to Add to Vercel

1. Go to your Vercel project dashboard
2. Navigate to **Settings** → **Environment Variables**
3. Add both variables:
   - `DATABASE_URL` with the pooler URL
   - `DIRECT_URL` with the direct URL
4. Apply to **Production**, **Preview**, and **Development** environments
5. Redeploy the application

## Why This Fixes the Error

The "prepared statement already exists" error occurs because:
- Serverless functions reuse execution contexts
- PostgreSQL prepared statements persist across invocations
- Adding `?pgbouncer=true` disables prepared statements
- Using `connection_limit=1` ensures proper connection management

## Testing

After deployment, test the OTP flow:
```bash
./test-production.sh
```

The OTP verification should now work without errors.
