# Book Sharing App - Mobile App Specifications

## Platform & Technology Stack

### Platforms
- **iOS:** Minimum iOS 14.0
- **Android:** Minimum Android 8.0 (API Level 26)

### Recommended Tech Stack
- **Framework:** React Native or Flutter
- **State Management:** Redux/MobX (React Native) or Provider/Riverpod (Flutter)
- **Navigation:** React Navigation / Flutter Navigator
- **Camera:** react-native-camera or camera plugin
- **Push Notifications:** Firebase Cloud Messaging
- **HTTP Client:** Axios / Dio
- **Local Storage:** AsyncStorage / SharedPreferences
- **Image Handling:** react-native-fast-image / cached_network_image

---

## App Architecture

### Navigation Structure
```
App Root
├── Auth Flow (If not logged in)
│   ├── Welcome Screen
│   ├── Login Screen
│   └── Register Screen
│
└── Main App (Bottom Tab Navigator)
    ├── Home Tab (Stack Navigator)
    │   ├── Home Screen
    │   ├── Book Details Screen
    │   ├── Group Details Screen
    │   └── User Profile Screen (other users)
    │
    ├── Groups Tab (Stack Navigator)
    │   ├── My Groups Screen
    │   ├── Discover Groups Screen
    │   ├── Create Group Screen
    │   └── Group Settings Screen
    │
    ├── Library Tab (Stack Navigator)
    │   ├── My Library Screen (3 tabs: My Books, Borrowed, History)
    │   ├── Add Book Screen
    │   ├── Edit Book Screen
    │   └── Transaction Details Screen
    │
    ├── Notifications Tab
    │   └── Notifications Screen
    │
    └── Profile Tab (Stack Navigator)
        ├── My Profile Screen
        ├── Settings Screen
        └── Edit Profile Screen
```

---

## Screen-by-Screen Specifications

## 1. Authentication Flow

### 1.1 Welcome Screen
**Purpose:** First screen for new users

**UI Elements:**
- App logo and tagline
- Carousel with 3-4 feature highlights:
  - "Share books with your community"
  - "Earn while lending"
  - "Discover new reads nearby"
- Buttons:
  - Primary: "Get Started" → Register
  - Secondary: "I have an account" → Login

**Actions:**
- Navigate to Register/Login

---

### 1.2 Register Screen
**Purpose:** Create new account

**UI Elements:**
- Form fields:
  - Name (text input)
  - Email (email input with validation)
  - Phone Number (phone input with country code selector)
  - Password (secure input with show/hide toggle)
  - Confirm Password
- Profile Picture (optional, camera/gallery picker)
- Checkbox: "I agree to Terms & Conditions"
- Button: "Create Account"
- Link: "Already have an account? Login"

**Validation:**
- Email format check
- Phone number format (10 digits for India)
- Password strength (min 8 chars, 1 uppercase, 1 number)
- Passwords match

**API Flow:**
1. Call `POST /auth/register`
2. On success, navigate to OTP Verification Screen

---

### 1.3 OTP Verification Screen
**Purpose:** Verify phone number

**UI Elements:**
- Text: "We've sent a code to +91-XXXXX-XXX10"
- 4-digit OTP input (auto-focus, auto-submit on completion)
- Timer: "Resend code in 30s"
- Link: "Didn't receive? Resend"
- Button: "Verify"

**API Flow:**
1. Call `POST /auth/verify-phone`
2. On success, store JWT token, navigate to Main App

**Edge Cases:**
- Show error if OTP is incorrect
- Allow resend after 30 seconds
- Auto-fill if SMS permission granted (Android)

---

### 1.4 Login Screen
**Purpose:** Existing users sign in

**UI Elements:**
- Email/Phone input
- Password input (secure, with show/hide)
- Checkbox: "Remember me"
- Button: "Login"
- Link: "Forgot Password?"
- Link: "Don't have an account? Sign up"

**API Flow:**
1. Call `POST /auth/login`
2. Store tokens, navigate to Main App

---

## 2. Home Tab

### 2.1 Home Screen (Feed)
**Purpose:** Browse available books from all joined groups

