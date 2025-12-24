# User Management API Testing

## Prerequisites

You need an access token from the authentication flow. See `AUTH_TESTING.md` for how to get one.

For these examples, replace `YOUR_ACCESS_TOKEN` with your actual token.

---

## 1. Get Current User Profile

```bash
curl -X GET http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response:**
```json
{
  "id": "user-uuid",
  "phoneNumber": "+919876543210",
  "phoneVerified": true,
  "name": "Demo User",
  "email": "demo@bookstore.com",
  "bio": "Book enthusiast and avid reader",
  "profileImageUrl": null,
  "booksShared": 8,
  "successfulLends": 15,
  "booksBorrowed": 12,
  "totalEarned": "650.00",
  "averageRating": "4.70",
  "phoneVisibility": "AFTER_APPROVAL",
  "pushEnabled": true,
  "emailEnabled": true,
  "borrowRequestsNotif": true,
  "dueDateRemindersNotif": true,
  "groupActivityNotif": true,
  "deviceToken": null,
  "lastTokenUpdate": null,
  "isActive": true,
  "createdAt": "2025-12-21T...",
  "lastLoginAt": "2025-12-22T..."
}
```

---

## 2. Update User Profile

```bash
curl -X PUT http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Updated",
    "email": "john.updated@example.com",
    "bio": "Updated bio text"
  }'
```

**Expected Response:** Updated user object

**Note:** All fields are optional. You can update just one field if needed.

---

## 3. Update Notification Preferences

```bash
curl -X PUT http://localhost:3000/api/v1/users/me/notifications \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pushEnabled": true,
    "emailEnabled": false,
    "borrowRequestsNotif": true,
    "dueDateRemindersNotif": true,
    "groupActivityNotif": false
  }'
```

**Expected Response:**
```json
{
  "message": "Notification preferences updated",
  "preferences": {
    "pushEnabled": true,
    "emailEnabled": false,
    "borrowRequestsNotif": true,
    "dueDateRemindersNotif": true,
    "groupActivityNotif": false
  }
}
```

---

## 4. Update Privacy Settings

```bash
curl -X PUT http://localhost:3000/api/v1/users/me/privacy \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneVisibility": "PUBLIC"
  }'
```

**Phone Visibility Options:**
- `AFTER_APPROVAL` - Show phone only after borrow request approval
- `GROUP_MEMBERS` - Show to all group members
- `PUBLIC` - Show to everyone

**Expected Response:**
```json
{
  "message": "Privacy settings updated",
  "phoneVisibility": "PUBLIC"
}
```

---

## 5. Register Device Token (for Push Notifications)

```bash
curl -X POST http://localhost:3000/api/v1/users/me/device-token \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceToken": "your-apns-device-token-here"
  }'
```

**Expected Response:**
```json
{
  "message": "Device token registered successfully"
}
```

---

## 6. Get Current User's Books

```bash
curl -X GET http://localhost:3000/api/v1/users/me/books \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response:**
```json
[
  {
    "id": "book-uuid",
    "title": "Clean Code",
    "author": "Robert C. Martin",
    "genre": "Technology",
    "description": "...",
    "imageUrl": "https://...",
    "condition": "GOOD",
    "lendingPricePerWeek": "40.00",
    "isAvailable": true,
    "ownerId": "user-uuid",
    "bookGroups": [
      {
        "group": {
          "id": "group-uuid",
          "name": "Office Book Club"
        }
      }
    ],
    "createdAt": "2025-12-21T...",
    "updatedAt": "2025-12-21T..."
  }
]
```

---

## Complete Testing Flow

### Step 1: Authenticate
```bash
# Send OTP
curl -X POST http://localhost:3000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+919876543210"}'

# Verify OTP (check console for OTP code)
curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+919876543210",
    "otp": "123456"
  }'

# Save the accessToken from response
```

### Step 2: Get Profile
```bash
export TOKEN="your-access-token-here"

curl -X GET http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"
```

### Step 3: Update Profile
```bash
curl -X PUT http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Name",
    "bio": "Updated bio"
  }'
```

### Step 4: Get User's Books
```bash
curl -X GET http://localhost:3000/api/v1/users/me/books \
  -H "Authorization: Bearer $TOKEN"
```

---

## Error Responses

### 401 Unauthorized (Missing or Invalid Token)
```json
{
  "error": "Unauthorized",
  "message": "No token provided"
}
```

### 400 Bad Request (Invalid Data)
```json
{
  "error": "Bad Request",
  "message": "At least one field must be provided"
}
```

### 404 Not Found (User Not Found)
```json
{
  "error": "Not Found",
  "message": "User not found"
}
```

---

## Notes

- All user endpoints require authentication via Bearer token
- Tokens expire after 15 minutes (use refresh token to get new access token)
- Profile updates are immediately reflected
- Device tokens are used for APNs push notifications (iOS)
