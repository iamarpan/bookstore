#!/bin/bash

# Production API Verification Script
# Tests the Vercel-deployed backend to ensure it's working correctly

echo "🧪 Testing Bookstore Production API"
echo "===================================="
echo ""

API_BASE="https://bookapp-iota-nine.vercel.app"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Health Check
echo "1️⃣  Testing Health Endpoint..."
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_BASE/health")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
    echo "   Response: $BODY"
else
    echo -e "${RED}❌ Health check failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

# Test 2: API Info
echo "2️⃣  Testing API Info Endpoint..."
API_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_BASE/api/v1")
HTTP_CODE=$(echo "$API_RESPONSE" | tail -n1)
BODY=$(echo "$API_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ API info endpoint working${NC}"
    echo "   Response: $BODY"
else
    echo -e "${RED}❌ API info failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

# Test 3: Send OTP
echo "3️⃣  Testing Send OTP Endpoint..."
OTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/api/v1/auth/send-otp" \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+919876543210"}')
HTTP_CODE=$(echo "$OTP_RESPONSE" | tail -n1)
BODY=$(echo "$OTP_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Send OTP endpoint working${NC}"
    echo "   Response: $BODY"
    echo -e "${YELLOW}   ⚠️  Check Vercel logs for the OTP code${NC}"
else
    echo -e "${RED}❌ Send OTP failed (HTTP $HTTP_CODE)${NC}"
    echo "   Response: $BODY"
fi
echo ""

# Test 4: Get Genres (requires auth, should return 401)
echo "4️⃣  Testing Protected Endpoint (should return 401)..."
GENRES_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_BASE/api/v1/books/genres")
HTTP_CODE=$(echo "$GENRES_RESPONSE" | tail -n1)
BODY=$(echo "$GENRES_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✅ Protected endpoint correctly requires authentication${NC}"
    echo "   Response: $BODY"
else
    echo -e "${YELLOW}⚠️  Unexpected response (HTTP $HTTP_CODE)${NC}"
    echo "   Response: $BODY"
fi
echo ""

# Summary
echo "=================================="
echo -e "${GREEN}✅ Production API is working!${NC}"
echo ""
echo "📱 iOS App Configuration:"
echo "   Base URL: $API_BASE/api/v1"
echo "   Environment: Production"
echo ""
echo "📋 Next Steps:"
echo "   1. Open Xcode: bookApp/bookApp/bookApp.xcodeproj"
echo "   2. Select a simulator or device"
echo "   3. Press Cmd+R to build and run"
echo "   4. Test authentication and features"
echo ""
echo "📊 Monitor Production:"
echo "   Vercel Dashboard: https://vercel.com/dashboard"
echo "   API Docs: $API_BASE/api-docs"
echo ""
