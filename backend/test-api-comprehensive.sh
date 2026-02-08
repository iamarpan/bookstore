#!/bin/bash

# Comprehensive API Testing Script for Mobile Team Handover
# Tests all backend endpoints on Vercel deployment

set -e

# Configuration
API_BASE="https://bookapp-ayushyachitranshs-projects.vercel.app/api/v1"
TEST_PHONE="+919876543210"
TEST_PHONE_2="+919876543211"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test results array
declare -a TEST_RESULTS

# Helper function to print section headers
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Helper function to test endpoint
test_endpoint() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local auth_token="$5"
    local expected_code="$6"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${YELLOW}Testing: $test_name${NC}"
    
    # Build curl command
    local curl_cmd="curl -s -w \"\n%{http_code}\" -X $method \"$API_BASE$endpoint\""
    curl_cmd="$curl_cmd -H \"Content-Type: application/json\""
    
    if [ -n "$auth_token" ]; then
        curl_cmd="$curl_cmd -H \"Authorization: Bearer $auth_token\""
    fi
    
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -d '$data'"
    fi
    
    # Execute request
    RESPONSE=$(eval $curl_cmd)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    # Check result
    if [ "$HTTP_CODE" = "$expected_code" ]; then
        echo -e "${GREEN}✅ PASS${NC} - HTTP $HTTP_CODE"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("✅ $test_name")
    else
        echo -e "${RED}❌ FAIL${NC} - Expected $expected_code, got $HTTP_CODE"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("❌ $test_name (Expected $expected_code, got $HTTP_CODE)")
    fi
    
    echo "Response: $BODY" | head -c 200
    echo ""
    echo ""
    
    # Return the body for further use
    echo "$BODY"
}

# Start testing
echo -e "${GREEN}🧪 Comprehensive Backend API Testing${NC}"
echo -e "${GREEN}=====================================${NC}"
echo "API Base: $API_BASE"
echo "Test Phone: $TEST_PHONE"
echo ""

# ============================================
# PHASE 1: HEALTH & INFO ENDPOINTS
# ============================================
print_header "PHASE 1: Health & Info Endpoints"

test_endpoint "Health Check" "GET" "/../health" "" "" "200" > /dev/null
test_endpoint "API Info" "GET" "" "" "" "200" > /dev/null

# ============================================
# PHASE 2: AUTHENTICATION FLOW
# ============================================
print_header "PHASE 2: Authentication Flow"

# Test 1: Send OTP
echo -e "${BLUE}📱 Test 1: Send OTP${NC}"
OTP_RESPONSE=$(test_endpoint "Send OTP" "POST" "/auth/send-otp" "{\"phoneNumber\": \"$TEST_PHONE\"}" "" "200")
echo -e "${YELLOW}⚠️  Check server logs for OTP code${NC}"
echo ""

# Test 2: Verify OTP with invalid code
echo -e "${BLUE}📱 Test 2: Verify OTP - Invalid Code${NC}"
test_endpoint "Verify OTP - Invalid" "POST" "/auth/verify-otp" "{\"phoneNumber\": \"$TEST_PHONE\", \"otp\": \"000000\"}" "" "401" > /dev/null

# Test 3: Verify OTP - Missing name for new user
echo -e "${BLUE}📱 Test 3: Verify OTP - Missing Name${NC}"
echo -e "${YELLOW}⚠️  This test requires a valid OTP. Skipping for now.${NC}"
echo ""

# Test 4: Refresh token without token
echo -e "${BLUE}📱 Test 4: Refresh Token - No Token${NC}"
test_endpoint "Refresh Token - No Token" "POST" "/auth/refresh" "{}" "" "401" > /dev/null

# ============================================
# PHASE 3: USER ENDPOINTS (Protected)
# ============================================
print_header "PHASE 3: User Endpoints (Protected)"

# Test without authentication
echo -e "${BLUE}👤 Test 5: Get User Profile - No Auth${NC}"
test_endpoint "Get User - No Auth" "GET" "/users/me" "" "" "401" > /dev/null

echo -e "${BLUE}👤 Test 6: Update User - No Auth${NC}"
test_endpoint "Update User - No Auth" "PUT" "/users/me" "{\"name\": \"Test User\"}" "" "401" > /dev/null

echo -e "${BLUE}👤 Test 7: Get User Books - No Auth${NC}"
test_endpoint "Get User Books - No Auth" "GET" "/users/me/books" "" "" "401" > /dev/null

echo -e "${BLUE}👤 Test 8: Update Notifications - No Auth${NC}"
test_endpoint "Update Notifications - No Auth" "PUT" "/users/me/notifications" "{\"pushEnabled\": true}" "" "401" > /dev/null

echo -e "${BLUE}👤 Test 9: Update Privacy - No Auth${NC}"
test_endpoint "Update Privacy - No Auth" "PUT" "/users/me/privacy" "{\"phoneVisibility\": \"PUBLIC\"}" "" "401" > /dev/null

echo -e "${BLUE}👤 Test 10: Register Device Token - No Auth${NC}"
test_endpoint "Register Device - No Auth" "POST" "/users/me/device-token" "{\"deviceToken\": \"test123\"}" "" "401" > /dev/null

