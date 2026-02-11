# Groups API - Mobile Team Handover Documentation

## 📋 Document Overview

**Version:** 1.0.0  
**Last Updated:** February 10, 2026  
**API Base URL:** `https://bookapp-ayushyachitranshs-projects.vercel.app/api/v1`  
**Status:** ✅ **FULLY IMPLEMENTED** - Production Ready

---

## 🚨 Current Implementation Status

> [!IMPORTANT]
> **Groups API Status**
> 
> The groups feature is **FULLY IMPLEMENTED** in the backend:
> - ✅ **Database Schema:** Fully defined with Group, GroupMember, and BookGroup models
> - ✅ **Book-Group Integration:** Books can be associated with groups
> - ✅ **Group Service:** Complete service layer with 12 functions
> - ✅ **API Endpoints:** All `/api/v1/groups` endpoints implemented and functional
> - ✅ **Group Management:** Create, join, leave, update, delete operations working
> - ✅ **Member Management:** Role updates, member removal, invite codes all working
> - ✅ **Swagger Documentation:** Complete API documentation available
> - ✅ **TypeScript Compilation:** No errors, production-ready
> 
> **Mobile Team Action:** Backend is ready for integration! All endpoints are functional and documented. See test script at `/backend/test-groups-api.sh` for verification.

---

## 📊 Database Schema

### Group Model

The `Group` model represents a collection of users who share books with each other.

```typescript
model Group {
  id                String         @id @default(uuid())
  name              String         // Group name (e.g., "Office Book Club")
  description       String         @db.Text
  coverImageUrl     String?        // Optional group cover image
  category          GroupCategory  @default(FRIENDS)
  privacy           PrivacySetting @default(PRIVATE)
  
  creatorId         String         // User who created the group
  inviteCode        String         @unique  // Unique code for joining
  inviteCodeExpiry  DateTime?      // Optional expiry for invite code
  
  rules             String?        @db.Text  // Optional group rules
  booksCount        Int            @default(0)  // Total books in group
  memberCount       Int            @default(1)  // Total members (starts with creator)
  
  createdAt         DateTime       @default(now())
  updatedAt         DateTime       @updatedAt
  
  // Relations
  creator           User           @relation("GroupCreator")
  members           GroupMember[]  // All group members
  bookGroups        BookGroup[]    // Books visible in this group
  transactions      Transaction[]  // Transactions within this group
}
```

**Enums:**

```typescript
enum GroupCategory {
  FRIENDS         // Friend circle
  OFFICE          // Office/workplace
  NEIGHBORHOOD    // Neighborhood community
  BOOK_CLUB       // Book club
  SCHOOL          // School/university
}

enum PrivacySetting {
  PUBLIC          // Anyone can see and join
  PRIVATE         // Invite-only, not discoverable
}
```

---

### GroupMember Model

The `GroupMember` model represents the many-to-many relationship between users and groups.

```typescript
model GroupMember {
  id        String      @id @default(uuid())
  groupId   String      // Reference to group
  userId    String      // Reference to user
  role      MemberRole  @default(MEMBER)
  joinedAt  DateTime    @default(now())
  
  // Relations
  group     Group       @relation(fields: [groupId])
  user      User        @relation(fields: [userId])
  
  @@unique([groupId, userId])  // User can only be in a group once
}
```

**Member Roles:**

```typescript
enum MemberRole {
  MEMBER      // Regular member
  MODERATOR   // Can moderate content
  ADMIN       // Can manage members and settings
  CREATOR     // Group creator (highest privileges)
}
```

---

### BookGroup Model

The `BookGroup` model represents which books are visible in which groups.

```typescript
model BookGroup {
  id       String   @id @default(uuid())
  bookId   String   // Reference to book
  groupId  String   // Reference to group
  addedAt  DateTime @default(now())
  
  // Relations
  book     Book     @relation(fields: [bookId])
  group    Group    @relation(fields: [groupId])
  
  @@unique([bookId, groupId])  // Book can only be in a group once
}
```

---

## ✅ Currently Implemented Functionality

### 1. Get User's Groups

