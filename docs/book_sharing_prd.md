# Book Sharing App - Product Requirements Document (PRD)

## 1. Executive Summary

### Vision
A community-driven platform enabling peer-to-peer book lending through organized groups, fostering reading culture and resource sharing.

### Mission
Connect book lovers to build local libraries where physical books circulate efficiently, reducing costs and environmental impact while building community.

### Target Users
- Book enthusiasts who want access to more books without buying
- Library organizers (schools, offices, neighborhoods, book clubs)
- Conscious consumers preferring sharing economy over ownership

---

## 2. Core Features & User Stories

### 2.1 Authentication & Onboarding

**User Stories:**
- As a new user, I want to sign up with email/phone so I can create my account securely
- As a returning user, I want to sign in quickly so I can access my books

**Requirements:**
- Email + Password authentication
- Phone number verification via OTP
- Social login options (Google, Apple) - Phase 2
- Profile setup: Name, Photo, Bio (optional)

### 2.2 Group/Library Management

**User Stories:**
- As a library organizer, I want to create a group with a shareable link so my community can join easily
- As a user, I want to join multiple groups so I can access different book collections
- As a group creator, I want to moderate my group so I can maintain quality

**Requirements:**

**Group Creation:**
- Group name, description, cover image
- Privacy settings: Public (discoverable) or Private (invite-only)
- Shareable invite link with expiry options
- Group categories: Friends, Office, Neighborhood, Book Club, School, etc.

**Group Administration:**
- Creator becomes admin by default
- Admin can add/remove moderators
- Moderators can approve/reject join requests (for private groups)
- Moderators can remove members
- Set group rules (displayed on group page)

**Group Discovery:**
- Browse public groups by category/location
- Search groups by name/description
- Request to join private groups

### 2.3 Book Upload & Management

**User Stories:**
- As a book owner, I want to upload books via QR scan so I can add them quickly
- As a book owner, I want to manually enter book details so I can add books without ISBNs
- As a book owner, I want to set which groups can see my book so I can control visibility
- As a book owner, I want to set a lending price so I can earn from sharing

**Requirements:**

**Upload Methods:**
1. **QR/Barcode Scan:**
   - Scan ISBN barcode
   - Auto-fetch: Title, Author, Cover, Genre, Publisher from Google Books API
   - User confirms and adds custom details

2. **Manual Entry:**
   - Required: Title, Author, Cover image (upload/URL)
   - Optional: Genre, Publisher, Edition, Year, Language, Page count
   - Condition: New, Like New, Good, Fair, Poor

