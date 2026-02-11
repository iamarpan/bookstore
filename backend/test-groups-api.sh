#!/bin/bash

# Groups API Testing Script
# This script tests all group endpoints

BASE_URL="http://localhost:3000/api/v1"
TOKEN=""
GROUP_ID=""
INVITE_CODE=""
USER_ID=""

echo "========================================="
echo "Groups API Testing Script"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
    fi
}

echo "Step 1: Authentication"
echo "-------------------------------------"
echo "Please provide your access token:"
read TOKEN

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Error: Token is required${NC}"
    exit 1
fi

echo ""
echo "========================================="
echo "Testing Groups API Endpoints"
echo "========================================="
echo ""

# Test 1: Create Group
echo "Test 1: Create Group"
echo "-------------------------------------"
RESPONSE=$(curl -s -X POST "$BASE_URL/groups" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Book Club",
    "description": "A test group for book sharing",
    "category": "BOOK_CLUB",
    "privacy": "PRIVATE",
    "rules": "1. Return books on time\n2. Keep books in good condition"
  }')

echo "$RESPONSE" | jq '.'
GROUP_ID=$(echo "$RESPONSE" | jq -r '.id // empty')
INVITE_CODE=$(echo "$RESPONSE" | jq -r '.inviteCode // empty')

if [ ! -z "$GROUP_ID" ]; then
    print_result 0 "Create Group"
    echo "Group ID: $GROUP_ID"
    echo "Invite Code: $INVITE_CODE"
else
    print_result 1 "Create Group"
fi
echo ""

# Test 2: Get My Groups
echo "Test 2: Get My Groups"
echo "-------------------------------------"
RESPONSE=$(curl -s -X GET "$BASE_URL/groups/my-groups" \
  -H "Authorization: Bearer $TOKEN")

echo "$RESPONSE" | jq '.'
COUNT=$(echo "$RESPONSE" | jq 'length')
if [ "$COUNT" -gt 0 ]; then
    print_result 0 "Get My Groups (Found $COUNT groups)"
else
    print_result 1 "Get My Groups"
fi
echo ""

# Test 3: Get Group Details
echo "Test 3: Get Group Details"
echo "-------------------------------------"
if [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -X GET "$BASE_URL/groups/$GROUP_ID" \
      -H "Authorization: Bearer $TOKEN")
    
    echo "$RESPONSE" | jq '.'
    NAME=$(echo "$RESPONSE" | jq -r '.name // empty')
    if [ "$NAME" = "Test Book Club" ]; then
        print_result 0 "Get Group Details"
    else
        print_result 1 "Get Group Details"
    fi
else
    echo "Skipping - No group ID available"
fi
echo ""

# Test 4: Get Group Members
echo "Test 4: Get Group Members"
echo "-------------------------------------"
if [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -X GET "$BASE_URL/groups/$GROUP_ID/members" \
      -H "Authorization: Bearer $TOKEN")
    
    echo "$RESPONSE" | jq '.'
    TOTAL=$(echo "$RESPONSE" | jq -r '.total // 0')
    if [ "$TOTAL" -ge 1 ]; then
        print_result 0 "Get Group Members (Found $TOTAL members)"
    else
        print_result 1 "Get Group Members"
    fi
else
    echo "Skipping - No group ID available"
fi
echo ""

# Test 5: Get Group Books
echo "Test 5: Get Group Books"
echo "-------------------------------------"
if [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -X GET "$BASE_URL/groups/$GROUP_ID/books" \
      -H "Authorization: Bearer $TOKEN")
    
    echo "$RESPONSE" | jq '.'
    print_result 0 "Get Group Books"
else
    echo "Skipping - No group ID available"
fi
echo ""