**UI Components:**

#### Top Section:
- **Search Bar** (sticky header)
  - Placeholder: "Search books or authors"
  - Icon: Magnifying glass
  - On tap: Navigate to Search Screen with full filters

- **Filter Chips** (Horizontal scrollable)
  - "All Groups" (default selected)
  - Individual group chips: "Office Club", "Friends", etc.
  - "Filter" chip with icon (opens filter modal)

#### Filter Modal (Bottom Sheet):
- **Availability:** Radio buttons (Available, Lent, All)
- **Genre:** Multi-select chips (Fiction, Non-fiction, Technical, etc.)
- **Price:** Slider (Free to ₹500/week)
- **Sort by:** Dropdown (Recently Added, Price Low-High, Popular)
- Buttons: "Reset", "Apply"

#### Book Feed:
- **Layout:** Grid (2 columns) or List (toggle in top-right)

**Book Card (Grid View):**
```
┌─────────────────────┐
│                     │
│   [Cover Image]     │
│                     │
├─────────────────────┤
│ Title (2 lines max) │
│ Author              │
│ Owner Name          │
│ ₹50/week            │
│ [Status Badge]      │
└─────────────────────┘
```

**Status Badges:**
- Green: "Available"
- Grey: "Currently Lent"
- Red: "Not Available"
- Blue: "My Book"

**Book Card (List View):**
```
┌──────┬─────────────────────────┐
│      │ Title                   │
│ [Img]│ Author • Genre          │
│      │ Owner Name • ₹50/week   │
│      │ [Available Button]      │
└──────┴─────────────────────────┘
```

**Actions:**
- Tap card → Navigate to Book Details
- Tap "Available" button → Quick borrow modal

**Loading States:**
- Skeleton loaders for cards
- Pull-to-refresh
- Infinite scroll pagination

**Empty State:**
- Icon + Text: "No books available"
- Button: "Discover more groups"

---

### 2.2 Book Details Screen
**Purpose:** Full book information and borrow action

**UI Components:**

#### Header:
- Back button
- Share button (share book within app or externally)

#### Book Section:
- Large cover image (full-width, aspect ratio 3:4)
- Title (large, bold)
- Author
- Genre chips (Fiction, Technology, etc.)
- Condition badge (Like New, Good, etc.)
- Stats: Pages, Year, Publisher, Language

#### Owner Section:
```
┌────────────────────────────────┐
│ [Avatar] John Doe              │
│          ⭐ 4.8 • 12 books     │
│          [View Profile] button │
└────────────────────────────────┘
```

#### Pricing & Availability:
- Large text: "₹50 per week"
- Badge: "Available Now" (green) or "Currently Lent" (grey)
- If lent: "Available from Jan 29"

#### Description:
- "Owner's Notes" section
- Personal notes from owner (expandable if long)

#### Visible In:
- Text: "Shared in: Office Book Club, Friends"

#### Action Buttons:
- **If Available:**
  - Primary button: "Request to Borrow"
  
- **If Lent:**
  - Disabled button: "Currently Unavailable"
  - Secondary button: "Join Waitlist" (Phase 2)

- **If My Book:**
  - "Edit Book" button
  - "Mark as Unavailable" toggle

**Bottom Sheet: Borrow Request Modal**
(Triggered when "Request to Borrow" is tapped)
```
┌────────────────────────────────┐
│ Request to Borrow              │
├────────────────────────────────┤
│ Duration:                      │
│ [1 week] [2 weeks] [1 month]  │
│ [Custom]                       │
│                                │
│ Total: ₹100 (2 weeks × ₹50)   │
│                                │
│ Message to Owner (optional):   │
│ [Text area]                    │
│                                │
│ [Cancel] [Send Request]        │
└────────────────────────────────┘
```

**API Flow:**
1. Call `POST /transactions/request`
2. Show success toast: "Request sent to John Doe!"
3. Navigate back to Home

---

### 2.3 Group Details Screen
**Purpose:** View group info and members

