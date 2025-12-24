# Vercel Deployment Guide

## Prerequisites

1. **Vercel Account**: Sign up at [vercel.com](https://vercel.com)
2. **Database**: Set up Vercel Postgres or Supabase
3. **Git Repository**: Code should be in GitHub/GitLab/Bitbucket

---

## Step 1: Install Vercel CLI

```bash
npm install -g vercel
```

## Step 2: Login to Vercel

```bash
vercel login
```

Follow the prompts to authenticate.

---

## Step 3: Set Up Production Database

### Option A: Vercel Postgres (Recommended)

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click on **Storage** tab
3. Click **Create Database**
4. Select **Postgres**
5. Choose a region close to your users
6. Copy the connection string

**Environment Variables Provided:**
- `POSTGRES_URL` (with pooling)
- `POSTGRES_URL_NON_POOLING` (for migrations)

### Option B: Supabase (Free Tier)

1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Go to **Settings** > **Database**
4. Copy the **Connection String** (Transaction mode)
5. Add `?pgbouncer=true` for connection pooling

---

## Step 4: Generate JWT Secrets

Run this command to generate secure random secrets:

```bash
# Generate ACCESS_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Generate REFRESH_SECRET  
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

Copy both values - you'll need them for environment variables.

---

## Step 5: Configure Environment Variables in Vercel

### Method 1: Vercel Dashboard

1. Go to your project in Vercel Dashboard
2. Go to **Settings** > **Environment Variables**
3. Add the following variables:

**Required:**
```
NODE_ENV=production
DATABASE_URL=<your_postgres_connection_string>
JWT_ACCESS_SECRET=<generated_secret_1>
JWT_REFRESH_SECRET=<generated_secret_2>
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d
OTP_EXPIRY_MINUTES=5
```

**For Vercel Postgres (if using):**
Vercel automatically sets `POSTGRES_URL` and `POSTGRES_URL_NON_POOLING`

### Method 2: Vercel CLI

```bash
vercel env add DATABASE_URL production
vercel env add JWT_ACCESS_SECRET production
vercel env add JWT_REFRESH_SECRET production
```

---

## Step 6: Link Local Project to Vercel

In your backend directory:

```bash
cd /Users/ayushyachitransh/development/bookstore/backend
vercel link
```

Follow the prompts:
- Link to existing project or create new
- Select your account/team
- Enter project name: `bookstore-backend`

---

## Step 7: Deploy to Vercel

### Deploy to Production

```bash
vercel --prod
```

This will:
1. Build your TypeScript code
2. Run Prisma migrations (`vercel-build` script)
3. Deploy to production
4. Give you a production URL

### Preview Deployment (optional)

```bash
vercel
```

Creates a preview deployment for testing.

---

## Step 8: Run Database Migrations

If migrations don't run automatically:

```bash
# Set the DATABASE_URL locally for migration
export DATABASE_URL="your_production_database_url"

# Run migrations
npx prisma migrate deploy

# Optionally seed database
npx prisma db seed
```

Or use Vercel's migration script (already configured):
- Migrations run automatically on deployment via `vercel-build` script

---

## Step 9: Verify Deployment

### Check Deployment Status

1. Go to Vercel Dashboard
2. Check **Deployments** tab
3. Click on latest deployment
4. View build logs

### Test API Endpoints

```bash
# Your production URL (example)
export API_URL="https://bookstore-backend.vercel.app"

# Health check
curl $API_URL/health

# API info
curl $API_URL/api/v1

# API docs
open $API_URL/api-docs
```

---

## Step 10: Update iOS App

Update `APIConfiguration.swift`:

```swift
var currentEnvironment: APIEnvironment = .production

case .production:
    return "https://bookstore-backend.vercel.app/api/v1"
```

---

## Post-Deployment Checklist

- [ ] Verify health endpoint works
- [ ] Check API documentation loads
- [ ] Test authentication flow (send-otp, verify-otp)
- [ ] Test book endpoints
- [ ] Test user endpoints
- [ ] Monitor Vercel logs for errors
- [ ] Check database connections
- [ ] Test from iOS app

---

## Troubleshooting

### Issue: Cold Starts

**Symptoms:** First request takes 2-3 seconds  
**Solution:** This is normal for Vercel serverless functions. Consider:
- Upgrade to Vercel Pro for better performance
- Add a health check ping service

### Issue: Database Connection Errors

**Symptoms:** `Too many connections` or timeout errors  
**Solution:**
- Ensure you're using the pooled connection URL (`?pgbouncer=true`)
- Check Prisma connection pool settings
- Use `POSTGRES_URL` (with pooling) for app, `POSTGRES_URL_NON_POOLING` for migrations

### Issue: Environment Variables Not Working

**Solution:**
- Double-check variable names in Vercel Dashboard
- Ensure variables are set for "Production" environment
- Redeploy after adding variables

### Issue: Migration Fails

**Solution:**
```bash
# Use non-pooled URL for migrations
export DATABASE_URL="<POSTGRES_URL_NON_POOLING>"
npx prisma migrate deploy
```

### Issue: Build Fails

**Check:**
- TypeScript compilation errors
- Missing dependencies in package.json
- Prisma schema errors
- View build logs in Vercel Dashboard

---

## Monitoring & Logs

### View Logs

1. Vercel Dashboard > Your Project > Deployments
2. Click on a deployment
3. View **Runtime Logs**

### Key Metrics

- Function execution time
- Error rate
- Request count
- Cold start frequency

---

## Custom Domain (Optional)

1. Go to **Settings** > **Domains**
2. Add your custom domain
3. Configure DNS settings
4. Update iOS app URL

---

## Costs

**Vercel Hobby (Free):**
- 100GB bandwidth/month
- Serverless function execution
- Basic analytics

**Vercel Pro ($20/month):**
- Faster deployments
- Better performance
- Advanced analytics
- Team collaboration

**Database:**
- Vercel Postgres: ~$0.25/GB storage
- Supabase Free: 500MB database

---

## Quick Deploy Commands

```bash
# Full deployment flow
cd backend
vercel login
vercel link
vercel env add DATABASE_URL production
vercel env add JWT_ACCESS_SECRET production  
vercel env add JWT_REFRESH_SECRET production
vercel --prod

# View deployment
vercel logs

# Open in browser
vercel open
```

---

## Next Steps After Deployment

1. ✅ Get production URL
2. ✅ Test all endpoints
3. ✅ Update iOS app configuration
4. ✅ Test end-to-end with iOS app
5. 🔄 Add remaining features (Groups, Transactions, Notifications)
6. 🔄 Set up monitoring/alerts
7. 🔄 Add custom domain

**You're ready to deploy! 🚀**
