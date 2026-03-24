#!/bin/bash
# Vercel Environment Variables Setup Script
# Run this to set all environment variables at once

echo "🔧 Setting up Vercel environment variables..."
echo ""
echo "⚠️  You will be prompted to enter your Supabase password"
echo "    Get it from: Supabase Dashboard > Settings > Database"
echo ""
read -p "Enter your Supabase password: " SUPABASE_PASSWORD

# Set DATABASE_URL with password
echo "Setting DATABASE_URL..."
echo "postgresql://postgres:${SUPABASE_PASSWORD}@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=10" | vercel env add DATABASE_URL production

# Set JWT secrets
echo "Setting JWT_ACCESS_SECRET..."
echo "3e057ebae69f8c01b9f1899c5886d836f56925c734b504df179d9577ca01f386917d138da93d05c9e8f42252843fa413465880bb6c9fe6872d9fcda5134eda7e" | vercel env add JWT_ACCESS_SECRET production

echo "Setting JWT_REFRESH_SECRET..."
echo "403c7ac7915df2a493f7c877b353dc0efb61dd824120249ed093febc3a66385881c705dde1f7dbc264cfefe42676ef5a1617defbc98494342e3a8d4234ef52c4" | vercel env add JWT_REFRESH_SECRET production

# Set other env vars
echo "Setting JWT_ACCESS_EXPIRY..."
echo "15m" | vercel env add JWT_ACCESS_EXPIRY production

echo "Setting JWT_REFRESH_EXPIRY..."
echo "7d" | vercel env add JWT_REFRESH_EXPIRY production

echo "Setting OTP_EXPIRY_MINUTES..."
echo "5" | vercel env add OTP_EXPIRY_MINUTES production

echo ""
echo "✅ All environment variables set!"
echo "🚀 Ready to deploy with: vercel --prod"