**Service Function:** `getUserGroups(userId: string)`  
**Location:** `/backend/src/services/user.service.ts`

```typescript
export async function getUserGroups(userId: string) {
    const memberships = await prisma.groupMember.findMany({
        where: { userId },
        include: {
            group: true,
        },
    });

    return memberships.map(m => m.group);
}
```

**Returns:** Array of all groups the user is a member of.

> [!NOTE]
> This function is implemented but **not exposed via any API endpoint** yet. Mobile team cannot currently access this functionality.

---

### 2. Book-Group Integration

Books can be associated with groups when created or updated. This functionality is **fully implemented** in the books service.

**Create Book with Groups:**

```typescript
// When creating a book, specify which groups it's visible in
POST /api/v1/books
{
  "title": "Clean Code",
  "author": "Robert C. Martin",
  "genre": "Technology",
  "condition": "GOOD",
  "lendingPricePerWeek": 50,
  "visibleInGroups": ["group-id-1", "group-id-2"]  // ✅ Implemented
}
```

**Filter Books by Group:**

```typescript
// Get books feed filtered by group IDs
GET /api/v1/books/feed?groupIds=group-id-1,group-id-2  // ✅ Implemented
```

**Book Response Includes Groups:**

```json
{
  "id": "book-id",
  "title": "Clean Code",
  "bookGroups": [
    {
      "id": "book-group-id",
      "groupId": "group-id-1",
      "group": {
        "id": "group-id-1",
        "name": "Office Book Club"
      },
      "addedAt": "2026-02-10T00:00:00.000Z"
    }
  ]
}
```

---

## ✅ Implemented API Endpoints

All the following endpoints have been implemented and are ready for use:

### 1. Create Group

**Endpoint:** `POST /api/v1/groups`  
**Authentication:** Required  
**Description:** Create a new group

**Request Body:**
```json
{
  "name": "Office Book Club",
  "description": "Share books with office colleagues",
  "category": "OFFICE",
  "privacy": "PRIVATE",
  "coverImageUrl": "https://example.com/cover.jpg",
  "rules": "1. Return books on time\n2. Keep books in good condition"
}
```

**Required Fields:**
- `name` (string)
- `description` (string)
- `category` (FRIENDS | OFFICE | NEIGHBORHOOD | BOOK_CLUB | SCHOOL)
- `privacy` (PUBLIC | PRIVATE)

**Optional Fields:**
- `coverImageUrl` (string)
- `rules` (string)

**Expected Response (201):**
```json
{
  "id": "group-id",
  "name": "Office Book Club",
  "description": "Share books with office colleagues",
  "coverImageUrl": "https://example.com/cover.jpg",
  "category": "OFFICE",
  "privacy": "PRIVATE",
  "creatorId": "user-id",
  "inviteCode": "ABC123XYZ",
  "inviteCodeExpiry": null,
  "rules": "1. Return books on time\n2. Keep books in good condition",
  "booksCount": 0,
  "memberCount": 1,
  "createdAt": "2026-02-10T00:00:00.000Z",
  "updatedAt": "2026-02-10T00:00:00.000Z",
  "role": "CREATOR"
}
```

**Implementation Notes:**
- Auto-generate unique `inviteCode` (e.g., 8-character alphanumeric)
- Set `memberCount` to 1 (creator)
- Automatically create `GroupMember` entry for creator with role `CREATOR`
- Return group with user's role included

---

### 2. Get User's Groups

**Endpoint:** `GET /api/v1/groups/my-groups`  
**Authentication:** Required  
**Description:** Get all groups the authenticated user is a member of

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `category` | string | - | Filter by category |
| `sortBy` | string | RECENT | Sort order (RECENT, NAME, MEMBERS, BOOKS) |

