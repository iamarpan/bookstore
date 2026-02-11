#!/bin/bash

# Groups API Production Testing Script
# Tests all group endpoints on Vercel deployment
# Base URL: https://bookapp-ayushyachitranshs-projects.vercel.app/api/v1

BASE_URL="https://bookapp-ayushyachitranshs-projects.vercel.app/api/v1"
TOKEN=""
GROUP_ID=""
INVITE_CODE=""
SECOND_USER_TOKEN=""
SECOND_USER_ID=""

echo "========================================="
echo "Groups API Production Testing"
echo "========================================="
echo "Testing on: $BASE_URL"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print test results
print_result() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ $1 -eq 0 ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}✓ PASS${NC}: $2"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}✗ FAIL${NC}: $2"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ INFO${NC}: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING${NC}: $1"
}

# Function to check HTTP status
check_status() {
    local status=$1
    local expected=$2
    if [ "$status" = "$expected" ]; then
        return 0
    else
        return 1
    fi
}

echo "========================================="
echo "Step 1: Authentication Setup"
echo "========================================="
echo ""
echo "Please provide your access token (User 1):"
read TOKEN

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Error: Token is required${NC}"
    exit 1
fi

print_info "Token received for User 1"
echo ""

echo "========================================="
echo "Step 2: Testing Groups API Endpoints"
echo "========================================="
echo ""

# Test 1: Create Group
echo "Test 1: Create Group"
echo "-------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/groups" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Book Club - Production",
    "description": "A test group for book sharing on production",
    "category": "BOOK_CLUB",
    "privacy": "PRIVATE",
    "rules": "1. Return books on time\n2. Keep books in good condition\n3. Be respectful"
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
GROUP_ID=$(echo "$BODY" | jq -r '.id // empty' 2>/dev/null)
INVITE_CODE=$(echo "$BODY" | jq -r '.inviteCode // empty' 2>/dev/null)

if check_status "$HTTP_CODE" "201" && [ ! -z "$GROUP_ID" ]; then
    print_result 0 "Create Group (HTTP $HTTP_CODE)"
    print_info "Group ID: $GROUP_ID"
    print_info "Invite Code: $INVITE_CODE"
else
    print_result 1 "Create Group (HTTP $HTTP_CODE, expected 201)"
fi
echo ""

# Test 2: Get My Groups
echo "Test 2: Get My Groups"
echo "-------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/groups/my-groups" \
  -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
COUNT=$(echo "$BODY" | jq 'length' 2>/dev/null || echo "0")

if check_status "$HTTP_CODE" "200" && [ "$COUNT" -gt 0 ]; then
    print_result 0 "Get My Groups (HTTP $HTTP_CODE, Found $COUNT groups)"
else
    print_result 1 "Get My Groups (HTTP $HTTP_CODE, expected 200)"
fi
echo ""