**UI Components:**
- Cover image (banner)
- Group name & category
- Members count, Books count
- "Rules" section (expandable)
- "Members" list (avatars + names)
- "Books in this group" feed (same as home feed, filtered)
- Action button: "Leave Group" (if member)

---

### 2.4 User Profile Screen (Other Users)
**Purpose:** View other user's profile

**UI Components:**
- Profile picture
- Name, Rating (⭐ 4.8)
- Stats: Books Shared, Successful Lends, Member Since
- Badges (Trusted Lender, etc.)
- "Books by [Name]" section (grid of their books)
- Button: "Contact" (if phone visible per privacy settings)

---

## 3. Groups Tab

### 3.1 My Groups Screen
**Purpose:** Manage user's groups

**UI Components:**

#### Header:
- Title: "My Groups"
- Button: "+ Create Group"

#### Tabs:
- "Joined" (default)
- "Created by Me"

#### Group List:
```
┌────────────────────────────────┐
│ [Cover] Office Book Club       │
│         15 members • 47 books  │
│         Admin                  │
└────────────────────────────────┘
```

**Actions:**
- Tap group → Navigate to Group Details
- Swipe actions (iOS) / Long press (Android):
  - Leave Group
  - Share Invite Link

**Empty State:**
- "You're not in any groups yet"
- Button: "Discover Groups"

---

### 3.2 Discover Groups Screen
**Purpose:** Find and join new groups

**UI Components:**
- Search bar: "Search groups"
- Category filters: All, Office, Friends, Neighborhood, etc.
- Group cards with:
  - Cover image
  - Name, Description (2 lines)
  - Privacy badge (Public/Private)
  - Members count
  - Button: "Join" (public) or "Request to Join" (private)

**API Flow:**
1. Call `GET /groups/discover`
2. On "Join": Call `POST /groups/{id}/join`

---

### 3.3 Create Group Screen
**Purpose:** Create new group

**UI Components:**
- Cover image picker (camera/gallery)
- Name input (required)
- Description textarea
- Category dropdown
- Privacy toggle: Public / Private
- Rules textarea (optional)
- Button: "Create Group"

**API Flow:**
1. Call `POST /groups`
2. On success, show invite link modal
3. Navigate to Group Details

**Invite Link Modal:**
```
┌────────────────────────────────┐
│ Group Created! 🎉              │
├────────────────────────────────┤
│ Share this link with your      │
│ community to invite them:      │
│                                │
│ https://bookshare.app/join/... │
│                                │
│ [Copy Link] [Share]            │
└────────────────────────────────┘
```

---

## 4. Library Tab

### 4.1 My Library Screen
**Purpose:** Manage user's books and transactions

**UI Components:**

#### Top Tabs:
1. **My Books**
2. **Borrowed Books**
3. **History**

---

#### Tab 1: My Books

**Analytics Card:**
```
┌────────────────────────────────┐
│ 📚 8 Books Shared              │
│ 💰 ₹1,450 Total Earned         │
│ ⭐ 4.8 Average Rating           │
└────────────────────────────────┘
```

**Book List:**
```
┌──────┬─────────────────────────┐
│      │ The Pragmatic Programmer│
│ [Img]│ Visible in 2 groups     │
│      │ Status: Lent            │
│      │ To: Jane • Due: Jan 24  │
│      │ [Manage] [Edit]         │
└──────┴─────────────────────────┘
```

**Status Indicators:**
- Green: Available
- Orange: Lent (with borrower info)
- Grey: Marked Unavailable

**Actions:**
- "Edit" button → Edit Book Screen
- "Manage" button (if lent) → Transaction Details

**Floating Action Button (FAB):**
- Icon: "+"
- Action: Navigate to Add Book Screen

---

#### Tab 2: Borrowed Books

**Active Borrows:**
```
┌──────┬─────────────────────────┐
│      │ Atomic Habits           │
│ [Img]│ From: John Doe          │
│      │ Due: Jan 24 (9 days)    │
│      │ [Contact] [Arrange Return]│
└──────┴─────────────────────────┘
```

**Countdown Timer:**
- If due < 3 days: Orange text "Due in 2 days"
- If overdue: Red text "Overdue by 1 day"