**Expected Response (200):**
```json
[
  {
    "id": "group-id-1",
    "name": "Office Book Club",
    "description": "Share books with office colleagues",
    "coverImageUrl": "https://example.com/cover.jpg",
    "category": "OFFICE",
    "privacy": "PRIVATE",
    "booksCount": 15,
    "memberCount": 8,
    "role": "CREATOR",
    "joinedAt": "2026-01-15T00:00:00.000Z",
    "createdAt": "2026-01-15T00:00:00.000Z"
  },
  {
    "id": "group-id-2",
    "name": "Friends Circle",
    "description": "Book sharing among friends",
    "coverImageUrl": null,
    "category": "FRIENDS",
    "privacy": "PRIVATE",
    "booksCount": 23,
    "memberCount": 5,
    "role": "MEMBER",
    "joinedAt": "2026-02-01T00:00:00.000Z",
    "createdAt": "2026-01-10T00:00:00.000Z"
  }
]
```

**Implementation Notes:**
- Use existing `getUserGroups()` service function
- Include user's role in each group
- Include `joinedAt` timestamp from `GroupMember`
- Sort by specified criteria

---

### 3. Get Group Details

**Endpoint:** `GET /api/v1/groups/:id`  
**Authentication:** Required (for private groups) / Optional (for public groups)  
**Description:** Get detailed information about a specific group

**Expected Response (200):**
```json
{
  "id": "group-id",
  "name": "Office Book Club",
  "description": "Share books with office colleagues",
  "coverImageUrl": "https://example.com/cover.jpg",
  "category": "OFFICE",
  "privacy": "PRIVATE",
  "inviteCode": "ABC123XYZ",
  "rules": "1. Return books on time\n2. Keep books in good condition",
  "booksCount": 15,
  "memberCount": 8,
  "createdAt": "2026-01-15T00:00:00.000Z",
  "updatedAt": "2026-02-08T00:00:00.000Z",
  "creator": {
    "id": "user-id",
    "name": "John Doe",
    "profileImageUrl": "https://example.com/profile.jpg"
  },
  "userRole": "CREATOR",
  "isMember": true
}
```

**Error Responses:**
- `403` - Private group and user is not a member
- `404` - Group not found

**Implementation Notes:**
- For private groups, verify user is a member
- Include creator information
- Include user's role if they're a member
- Include `isMember` boolean

---

### 4. Get Group Members

**Endpoint:** `GET /api/v1/groups/:id/members`  
**Authentication:** Required  
**Description:** Get all members of a group (must be a member to view)

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `role` | string | - | Filter by role (MEMBER, MODERATOR, ADMIN, CREATOR) |

**Expected Response (200):**
```json
{
  "members": [
    {
      "id": "member-id-1",
      "userId": "user-id-1",
      "role": "CREATOR",
      "joinedAt": "2026-01-15T00:00:00.000Z",
      "user": {
        "id": "user-id-1",
        "name": "John Doe",
        "profileImageUrl": "https://example.com/profile.jpg",
        "booksShared": 12,
        "averageRating": 4.5
      }
    },
    {
      "id": "member-id-2",
      "userId": "user-id-2",
      "role": "MEMBER",
      "joinedAt": "2026-01-20T00:00:00.000Z",
      "user": {
        "id": "user-id-2",
        "name": "Jane Smith",
        "profileImageUrl": "https://example.com/profile2.jpg",
        "booksShared": 5,
        "averageRating": 4.8
      }
    }
  ],
  "total": 8
}
```

**Error Responses:**
- `403` - User is not a member of this group
- `404` - Group not found

---

### 5. Get Group Books

**Endpoint:** `GET /api/v1/groups/:id/books`  
**Authentication:** Required  
**Description:** Get all books visible in a specific group

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number |
| `limit` | integer | 20 | Items per page |
| `availability` | boolean | - | Filter by availability |
| `genre` | string | - | Filter by genre |
| `sortBy` | string | RECENT | Sort order (RECENT, PRICE_LOW, PRICE_HIGH) |

**Expected Response (200):**
```json
{
  "books": [
    {
      "id": "book-id",
      "title": "Clean Code",
      "author": "Robert C. Martin",
      "genre": "Technology",
      "imageUrl": "https://example.com/book.jpg",
      "condition": "GOOD",
      "lendingPricePerWeek": 50,
      "isAvailable": true,
      "ownerId": "user-id",
      "ownerName": "John Doe",
      "addedAt": "2026-01-20T00:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 15,
    "totalPages": 1
  }
}
```