# ============================================
# PHASE 4: BOOK ENDPOINTS
# ============================================
print_header "PHASE 4: Book Endpoints"

# Test 11: Get Books Feed (public endpoint with optional auth)
echo -e "${BLUE}📚 Test 11: Get Books Feed - No Auth${NC}"
FEED_RESPONSE=$(test_endpoint "Get Books Feed" "GET" "/books/feed?page=1&limit=10" "" "" "200")
echo "Feed Response Preview:"
echo "$FEED_RESPONSE" | jq '.' 2>/dev/null || echo "$FEED_RESPONSE" | head -c 300
echo ""

# Test 12: Get Books Feed with filters
echo -e "${BLUE}📚 Test 12: Get Books Feed - With Filters${NC}"
test_endpoint "Get Books Feed - Filtered" "GET" "/books/feed?genre=Fiction&sortBy=RECENT" "" "" "200" > /dev/null

# Test 13: Get Genres
echo -e "${BLUE}📚 Test 13: Get Available Genres${NC}"
GENRES_RESPONSE=$(test_endpoint "Get Genres" "GET" "/books/genres" "" "" "200")
echo "Genres:"
echo "$GENRES_RESPONSE" | jq '.' 2>/dev/null || echo "$GENRES_RESPONSE"
echo ""

# Test 14: Scan ISBN - Valid
echo -e "${BLUE}📚 Test 14: Scan ISBN - Valid${NC}"
test_endpoint "Scan ISBN - Valid" "POST" "/books/scan-isbn" "{\"isbn\": \"9780743273565\"}" "" "200" > /dev/null

# Test 15: Scan ISBN - Invalid
echo -e "${BLUE}📚 Test 15: Scan ISBN - Invalid${NC}"
test_endpoint "Scan ISBN - Invalid" "POST" "/books/scan-isbn" "{\"isbn\": \"invalid\"}" "" "404" > /dev/null

# Test 16: Get Book by ID - Invalid ID
echo -e "${BLUE}📚 Test 16: Get Book - Invalid ID${NC}"
test_endpoint "Get Book - Invalid ID" "GET" "/books/00000000-0000-0000-0000-000000000000" "" "" "404" > /dev/null

# Test 17: Create Book - No Auth
echo -e "${BLUE}📚 Test 17: Create Book - No Auth${NC}"
BOOK_DATA='{
  "title": "Test Book",
  "author": "Test Author",
  "genre": "Fiction",
  "description": "Test description",
  "condition": "GOOD",
  "lendingPricePerWeek": 50
}'
test_endpoint "Create Book - No Auth" "POST" "/books" "$BOOK_DATA" "" "401" > /dev/null

# Test 18: Update Book - No Auth
echo -e "${BLUE}📚 Test 18: Update Book - No Auth${NC}"
test_endpoint "Update Book - No Auth" "PUT" "/books/00000000-0000-0000-0000-000000000000" "{\"title\": \"Updated\"}" "" "401" > /dev/null

# Test 19: Delete Book - No Auth
echo -e "${BLUE}📚 Test 19: Delete Book - No Auth${NC}"
test_endpoint "Delete Book - No Auth" "DELETE" "/books/00000000-0000-0000-0000-000000000000" "" "" "401" > /dev/null

# ============================================
# PHASE 5: ERROR HANDLING
# ============================================
print_header "PHASE 5: Error Handling"

# Test 20: Invalid endpoint
echo -e "${BLUE}❌ Test 20: Invalid Endpoint${NC}"
test_endpoint "Invalid Endpoint" "GET" "/invalid/endpoint" "" "" "404" > /dev/null

# Test 21: Invalid JSON
echo -e "${BLUE}❌ Test 21: Invalid JSON${NC}"
curl -s -w "\n%{http_code}" -X POST "$API_BASE/auth/send-otp" \
  -H "Content-Type: application/json" \
  -d '{invalid json}' > /tmp/invalid_json_test.txt
HTTP_CODE=$(tail -n1 /tmp/invalid_json_test.txt)
if [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "500" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Handles invalid JSON (HTTP $HTTP_CODE)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS+=("✅ Invalid JSON Handling")
else
    echo -e "${RED}❌ FAIL${NC} - Unexpected response to invalid JSON (HTTP $HTTP_CODE)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TEST_RESULTS+=("❌ Invalid JSON Handling")
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""

# ============================================
# SUMMARY
# ============================================
print_header "TEST SUMMARY"

echo -e "${BLUE}Total Tests:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Passed:${NC} $PASSED_TESTS"
echo -e "${RED}Failed:${NC} $FAILED_TESTS"
echo ""

SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
echo -e "${BLUE}Success Rate:${NC} $SUCCESS_RATE%"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests failed. Review the results above.${NC}"
fi

echo ""
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Detailed Results:${NC}"
echo -e "${BLUE}=====================================${NC}"
for result in "${TEST_RESULTS[@]}"; do
    echo "$result"
done

echo ""
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Next Steps for Mobile Team:${NC}"
echo -e "${BLUE}=====================================${NC}"
echo "1. Review API documentation at: $API_BASE/../api-docs"
echo "2. Use test credentials to authenticate"
echo "3. Implement error handling for all error codes"
echo "4. Test with real OTP flow for authentication"
echo "5. Implement token refresh logic"
echo ""