**Actions:**
- "Contact" → Open phone dialer or chat
- "Arrange Return" → Shows return instructions + generates return OTP

**Empty State:**
- "No active borrows"
- Button: "Browse Books"

---

#### Tab 3: History

**Transaction List:**
```
┌──────┬─────────────────────────┐
│      │ The Clean Coder         │
│ [Img]│ Borrowed from: Mike     │
│      │ Jan 1 - Jan 15          │
│      │ ✅ Returned on time     │
│      │ [View Details]          │
└──────┴─────────────────────────┘
```

**Filters:**
- All, As Owner, As Borrower
- Completed, Overdue

---

### 4.2 Add Book Screen
**Purpose:** Upload new book

**UI Components:**

#### Step 1: Scan or Enter
```
┌────────────────────────────────┐
│ How would you like to add?     │
│                                │
│ [📷 Scan Barcode]              │
│                                │
│ [✍️ Enter Manually]            │
└────────────────────────────────┘
```

#### If Scan Selected:
- Open camera with barcode overlay
- Scan ISBN → Call `POST /books/scan`
- Show fetched details for confirmation

#### If Manual Selected:
- Form with all book fields

#### Step 2: Book Details Form
(Pre-filled if scanned, empty if manual)
- Cover image (camera/gallery/URL)
- Title (required)
- Author (required)
- Genre dropdown
- Publisher, Year, Pages, Language (optional)
- ISBN (auto-filled if scanned)
- Condition dropdown (required)

#### Step 3: Sharing Settings
- "Select groups to share in" (multi-select with checkboxes)
- Lending price input: "₹ ___ per week" (default 0)
- Personal notes textarea
- Toggle: "Available for lending" (default ON)

**Bottom Buttons:**
- "Cancel"
- "Add Book"

**API Flow:**
1. If scanned: `POST /books/scan` → Get details
2. `POST /books` with all data
3. Show success toast: "Book added successfully!"
4. Navigate back to My Library

---

### 4.3 Transaction Details Screen
**Purpose:** Manage active transaction

**UI Components:**

#### Book Info:
- Cover, Title, Author

#### Transaction Info:
```
Status: 🟢 Active
Borrowed: Jan 10, 2025
Due Date: Jan 24, 2025
Days Remaining: 9
Lending Fee: ₹100
```

#### Other Party Info:
```
┌────────────────────────────────┐
│ [Avatar] Jane Smith            │
│          ⭐ 4.9                │
│          📞 +91-XXXXX-XXX09    │
│          [Call] [Chat]         │
└────────────────────────────────┘
```

#### Timeline:
- ✅ Request sent - Jan 9
- ✅ Approved - Jan 9
- ✅ Book handed over - Jan 10
- ⏳ Return pending

#### Action Buttons:
**If Owner:**
- "Report Overdue" (if past due date)
- "Mark as Returned" → Return OTP flow

**If Borrower:**
- "Arrange Return" → Return OTP flow

---

## 5. OTP Handover/Return Screens

### 5.1 Handover Flow

#### Borrower Screen (Shows OTP):
```
┌────────────────────────────────┐
│ 📖 Ready to Collect Book       │
├────────────────────────────────┤
│ Show this code to John Doe:    │
│                                │
│        4  5  2  1              │
│                                │
│ Owner will enter this code     │
│ to confirm handover            │
│                                │
│ [Generate New Code]            │
└────────────────────────────────┘
```

**Features:**
- Large, bold OTP display
- Auto-refresh every 10 minutes
- Copy to clipboard option

**API Flow:**
1. Call `POST /transactions/{id}/generate-handover-otp`
2. Display OTP

---

#### Owner Screen (Enters OTP):
```
┌────────────────────────────────┐
│ 📖 Confirm Handover            │
├────────────────────────────────┤
│ Enter the 4-digit code shown   │
│ on Jane Smith's phone:         │
│                                │
│  [_]  [_]  [_]  [_]            │
│                                │
│ Borrower: Jane Smith           │
│ Book: The Pragmatic Programmer │
│ Duration: 2 weeks              │
│ Due: Jan 24, 2025              │
│                                │
│ [Cancel] [Confirm Handover]    │
└────────────────────────────────┘
```