**Implementation Notes:**
- Verify user is a member of the group
- Use existing book feed logic with group filter
- Include `addedAt` from `BookGroup` table

---

### 6. Join Group

**Endpoint:** `POST /api/v1/groups/join`  
**Authentication:** Required  
**Description:** Join a group using an invite code

**Request Body:**
```json
{
  "inviteCode": "ABC123XYZ"
}
```

**Expected Response (200):**
```json
{
  "message": "Successfully joined group",
  "group": {
    "id": "group-id",
    "name": "Office Book Club",
    "description": "Share books with office colleagues",
    "coverImageUrl": "https://example.com/cover.jpg",
    "category": "OFFICE",
    "privacy": "PRIVATE",
    "booksCount": 15,
    "memberCount": 9,
    "role": "MEMBER",
    "joinedAt": "2026-02-10T00:00:00.000Z"
  }
}
```

**Error Responses:**
- `400` - Invalid or expired invite code
- `409` - User is already a member of this group
- `404` - Group not found

**Implementation Notes:**
- Validate invite code exists and not expired
- Check if user is already a member
- Create `GroupMember` entry with role `MEMBER`
- Increment group's `memberCount`
- Return group with user's new role

---

### 7. Leave Group

**Endpoint:** `POST /api/v1/groups/:id/leave`  
**Authentication:** Required  
**Description:** Leave a group (creator cannot leave)

**Expected Response (200):**
```json
{
  "message": "Successfully left group"
}
```

**Error Responses:**
- `400` - Creator cannot leave group (must transfer ownership or delete)
- `403` - User is not a member of this group
- `404` - Group not found

**Implementation Notes:**
- Prevent creator from leaving
- Delete `GroupMember` entry
- Decrement group's `memberCount`
- Remove user's books from group (delete `BookGroup` entries)
- Update group's `booksCount`

---

### 8. Update Group

**Endpoint:** `PUT /api/v1/groups/:id`  
**Authentication:** Required  
**Description:** Update group details (admin/creator only)

**Request Body (all fields optional):**
```json
{
  "name": "Updated Office Book Club",
  "description": "Updated description",
  "coverImageUrl": "https://example.com/new-cover.jpg",
  "category": "OFFICE",
  "privacy": "PUBLIC",
  "rules": "Updated rules"
}
```

**Expected Response (200):**
```json
{
  "id": "group-id",
  "name": "Updated Office Book Club",
  "description": "Updated description",
  ...
}
```

**Error Responses:**
- `403` - User must be admin or creator to update group
- `404` - Group not found

**Implementation Notes:**
- Verify user has ADMIN or CREATOR role
- All fields are optional
- Update `updatedAt` timestamp

---

### 9. Delete Group

**Endpoint:** `DELETE /api/v1/groups/:id`  
**Authentication:** Required  
**Description:** Delete a group (creator only)

**Expected Response (200):**
```json
{
  "message": "Group deleted successfully"
}
```

**Error Responses:**
- `403` - Only creator can delete group
- `404` - Group not found

**Implementation Notes:**
- Verify user is the creator
- Cascade delete will handle:
  - All `GroupMember` entries
  - All `BookGroup` entries
  - All `Transaction` entries in this group
- No need to manually update counts (group is deleted)

---

### 10. Update Member Role

**Endpoint:** `PUT /api/v1/groups/:id/members/:userId`  
**Authentication:** Required  
**Description:** Update a member's role (admin/creator only)

**Request Body:**
```json
{
  "role": "MODERATOR"
}
```

**Allowed Roles:**
- `MEMBER`
- `MODERATOR`
- `ADMIN`

**Expected Response (200):**
```json
{
  "message": "Member role updated successfully",
  "member": {
    "id": "member-id",
    "userId": "user-id",
    "role": "MODERATOR",
    "joinedAt": "2026-01-20T00:00:00.000Z"
  }
}
```

**Error Responses:**
- `400` - Cannot change creator's role
- `403` - User must be admin or creator to update roles
- `404` - Group or member not found

