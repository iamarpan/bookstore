# Supabase + Vercel Deployment Configuration

## ✅ Generated Configuration

### JWT Secrets (Keep these safe!)

```
JWT_ACCESS_SECRET=3e057ebae69f8c01b9f1899c5886d836f56925c734b504df179d9577ca01f386917d138da93d05c9e8f42252843fa413465880bb6c9fe6872d9fcda5134eda7e

JWT_REFRESH_SECRET=403c7ac7915df2a493f7c877b353dc0efb61dd824120249ed093febc3a66385881c705dde1f7dbc264cfefe42676ef5a1617defbc98494342e3a8d4234ef52c4
```

---

## 🗄️ Supabase Database Configuration

**Your Database URL:**
```
postgresql://postgres:[YOUR-PASSWORD]@db.iyffnwujmbwdeqvqkgqe.supabase.co:5432/postgres
```

**⚠️ IMPORTANT:** You need to replace `[YOUR-PASSWORD]` with your actual Supabase password!

**For Production (with connection pooling):**
```
postgresql://postgres:YOUR_ACTUAL_PASSWORD@db.iyffnwujmbwdeqvqkgqe.supabase.co:5432/postgres?pgbouncer=true
```

### Where to find your Supabase password:
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Settings** > **Database**
4. Find **Connection String** section
5. Click **Connection Pooling** tab
6. Your password is shown there

---

## 📋 Vercel Environment Variables Setup

### Step 1: Login to Vercel

```bash
vercel login
```

### Step 2: Set Environment Variables

You have two options:

#### Option A: Via Vercel Dashboard (Recommended)

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select or create your project
3. Go to **Settings** > **Environment Variables**
4. Add these variables (one by one):

```
Variable Name: NODE_ENV
Value: production
Environment: Production

Variable Name: DATABASE_URL  
Value: postgresql://postgres:YOUR_ACTUAL_PASSWORD@db.iyffnwujmbwdeqvqkgqe.supabase.co:5432/postgres?pgbouncer=true
Environment: Production

Variable Name: JWT_ACCESS_SECRET
Value: 3e057ebae69f8c01b9f1899c5886d836f56925c734b504df179d9577ca01f386917d138da93d05c9e8f42252843fa413465880bb6c9fe6872d9fcda5134eda7e
Environment: Production

Variable Name: JWT_REFRESH_SECRET
Value: 403c7ac7915df2a493f7c877b353dc0efb61dd824120249ed093febc3a66385881c705dde1f7dbc264cfefe42676ef5a1617defbc98494342e3a8d4234ef52c4
Environment: Production

Variable Name: JWT_ACCESS_EXPIRY
Value: 15m
Environment: Production

Variable Name: JWT_REFRESH_EXPIRY
Value: 7d
Environment: Production

Variable Name: OTP_EXPIRY_MINUTES
Value: 5
Environment: Production
```

#### Option B: Via Vercel CLI

```bash
cd /Users/ayushyachitransh/development/bookstore/backend

# Set DATABASE_URL (replace YOUR_ACTUAL_PASSWORD)
vercel env add DATABASE_URL production
# When prompted, paste: postgresql://postgres:YOUR_ACTUAL_PASSWORD@db.iyffnwujmbwdeqvqkgqe.supabase.co:5432/postgres?pgbouncer=true

# Set JWT secrets
vercel env add JWT_ACCESS_SECRET production
# Paste: 3e057ebae69f8c01b9f1899c5886d836f56925c734b504df179d9577ca01f386917d138da93d05c9e8f42252843fa413465880bb6c9fe6872d9fcda5134eda7e

vercel env add JWT_REFRESH_SECRET production
# Paste: 403c7ac7915df2a493f7c877b353dc0efb61dd824120249ed093febc3a66385881c705dde1f7dbc264cfefe42676ef5a1617defbc98494342e3a8d4234ef52c4

# Set other variables
vercel env add JWT_ACCESS_EXPIRY production
# Value: 15m

vercel env add JWT_REFRESH_EXPIRY production
# Value: 7d

vercel env add OTP_EXPIRY_MINUTES production
# Value: 5
```

---

## 🚀 Deployment Steps

### 1. Initialize Vercel Project

```bash
cd /Users/ayushyachitransh/development/bookstore/backend
vercel link
```

Follow prompts:
- Create new project or link existing
- Project name: `bookstore-backend`

### 2. Run Database Migrations

**Before deploying, test database connection locally:**

```bash
# Create a temporary .env.production file for testing
echo 'DATABASE_URL=postgresql://postgres:YOUR_ACTUAL_PASSWORD@db.iyffnwujmbwdeqvqkgqe.supabase.co:5432/postgres?pgbouncer=true' > .env.test

# Load it and test migration
export $(cat .env.test | xargs)
npx prisma migrate deploy
```

### 3. Deploy to Vercel

```bash
vercel --prod
```

This will:
- Build your TypeScript code
- Run `vercel-build` script (Prisma generate + migrate)  
- Deploy to production
- Give you a production URL like: `https://bookstore-backend-xxx.vercel.app`

---

## ✅ Post-Deployment Checklist

### 1. Verify Deployment

```bash
# Get your deployment URL from Vercel output, then:
export API_URL="https://your-deployment-url.vercel.app"

# Test health endpoint
curl $API_URL/health

# Test API info
curl $API_URL/api/v1

# Test API docs (open in browser)
open $API_URL/api-docs
```

### 2. Test Authentication

```bash
# Send OTP
curl -X POST $API_URL/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+919876543210"}'

# Check Vercel logs for OTP (since Twilio is not configured)
```

### 3. Monitor Deployment

1. Go to Vercel Dashboard
2. Click on your deployment
3. Check **Runtime Logs** for any errors
4. Verify database connections

---

## 🔧 Troubleshooting

### Database Connection Issues

If you see connection errors:

1. **Verify the password** - Make sure you replaced `[YOUR-PASSWORD]`
2. **Check connection string format** - Should end with `?pgbouncer=true`
3. **Test locally first:**
   ```bash
   export DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@db.iyffnwujmbwdeqvqkgqe.supabase.co:5432/postgres"
   npx prisma db pull
   ```

### Migration Errors

If migrations fail during deployment:

```bash
# Use direct connection (without pgbouncer) for migrations
export DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@db.iyffnwujmbwdeqvqkgqe.supabase.co:5432/postgres"
npx prisma migrate deploy
```

Then add pgbouncer back for the app connection.

---

## 📱 Update iOS App

Once deployed successfully, update `APIConfiguration.swift`:

```swift
case .production:
    return "https://your-deployment-url.vercel.app/api/v1"
```

---

## 🎯 Quick Start Commands

```bash
# Step 1: Login
vercel login

# Step 2: Link project
cd /Users/ayushyachitransh/development/bookstore/backend
vercel link

# Step 3: Set environment variables (via dashboard or CLI)
# Use Vercel Dashboard or run:
# vercel env add DATABASE_URL production
# ... (repeat for all variables above)

# Step 4: Deploy
vercel --prod

# Step 5: Test
# Visit the URL provided by Vercel
```

---

**All secrets are generated and ready! Just replace YOUR_ACTUAL_PASSWORD and deploy! 🚀**