**Features:**
- Numeric keypad (auto-focus)
- Auto-submit on 4th digit
- Show error if OTP incorrect

**API Flow:**
1. Call `POST /transactions/{id}/confirm-handover` with OTP
2. On success: Show confirmation modal
3. Update book status to "Lent"

**Success Modal:**
```
┌────────────────────────────────┐
│ ✅ Handover Complete!          │
├────────────────────────────────┤
│ Book has been lent to          │
│ Jane Smith                     │
│                                │
│ Return due: Jan 24, 2025       │
│                                │
│ [Done]                         │
└────────────────────────────────┘
```

---

### 5.2 Return Flow
(Identical to handover, but roles reversed)

#### Borrower Screen (Enters OTP):
- Similar to Owner Handover Screen
- Text: "Enter code shown by Owner to confirm return"

#### Owner Screen (Shows OTP):
- Similar to Borrower Handover Screen
- Text: "Show this code to Borrower when receiving book"

**Post-Return:**
- Show rating modal (both parties)

**Rating Modal:**
```
┌────────────────────────────────┐
│ Rate this transaction          │
├────────────────────────────────┤
│ How was your experience?       │
│ ⭐ ⭐ ⭐ ⭐ ⭐                  │
│                                │
│ [Owner only:]                  │
│ Book condition:                │
│ ⭐ ⭐ ⭐ ⭐ ⭐                  │
│                                │
│ Comment (optional):            │
│ [Text area]                    │
│                                │
│ [Skip] [Submit]                │
└────────────────────────────────┘
```

---

## 6. Notifications Tab

### 6.1 Notifications Screen
**Purpose:** View all notifications

**UI Components:**

#### Header:
- Title: "Notifications"
- "Mark all as read" button

#### Notification List:
```
┌────────────────────────────────┐
│ 🔔 New borrow request          │
│    Jane Smith wants to borrow  │
│    "The Pragmatic Programmer"  │
│    2 hours ago                 │
└────────────────────────────────┘
```

**Notification Types & Actions:**
- **Borrow Request:** Tap → Transaction Details (with Approve/Reject)
- **Request Approved:** Tap → Transaction Details
- **Book Due Soon:** Tap → Transaction Details
- **Book Overdue:** Tap → Transaction Details with "Arrange Return"
- **Return Requested:** Tap → Generate Return OTP
- **New Book in Group:** Tap → Book Details

**Visual States:**
- Unread: White background, bold text
- Read: Grey background, normal text

**Empty State:**
- "No new notifications"
- Icon: Bell with slash

---

## 7. Profile Tab

### 7.1 My Profile Screen
**Purpose:** View and edit own profile

**UI Components:**

#### Profile Header:
- Large profile picture (editable)
- Name
- Rating (⭐ 4.8)
- Member since date

#### Stats Section:
```
┌────────────────────────────────┐
│ 📚 12 Books Shared             │
│ 🔄 45 Successful Lends         │
│ 📖 23 Books Borrowed           │
│ 💰 ₹2,450 Total Earned         │
└────────────────────────────────┘
```

#### Badges Section:
- Display earned badges with icons
- "Trusted Lender" "Bookworm" etc.

#### Menu Items:
- Edit Profile
- Settings
- Help & Support
- Terms & Conditions
- Privacy Policy
- Logout

---

### 7.2 Settings Screen
**Purpose:** Configure app preferences

**UI Sections:**

#### Notifications:
- Toggle: Push Notifications
- Toggle: Email Notifications
- Toggle: Borrow Requests
- Toggle: Due Date Reminders
- Toggle: Group Activity Updates

#### Privacy:
- Radio: Phone Number Visibility
  - After approval only (default)
  - Group members
  - Public

#### App Preferences:
- Language selection
- Theme: Light / Dark / System
- Default view: Grid / List (for book feed)

#### Account:
- Change Password
- Delete Account (with confirmation)