**Implementation Notes:**
- Verify requester has ADMIN or CREATOR role
- Cannot change CREATOR role (only one creator per group)
- Update `GroupMember.role`

---

### 11. Remove Member

**Endpoint:** `DELETE /api/v1/groups/:id/members/:userId`  
**Authentication:** Required  
**Description:** Remove a member from the group (admin/creator only)

**Expected Response (200):**
```json
{
  "message": "Member removed successfully"
}
```

**Error Responses:**
- `400` - Cannot remove creator
- `403` - User must be admin or creator to remove members
- `404` - Group or member not found

**Implementation Notes:**
- Verify requester has ADMIN or CREATOR role
- Cannot remove creator
- Delete `GroupMember` entry
- Decrement group's `memberCount`
- Remove member's books from group

---

### 12. Regenerate Invite Code

**Endpoint:** `POST /api/v1/groups/:id/regenerate-invite`  
**Authentication:** Required  
**Description:** Generate a new invite code (admin/creator only)

**Request Body (optional):**
```json
{
  "expiresInDays": 7
}
```

**Expected Response (200):**
```json
{
  "inviteCode": "XYZ789ABC",
  "inviteCodeExpiry": "2026-02-17T00:00:00.000Z"
}
```

**Implementation Notes:**
- Verify user has ADMIN or CREATOR role
- Generate new unique 8-character alphanumeric code
- Set expiry if provided
- Invalidates old invite code

---

## 🔄 Transaction-Group Relationship

All transactions are associated with a group. This is **already implemented** in the transaction service.

**Transaction Model:**
```typescript
model Transaction {
  id          String   @id @default(uuid())
  bookId      String
  borrowerId  String
  ownerId     String
  groupId     String   // ✅ Every transaction belongs to a group
  status      TransactionStatus
  ...
  
  group       Group    @relation(fields: [groupId])
}
```

**When Creating a Transaction:**
```typescript
// The book must belong to at least one group
// Transaction uses the first group the book is in
const groupId = book.bookGroups[0]?.groupId;
if (!groupId) throw new Error('Book must belong to at least one group');
```

> [!NOTE]
> Mobile team should ensure books are added to at least one group before allowing borrow requests.

---

## 📱 Mobile Integration Checklist

### Phase 1: Read-Only Group Features
- [ ] Display user's groups (once `GET /groups/my-groups` is implemented)
- [ ] Show group details (once `GET /groups/:id` is implemented)
- [ ] List group members (once `GET /groups/:id/members` is implemented)
- [ ] Filter books by group (✅ already works with `GET /books/feed?groupIds=...`)

### Phase 2: Group Management
- [ ] Create new group (once `POST /groups` is implemented)
- [ ] Join group with invite code (once `POST /groups/join` is implemented)
- [ ] Leave group (once `POST /groups/:id/leave` is implemented)
- [ ] Update group settings (once `PUT /groups/:id` is implemented)

### Phase 3: Book-Group Integration
- [ ] Add books to groups when creating (✅ already works)
- [ ] Update book visibility in groups (✅ already works)
- [ ] View books in specific group (once `GET /groups/:id/books` is implemented)

### Phase 4: Advanced Features
- [ ] Manage member roles (once role endpoints are implemented)
- [ ] Remove members (once `DELETE /groups/:id/members/:userId` is implemented)
- [ ] Regenerate invite codes (once `POST /groups/:id/regenerate-invite` is implemented)

---

## 🎨 UI/UX Recommendations

### Group Categories Icons
```
FRIENDS       → 👥 People icon
OFFICE        → 💼 Briefcase icon
NEIGHBORHOOD  → 🏘️ Houses icon
BOOK_CLUB     → 📚 Books icon
SCHOOL        → 🎓 Graduation cap icon
```

### Privacy Settings Display
```
PUBLIC        → 🌍 Globe icon - "Anyone can join"
PRIVATE       → 🔒 Lock icon - "Invite only"
```