**Book Configuration:**
- Select visibility groups (multi-select from user's joined groups)
- Set weekly lending price (₹0 for free)
- Set availability status (Available/Not Available)
- Add personal notes (visible to borrowers)

**Inventory Management (Critical):**
- **One Book, Multiple Groups:** If a user uploads 1 copy and makes it visible in 3 groups, when borrowed from Group A, it automatically shows "Unavailable" in Groups B & C
- Users can specify quantity (e.g., "I have 2 copies") - Phase 2

### 2.4 Home Screen & Discovery

**User Stories:**
- As a user, I want to see all available books from my groups so I can browse what's available
- As a user, I want to filter books so I can find what I'm looking for quickly
- As a user, I want to see book details so I can make informed borrowing decisions

**Requirements:**

**Home Feed Layout:**
- Default: Books from all joined groups
- Grid/List view toggle
- Book Card displays:
  - Cover image
  - Title & Author
  - Owner name & profile pic
  - Lending price/week
  - Status badge: Available (green) / Lent (grey) / Not Available (red)
  - Action button (context-aware)

**Filter System:**
- **By Group:** Multi-select dropdown of joined groups
- **By Availability:** Available, Lent, All
- **By Genre:** Fiction, Non-fiction, Self-help, Technical, Children, etc.
- **By Price:** Free, Paid, Custom range
- **Sort by:** Recently added, Price (low to high), Popularity

**Book Detail Page:**
- Full book information
- Owner profile (name, rating, books shared count)
- Condition & personal notes
- Reviews from previous borrowers (Phase 2)
- Similar books in the group
- "Borrow" or "Join Waitlist" button

### 2.5 Borrowing Workflow

**User Stories:**
- As a borrower, I want to request a book so the owner knows I'm interested
- As an owner, I want to approve/reject requests so I can control who borrows my books
- As both parties, I want a secure handover process so we confirm the physical exchange

**Requirements:**

**Step 1: Request**
- Borrower clicks "Request to Borrow"
- Modal: Select borrow duration (1 week, 2 weeks, 1 month, custom)
- Add message to owner (optional)
- Submit request

**Step 2: Notification & Approval**
- Owner receives push notification + in-app notification
- Owner views borrower profile (name, photo, rating, borrow history)
- Owner can: Approve / Reject / Counter-offer (different duration/price)
- If approved: System creates a "Transaction" record

**Step 3: Contact Exchange**
- Both parties can now see each other's phone numbers
- In-app chat enabled (Phase 2: before sharing phone)
- Schedule pickup time via chat/phone

**Step 4: Physical Handover (Critical)**

**OTP-Based Confirmation:**
1. System generates 4-digit OTP
2. **Borrower's View:** 
   - Big bold display: "OTP: 4521"
   - Text: "Show this code to [Owner Name] when collecting the book"
   - Button: "I've received the book (enter OTP below)"

3. **Owner's View:**
   - Numeric keypad to enter OTP
   - Text: "Enter the 4-digit code shown on [Borrower Name]'s phone"
   - Once entered correctly: "Handover confirmed! Book marked as lent."

4. **System Actions on Confirmation:**
   - Book status → LENT
   - Start date recorded
   - Expected return date set (start date + duration)
   - Book becomes unavailable in all groups
   - Payment reminder triggered (since offline payment)

**Alternative to OTP (Phase 2):**
- QR code scan: Borrower scans QR from owner's phone

### 2.6 Book Return Process

**User Stories:**
- As a borrower, I want to return a book smoothly so the owner confirms receipt
- As an owner, I want to confirm return and condition so I can lend again

**Requirements:**

**Step 1: Initiate Return**
- Borrower clicks "Arrange Return" on borrowed book
- Schedule return via chat/phone

**Step 2: Return Handover**
- Similar OTP process:
  - Owner generates return OTP
  - Borrower enters OTP on owner's phone
  - System confirms return

**Step 3: Post-Return Actions**
- Owner rates transaction: Book condition (Good/Damaged), Borrower behavior
- Borrower rates transaction: Book as described, Owner responsiveness
- Book status → AVAILABLE
- Book reappears in all visibility groups

**Overdue Handling:**
- System sends reminder 1 day before due date
- If overdue: Daily reminders to borrower
- Owner can "Report Overdue" → Sends escalated notification
- Overdue count affects borrower's reputation

### 2.7 My Library Tab

**User Stories:**
- As a user, I want to see all my books in one place so I can manage my inventory
- As a user, I want to track books I've borrowed so I remember what to return
- As a user, I want to see my lending history so I can track my activity

**Requirements:**

**Three Sub-Tabs:**

1. **My Books**
   - All books user has uploaded
   - Each book shows:
     - Cover, title, status
     - "Visible in X groups" with edit icon
     - If lent: "Lent to [Name], due [Date]"
     - Actions: Edit, Delete, Mark Available/Unavailable

2. **Borrowed Books**
   - Active borrows with countdown to due date
   - Owner contact info
   - "Arrange Return" button
   - Past borrows (collapsed by default)

3. **Lending History**
   - All past transactions where user was owner
   - Filter by: Active, Completed, Overdue
   - Shows: Borrower, book, dates, earnings
   - Analytics: "Total earned: ₹500 from 15 lends"

### 2.8 Notifications

**User Stories:**
- As a user, I want timely notifications so I don't miss important updates

**Notification Types:**
- Borrow request received
- Request approved/rejected
- Book due soon (1 day before)
- Book overdue
- Return requested
- New book added to group (optional, user preference)
- Group announcement from admin

**Channels:**
- Push notifications
- In-app notification center (bell icon)
- Email digest (weekly summary) - Phase 2

### 2.9 Profile & Settings

**User Profile:**
- Display name, photo, bio
- Stats: Books shared, Successful lends, Rating
- Badges: Trusted Lender, Bookworm, etc.
- Public books (optional privacy setting)

**Settings:**
- Notification preferences
- Privacy: Who can see my phone number (After approval only / Group members / Public)
- Language & theme
- Terms, Privacy Policy, Help Center
- Delete account

---

## 3. Enhanced Features (Roadmap)

### Phase 2 (3-6 months)
- **In-app Chat:** Messaging between users
- **Waitlist:** Queue for unavailable books
- **Book Reviews:** Rate & review books after reading
- **Wishlist:** Create reading lists
- **Multiple Copies:** Support for "I have 3 copies"

### Phase 3 (6-12 months)
- **Payment Integration:** Optional online payment for lending fees
- **Delivery Option:** Partner with courier services for non-local exchanges
- **Book Clubs:** Schedule reading events within groups
- **Recommendations:** ML-based book suggestions
- **Public Library Integration:** Borrow from local libraries via app

---

## 4. Non-Functional Requirements

### Performance
- App load time < 2 seconds
- Search results < 1 second
- Image upload < 5 seconds for 5MB file

### Security
- All API calls over HTTPS
- Phone numbers encrypted in database
- OTP expires in 10 minutes
- Rate limiting on login attempts

### Scalability
- Support 10,000 concurrent users
- Database sharding by region

### Compliance
- GDPR compliance for EU users
- Data deletion within 30 days of account deletion

---

## 5. Success Metrics

### Acquisition
- Daily active users (DAU)
- User registrations per day
- Group creation rate

### Engagement
- Books uploaded per user
- Borrow requests per day
- Successful transactions per week

### Retention
- 7-day retention rate
- 30-day retention rate
- Monthly active groups

### Satisfaction
- Average user rating
- App store rating
- NPS score

---

## 6. Out of Scope (V1)

- Audiobooks/Ebooks
- Buying/selling books
- International shipping
- Currency other than local
- Web application (mobile-only for V1)

---

## 7. Open Questions & Decisions Needed

1. **Dispute Resolution:** If a book is not returned or returned damaged, what's the process? (Recommendation: Mediation feature where admin can intervene)

2. **Group Size Limits:** Should we cap group sizes? (Large groups might have too many books to browse)

3. **Premium Features:** Any paid tier for users? (e.g., unlimited groups, priority support)

4. **Moderation:** How to handle inappropriate content or users? (Reporting system + automated flagging)

---

**Next Steps:**
1. Review and approve PRD
2. Create detailed API specifications
3. Design database schema
4. Build wireframes & mockups
5. Develop MVP roadmap