# Test 3: Get Group Details
echo "Test 3: Get Group Details"
echo "-------------------------------------"
if [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/groups/$GROUP_ID" \
      -H "Authorization: Bearer $TOKEN")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    NAME=$(echo "$BODY" | jq -r '.name // empty' 2>/dev/null)
    
    if check_status "$HTTP_CODE" "200" && [ ! -z "$NAME" ]; then
        print_result 0 "Get Group Details (HTTP $HTTP_CODE)"
        print_info "Group Name: $NAME"
    else
        print_result 1 "Get Group Details (HTTP $HTTP_CODE, expected 200)"
    fi
else
    print_warning "Skipping - No group ID available"
fi
echo ""

# Test 4: Get Group Members
echo "Test 4: Get Group Members"
echo "-------------------------------------"
if [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/groups/$GROUP_ID/members" \
      -H "Authorization: Bearer $TOKEN")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    TOTAL=$(echo "$BODY" | jq -r '.total // 0' 2>/dev/null)
    
    if check_status "$HTTP_CODE" "200" && [ "$TOTAL" -ge 1 ]; then
        print_result 0 "Get Group Members (HTTP $HTTP_CODE, Found $TOTAL members)"
    else
        print_result 1 "Get Group Members (HTTP $HTTP_CODE, expected 200)"
    fi
else
    print_warning "Skipping - No group ID available"
fi
echo ""

# Test 5: Get Group Books
echo "Test 5: Get Group Books"
echo "-------------------------------------"
if [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/groups/$GROUP_ID/books" \
      -H "Authorization: Bearer $TOKEN")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    
    if check_status "$HTTP_CODE" "200"; then
        print_result 0 "Get Group Books (HTTP $HTTP_CODE)"
        BOOK_COUNT=$(echo "$BODY" | jq -r '.books | length // 0' 2>/dev/null)
        print_info "Books in group: $BOOK_COUNT"
    else
        print_result 1 "Get Group Books (HTTP $HTTP_CODE, expected 200)"
    fi
else
    print_warning "Skipping - No group ID available"
fi
echo ""

# Test 6: Update Group
echo "Test 6: Update Group"
echo "-------------------------------------"
if [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/groups/$GROUP_ID" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "Updated Test Book Club - Production",
        "description": "Updated description for production testing"
      }')
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    NAME=$(echo "$BODY" | jq -r '.name // empty' 2>/dev/null)
    
    if check_status "$HTTP_CODE" "200" && [ "$NAME" = "Updated Test Book Club - Production" ]; then
        print_result 0 "Update Group (HTTP $HTTP_CODE)"
    else
        print_result 1 "Update Group (HTTP $HTTP_CODE, expected 200)"
    fi
else
    print_warning "Skipping - No group ID available"
fi
echo ""

# Test 7: Regenerate Invite Code
echo "Test 7: Regenerate Invite Code"
echo "-------------------------------------"
if [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/groups/$GROUP_ID/regenerate-invite" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "expiresInDays": 7
      }')
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    NEW_CODE=$(echo "$BODY" | jq -r '.inviteCode // empty' 2>/dev/null)
    
    if check_status "$HTTP_CODE" "200" && [ ! -z "$NEW_CODE" ] && [ "$NEW_CODE" != "$INVITE_CODE" ]; then
        print_result 0 "Regenerate Invite Code (HTTP $HTTP_CODE)"
        print_info "Old Code: $INVITE_CODE"
        print_info "New Code: $NEW_CODE"
        INVITE_CODE="$NEW_CODE"
    else
        print_result 1 "Regenerate Invite Code (HTTP $HTTP_CODE, expected 200)"
    fi
else
    print_warning "Skipping - No group ID available"
fi
echo ""

# Test 8: Filter Groups by Category
echo "Test 8: Filter Groups by Category"
echo "-------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/groups/my-groups?category=BOOK_CLUB" \
  -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"

if check_status "$HTTP_CODE" "200"; then
    print_result 0 "Filter Groups by Category (HTTP $HTTP_CODE)"
    FILTERED_COUNT=$(echo "$BODY" | jq 'length' 2>/dev/null || echo "0")
    print_info "Filtered groups: $FILTERED_COUNT"
else
    print_result 1 "Filter Groups by Category (HTTP $HTTP_CODE, expected 200)"
fi
echo ""

# Test 9: Sort Groups
echo "Test 9: Sort Groups by Name"
echo "-------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/groups/my-groups?sortBy=NAME" \
  -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"

if check_status "$HTTP_CODE" "200"; then
    print_result 0 "Sort Groups by Name (HTTP $HTTP_CODE)"
else
    print_result 1 "Sort Groups by Name (HTTP $HTTP_CODE, expected 200)"
fi
echo ""

# Test 10: Join Group (requires second user)
echo "Test 10: Join Group with Invite Code"
echo "-------------------------------------"
echo "To test joining a group, you need a second user's token."
echo "Do you want to test this? (y/n)"
read TEST_JOIN

if [ "$TEST_JOIN" = "y" ]; then
    echo "Enter the second user's access token:"
    read SECOND_USER_TOKEN
    
    if [ ! -z "$SECOND_USER_TOKEN" ] && [ ! -z "$INVITE_CODE" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/groups/join" \
          -H "Authorization: Bearer $SECOND_USER_TOKEN" \
          -H "Content-Type: application/json" \
          -d "{
            \"inviteCode\": \"$INVITE_CODE\"
          }")
        
        HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
        BODY=$(echo "$RESPONSE" | sed '$d')
        
        echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
        MESSAGE=$(echo "$BODY" | jq -r '.message // empty' 2>/dev/null)
        
        if check_status "$HTTP_CODE" "200" && [ "$MESSAGE" = "Successfully joined group" ]; then
            print_result 0 "Join Group (HTTP $HTTP_CODE)"
            
            # Get the second user's ID from the group members
            MEMBERS_RESPONSE=$(curl -s -X GET "$BASE_URL/groups/$GROUP_ID/members" \
              -H "Authorization: Bearer $TOKEN")
            SECOND_USER_ID=$(echo "$MEMBERS_RESPONSE" | jq -r '.members[-1].userId // empty' 2>/dev/null)
            print_info "Second user joined successfully"
        else
            print_result 1 "Join Group (HTTP $HTTP_CODE, expected 200)"
        fi
    fi
else
    print_warning "Skipping Join Group test"
fi
echo ""

# Test 11: Update Member Role (if second user joined)
if [ ! -z "$SECOND_USER_ID" ] && [ ! -z "$GROUP_ID" ]; then
    echo "Test 11: Update Member Role"
    echo "-------------------------------------"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/groups/$GROUP_ID/members/$SECOND_USER_ID" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "role": "MODERATOR"
      }')
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    
    if check_status "$HTTP_CODE" "200"; then
        print_result 0 "Update Member Role (HTTP $HTTP_CODE)"
    else
        print_result 1 "Update Member Role (HTTP $HTTP_CODE, expected 200)"
    fi
    echo ""
fi

# Test 12: Leave Group (if second user joined)
if [ ! -z "$SECOND_USER_TOKEN" ] && [ ! -z "$GROUP_ID" ]; then
    echo "Test 12: Leave Group"
    echo "-------------------------------------"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/groups/$GROUP_ID/leave" \
      -H "Authorization: Bearer $SECOND_USER_TOKEN")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    
    if check_status "$HTTP_CODE" "200"; then
        print_result 0 "Leave Group (HTTP $HTTP_CODE)"
    else
        print_result 1 "Leave Group (HTTP $HTTP_CODE, expected 200)"
    fi
    echo ""
fi

# Test 13: Delete Group (cleanup)
echo "Test 13: Delete Group (Cleanup)"
echo "-------------------------------------"
echo "Do you want to delete the test group? (y/n)"
read DELETE_GROUP

if [ "$DELETE_GROUP" = "y" ] && [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/groups/$GROUP_ID" \
      -H "Authorization: Bearer $TOKEN")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    MESSAGE=$(echo "$BODY" | jq -r '.message // empty' 2>/dev/null)
    
    if check_status "$HTTP_CODE" "200" && [ "$MESSAGE" = "Group deleted successfully" ]; then
        print_result 0 "Delete Group (HTTP $HTTP_CODE)"
    else
        print_result 1 "Delete Group (HTTP $HTTP_CODE, expected 200)"
    fi
else
    print_warning "Skipping group deletion - Group ID: $GROUP_ID"
fi
echo ""

# Final Summary
echo "========================================="
echo "Testing Complete!"
echo "========================================="
echo ""
echo -e "${BLUE}Test Summary:${NC}"
echo "  Total Tests: $TOTAL_TESTS"
echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
else
    echo -e "${YELLOW}⚠ Some tests failed. Please review the output above.${NC}"
fi

echo ""
echo "Test artifacts:"
echo "  - Group ID: $GROUP_ID"
echo "  - Invite Code: $INVITE_CODE"
echo ""
echo "Next steps:"
echo "  1. Review Swagger documentation: https://bookapp-ayushyachitranshs-projects.vercel.app/api-docs"
echo "  2. Test with the mobile app"
echo "  3. Test edge cases and error scenarios"
echo "  4. Verify role-based permissions"
echo ""