### Member Roles Display
```
CREATOR       → 👑 Crown icon - Full control
ADMIN         → ⭐ Star icon - Can manage members
MODERATOR     → 🛡️ Shield icon - Can moderate content
MEMBER        → 👤 User icon - Regular member
```

---

## 🧪 Testing Recommendations

### Once API is Implemented

**1. Create Group Flow:**
```bash
# Create a new group
curl -X POST https://bookapp-ayushyachitranshs-projects.vercel.app/api/v1/groups \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Group",
    "description": "Testing group creation",
    "category": "FRIENDS",
    "privacy": "PRIVATE"
  }'
```

**2. Join Group Flow:**
```bash
# Join using invite code
curl -X POST https://bookapp-ayushyachitranshs-projects.vercel.app/api/v1/groups/join \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "inviteCode": "ABC123XYZ"
  }'
```

**3. Get User's Groups:**
```bash
curl -X GET https://bookapp-ayushyachitranshs-projects.vercel.app/api/v1/groups/my-groups \
  -H "Authorization: Bearer $TOKEN"
```

**4. Filter Books by Group:**
```bash
# This already works!
curl -X GET "https://bookapp-ayushyachitranshs-projects.vercel.app/api/v1/books/feed?groupIds=group-id-1,group-id-2" \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📞 Backend Team Action Items

> [!CAUTION]
> **Required Before Mobile Integration**
> 
> The backend team must implement the following before mobile team can integrate groups:
> 
> 1. **Create Group Service** (`/backend/src/services/group.service.ts`)
>    - `createGroup()`
>    - `getGroupById()`
>    - `getUserGroups()` (already exists in user service, move here)
>    - `getGroupMembers()`
>    - `getGroupBooks()`
>    - `joinGroup()`
>    - `leaveGroup()`
>    - `updateGroup()`
>    - `deleteGroup()`
>    - `updateMemberRole()`
>    - `removeMember()`
>    - `regenerateInviteCode()`
> 
> 2. **Create Group Controller** (`/backend/src/controllers/group.controller.ts`)
>    - Implement all controller functions for above services
> 
> 3. **Create Group Routes** (`/backend/src/routes/group.routes.ts`)
>    - Define all API endpoints with Swagger documentation
> 
> 4. **Register Routes** (`/backend/src/app.ts`)
>    - Add `app.use('/api/v1/groups', groupRoutes)`
> 
> 5. **Update Swagger Documentation**
>    - Add Groups tag and all endpoint documentation
> 
> 6. **Testing**
>    - Add comprehensive tests for all group operations
>    - Test invite code generation and validation
>    - Test role-based permissions

---

## 🔗 Related Documentation

- [Main API Handover Document](./MOBILE_TEAM_HANDOVER.md) - Complete API reference
- [Database Schema](./prisma/schema.prisma) - Full Prisma schema
- [Authentication Flow](./AUTH_TESTING.md) - Authentication testing guide

---

## 📝 Notes for Mobile Team

1. **Groups are Required for Transactions:** Every book must belong to at least one group before it can be borrowed. Ensure your UI enforces this.

2. **Invite Codes:** Invite codes are case-sensitive and 8 characters long. Consider adding a QR code scanner for easier group joining.

3. **Role Hierarchy:** 
   - CREATOR > ADMIN > MODERATOR > MEMBER
   - Only one CREATOR per group
   - CREATOR cannot leave (must delete group or transfer ownership)

4. **Book Visibility:** When a user adds a book, they select which groups can see it. A book can be visible in multiple groups.

5. **Group Filtering:** The books feed already supports filtering by multiple groups. Use this to show "Books in this group" views.

6. **Member Count Updates:** The backend automatically maintains `memberCount` and `booksCount`. Don't rely on counting array lengths.

7. **Privacy Settings:** 
   - PRIVATE groups require invite code to join
   - PUBLIC groups can be discovered and joined by anyone

---

## ❓ Questions?

For any questions or clarifications about the Groups API implementation, please contact:
- **Backend Team Lead:** [Contact Info]
- **API Documentation:** https://bookapp-ayushyachitranshs-projects.vercel.app/api-docs

---

**Document End**