---

## 8. Global Components

### 8.1 Bottom Navigation Bar
**Icons & Labels:**
1. Home (House icon)
2. Groups (People icon)
3. Library (Book icon)
4. Notifications (Bell icon) - Shows badge count
5. Profile (Avatar icon)

**Active State:**
- Selected tab: Primary color, bold label
- Unselected: Grey, normal weight

---

### 8.2 Search Screen (Global)
**Triggered from:** Home search bar tap

**UI Components:**
- Search input (auto-focus)
- Recent searches (clearable)
- Search results (same as Home feed)
- Filters (same as Home filters)

---

### 8.3 Chat/Messaging (Phase 2)
**Purpose:** In-app messaging between users

**UI:**
- Simple chat interface
- Text only (no media initially)
- "Book Transaction" context header

---

## 9. Design System

### Color Palette:
- **Primary:** #4A90E2 (Blue)
- **Secondary:** #50C878 (Green)
- **Accent:** #FF6B6B (Red)
- **Background:** #F8F9FA (Light Grey)
- **Text Primary:** #2C3E50 (Dark Grey)
- **Text Secondary:** #7F8C8D (Medium Grey)

### Typography:
- **Headers:** 24px, Bold
- **Sub-headers:** 18px, Semi-Bold
- **Body:** 14px, Regular
- **Captions:** 12px, Regular

### Spacing:
- Standard padding: 16px
- Card margin: 12px
- Element spacing: 8px

### Buttons:
- **Primary:** Blue background, white text, rounded 8px
- **Secondary:** White background, blue border, blue text
- **Disabled:** Grey background, grey text

### Cards:
- White background
- Border radius: 12px
- Shadow: 0 2px 8px rgba(0,0,0,0.1)

---

## 10. Performance Requirements

### Load Times:
- App launch: < 2 seconds
- Screen transitions: < 300ms
- API responses: Loading indicators after 500ms

### Image Optimization:
- Lazy load images
- Cache book covers
- Compress uploads before sending

### Offline Support:
- Cache user's books
- Show cached data while loading
- Queue actions when offline (borrow requests, etc.)

### Memory Management:
- Image memory budget: 100MB
- Clear cache on low memory warning

---

## 11. Error Handling

### Network Errors:
- Show retry button
- "No internet connection" message with icon

### API Errors:
- User-friendly error messages
- Log to crash analytics (Sentry/Crashlytics)

### Validation Errors:
- Inline field errors (red text below field)
- Prevent form submission until fixed

---

## 12. Accessibility

- VoiceOver/TalkBack support for all interactive elements
- Minimum touch target: 44x44 points
- High contrast mode support
- Text scaling support (up to 200%)

---

## 13. Analytics & Tracking

### Events to Track:
- Screen views
- Button clicks (Borrow, Request, etc.)
- API call failures
- User flow drop-offs
- Feature usage (QR scan vs manual entry)

### Tools:
- Firebase Analytics
- Mixpanel (for funnel analysis)

---

## 14. Testing Requirements

### Unit Tests:
- API service functions
- State management logic
- Utility functions

### Integration Tests:
- Complete user flows (Register → Add Book → Borrow)
- OTP verification flow
- Transaction lifecycle

### UI Tests:
- Screenshot tests for key screens
- Cross-device compatibility

### Manual Testing:
- Test on iOS (iPhone 12+) and Android (Samsung S21+)
- Different screen sizes (small, medium, large)
- Low bandwidth simulation

---

## 15. Release Checklist

### Pre-Launch:
- [ ] All API endpoints integrated
- [ ] Push notifications configured
- [ ] App Store/Play Store assets ready
- [ ] Privacy Policy & Terms implemented
- [ ] Crash reporting enabled
- [ ] Analytics configured
- [ ] Beta testing completed (TestFlight/Play Console)

### App Store Requirements:
- **iOS:** App Store screenshots, description, keywords, ratings
- **Android:** Play Store screenshots, feature graphic, description

### Post-Launch:
- Monitor crash reports daily
- Track user feedback
- A/B test key features (Phase 2)