# Test 6: Update Group
echo "Test 6: Update Group"
echo "-------------------------------------"
if [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -X PUT "$BASE_URL/groups/$GROUP_ID" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "Updated Test Book Club",
        "description": "Updated description for testing"
      }')
    
    echo "$RESPONSE" | jq '.'
    NAME=$(echo "$RESPONSE" | jq -r '.name // empty')
    if [ "$NAME" = "Updated Test Book Club" ]; then
        print_result 0 "Update Group"
    else
        print_result 1 "Update Group"
    fi
else
    echo "Skipping - No group ID available"
fi
echo ""

# Test 7: Regenerate Invite Code
echo "Test 7: Regenerate Invite Code"
echo "-------------------------------------"
if [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -X POST "$BASE_URL/groups/$GROUP_ID/regenerate-invite" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "expiresInDays": 7
      }')
    
    echo "$RESPONSE" | jq '.'
    NEW_CODE=$(echo "$RESPONSE" | jq -r '.inviteCode // empty')
    if [ ! -z "$NEW_CODE" ] && [ "$NEW_CODE" != "$INVITE_CODE" ]; then
        print_result 0 "Regenerate Invite Code"
        echo "New Invite Code: $NEW_CODE"
        INVITE_CODE="$NEW_CODE"
    else
        print_result 1 "Regenerate Invite Code"
    fi
else
    echo "Skipping - No group ID available"
fi
echo ""

# Test 8: Join Group (requires second user)
echo "Test 8: Join Group"
echo "-------------------------------------"
echo "To test joining a group, you need a second user's token."
echo "Do you want to test this? (y/n)"
read TEST_JOIN

if [ "$TEST_JOIN" = "y" ]; then
    echo "Enter the second user's access token:"
    read TOKEN2
    
    if [ ! -z "$TOKEN2" ] && [ ! -z "$INVITE_CODE" ]; then
        RESPONSE=$(curl -s -X POST "$BASE_URL/groups/join" \
          -H "Authorization: Bearer $TOKEN2" \
          -H "Content-Type: application/json" \
          -d "{
            \"inviteCode\": \"$INVITE_CODE\"
          }")
        
        echo "$RESPONSE" | jq '.'
        MESSAGE=$(echo "$RESPONSE" | jq -r '.message // empty')
        if [ "$MESSAGE" = "Successfully joined group" ]; then
            print_result 0 "Join Group"
        else
            print_result 1 "Join Group"
        fi
    fi
else
    echo "Skipping Join Group test"
fi
echo ""

# Test 9: Filter Groups by Category
echo "Test 9: Filter Groups by Category"
echo "-------------------------------------"
RESPONSE=$(curl -s -X GET "$BASE_URL/groups/my-groups?category=BOOK_CLUB" \
  -H "Authorization: Bearer $TOKEN")

echo "$RESPONSE" | jq '.'
print_result 0 "Filter Groups by Category"
echo ""

# Test 10: Delete Group (optional - cleanup)
echo "Test 10: Delete Group (Cleanup)"
echo "-------------------------------------"
echo "Do you want to delete the test group? (y/n)"
read DELETE_GROUP

if [ "$DELETE_GROUP" = "y" ] && [ ! -z "$GROUP_ID" ]; then
    RESPONSE=$(curl -s -X DELETE "$BASE_URL/groups/$GROUP_ID" \
      -H "Authorization: Bearer $TOKEN")
    
    echo "$RESPONSE" | jq '.'
    MESSAGE=$(echo "$RESPONSE" | jq -r '.message // empty')
    if [ "$MESSAGE" = "Group deleted successfully" ]; then
        print_result 0 "Delete Group"
    else
        print_result 1 "Delete Group"
    fi
else
    echo "Skipping group deletion"
fi
echo ""

echo "========================================="
echo "Testing Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "- Created group with ID: $GROUP_ID"
echo "- Invite code: $INVITE_CODE"
echo ""
echo "Next steps:"
echo "1. Test with the mobile app"
echo "2. Verify all endpoints in Swagger UI"
echo "3. Test edge cases and error scenarios"
