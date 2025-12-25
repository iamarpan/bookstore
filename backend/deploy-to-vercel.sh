#!/bin/bash

# Supabase + Vercel Deployment Script
# This script helps set up environment variables in Vercel for deployment

echo "🚀 Bookstore Backend - Vercel Deployment Helper"
echo "================================================"
echo ""

# Check if vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI not found. Installing..."
    npm install -g vercel
fi

echo "📝 Setting up Vercel environment variables..."
echo ""

# Supabase Database URL (using pooled connection for better performance)
echo "Setting DATABASE_URL..."
vercel env add DATABASE_URL production << EOF
postgresql://postgres.iyffnwujmbwdeqvqkgqe:FVu9%268b9kDqGP8%2A@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require
EOF


# JWT Access Secret
echo "Setting JWT_ACCESS_SECRET..."
vercel env add JWT_ACCESS_SECRET production << EOF
3e057ebae69f8c01b9f1899c5886d836f56925c734b504df179d9577ca01f386917d138da93d05c9e8f42252843fa413465880bb6c9fe6872d9fcda5134eda7e
EOF

# JWT Refresh Secret
echo "Setting JWT_REFRESH_SECRET..."
vercel env add JWT_REFRESH_SECRET production << EOF
403c7ac7915df2a493f7c877b353dc0efb61dd824120249ed093febc3a66385881c705dde1f7dbc264cfefe42676ef5a1617defbc98494342e3a8d4234ef52c4
EOF

# JWT Access Expiry
echo "Setting JWT_ACCESS_EXPIRY..."
vercel env add JWT_ACCESS_EXPIRY production << EOF
15m
EOF

# JWT Refresh Expiry
echo "Setting JWT_REFRESH_EXPIRY..."
vercel env add JWT_REFRESH_EXPIRY production << EOF
7d
EOF

# OTP Expiry Minutes
echo "Setting OTP_EXPIRY_MINUTES..."
vercel env add OTP_EXPIRY_MINUTES production << EOF
5
EOF

echo ""
echo "✅ All environment variables have been set!"
echo ""
echo "Next steps:"
echo "1. Run: vercel link (to link your project)"
echo "2. Run: vercel --prod (to deploy)"
echo ""
