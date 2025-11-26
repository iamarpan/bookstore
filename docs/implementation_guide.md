# Book Sharing App - Technical Implementation Guide

## Development Roadmap

### Phase 1: MVP (8-10 weeks)
**Core Features:**
- User authentication
- Group creation & management
- Book upload (scan + manual)
- Book browsing & search
- Borrow request workflow
- OTP-based handover/return
- Basic notifications
- My Library management

**Team Structure:**
- 1 Backend Developer
- 2 Mobile Developers (iOS + Android or React Native)
- 1 UI/UX Designer
- 1 QA Engineer
- 1 Project Manager

---

### Phase 2: Enhancements (4-6 weeks)
- In-app chat
- Waitlist feature
- Book reviews & ratings enhancement
- Payment gateway integration
- Advanced analytics dashboard
- Push notification optimization

---

### Phase 3: Scale & Optimize (Ongoing)
- Performance optimization
- Advanced search (Elasticsearch)
- ML-based recommendations
- Web application
- Admin panel

---

## Backend Development Guide

### 1. Project Setup

#### Tech Stack:
```yaml
Language: Node.js (Express) or Python (FastAPI)
Database: PostgreSQL 14+
Cache: Redis 7+
File Storage: AWS S3 / Cloudinary
Authentication: JWT
SMS Gateway: Twilio / AWS SNS
Push Notifications: Firebase Cloud Messaging
Email: SendGrid / AWS SES
```

#### Folder Structure (Node.js/Express):
```
backend/
├── src/
│   ├── config/
│   │   ├── database.js
│   │   ├── redis.js
│   │   └── aws.js
│   ├── middleware/
│   │   ├── auth.js
│   │   ├── validation.js
│   │   └── errorHandler.js
│   ├── models/
│   │   ├── User.js
│   │   ├── Group.js
│   │   ├── Book.js
│   │   └── Transaction.js
│   ├── routes/
│   │   ├── auth.js
│   │   ├── groups.js
│   │   ├── books.js
│   │   ├── transactions.js
│   │   └── notifications.js
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── groupController.js
│   │   ├── bookController.js
│   │   └── transactionController.js
│   ├── services/
│   │   ├── smsService.js
│   │   ├── emailService.js
│   │   ├── uploadService.js
│   │   └── notificationService.js
│   ├── utils/
│   │   ├── otpGenerator.js
│   │   ├── tokenGenerator.js
│   │   └── validators.js
│   └── app.js
├── tests/
├── .env
├── package.json
└── README.md
```

---

### 2. Critical Implementation Details

#### A. OTP Generation & Storage
```javascript
// utils/otpGenerator.js
const crypto = require('crypto');

function generateOTP() {
  return crypto.randomInt(1000, 9999).toString();
}

// Store in Redis with 10-minute expiry
async function storeOTP(transactionId, type, otp) {
  const key = `otp:${transactionId}:${type}`; // type: handover or return
  await redisClient.setex(key, 600, otp); // 600 seconds = 10 minutes
  return key;
}

async function verifyOTP(transactionId, type, inputOTP) {
  const key = `otp:${transactionId}:${type}`;
  const storedOTP = await redisClient.get(key);
  
  if (!storedOTP) {
    throw new Error('OTP expired or not found');
  }
  
  if (storedOTP !== inputOTP) {
    throw new Error('Invalid OTP');
  }
  
  // Delete OTP after successful verification
  await redisClient.del(key);
  return true;
}
```

#### B. Global Book Availability Logic
```javascript
// services/bookService.js
async function checkBookAvailability(bookId) {
  const book = await Book.findById(bookId);
  
  // Check if book is currently in an active transaction
  const activeTransaction = await Transaction.findOne({
    book_id: bookId,
    status: 'active'
  });
  
  if (activeTransaction) {
    return {
      available: false,
      reason: 'currently_lent',
      availableFrom: activeTransaction.due_date
    };
  }
  
  if (!book.is_available) {
    return {
      available: false,
      reason: 'marked_unavailable'
    };
  }
  
  return { available: true };
}

// When transaction becomes active
async function markBookAsLent(bookId, transactionId) {
  await Book.update(
    { 
      status: 'lent',
      current_transaction_id: transactionId 
    },
    { where: { id: bookId } }
  );
}

// When transaction completes
async function markBookAsAvailable(bookId) {
  await Book.update(
    { 
      status: 'available',
      current_transaction_id: null 
    },
    { where: { id: bookId } }
  );
}
```

#### C. Transaction State Machine
```javascript
// controllers/transactionController.js
const TRANSACTION_STATES = {
  PENDING: 'pending',
  APPROVED: 'approved',
  ACTIVE: 'active',
  RETURNED: 'returned',
  REJECTED: 'rejected',
  CANCELLED: 'cancelled'
};

const ALLOWED_TRANSITIONS = {
  pending: ['approved', 'rejected', 'cancelled'],
  approved: ['active', 'cancelled'],
  active: ['returned', 'cancelled'],
  returned: [],
  rejected: [],
  cancelled: []
};

async function updateTransactionStatus(transactionId, newStatus, userId) {
  const transaction = await Transaction.findById(transactionId);
  
  // Validate transition
  if (!ALLOWED_TRANSITIONS[transaction.status].includes(newStatus)) {
    throw new Error(`Cannot transition from ${transaction.status} to ${newStatus}`);
  }
  
  // Update status
  transaction.status = newStatus;
  transaction[`${newStatus}_at`] = new Date();
  
  // Perform side effects based on new status
  switch(newStatus) {
    case 'active':
      await markBookAsLent(transaction.book_id, transaction.id);
      transaction.borrowed_at = new Date();
      transaction.due_date = calculateDueDate(transaction.duration_weeks);
      await sendNotification(transaction.borrower_id, 'handover_confirmed');
      break;
      
    case 'returned':
      await markBookAsAvailable(transaction.book_id);
      transaction.returned_at = new Date();
      transaction.was_on_time = new Date() <= transaction.due_date;
      await sendNotification(transaction.owner_id, 'book_returned');
      await sendNotification(transaction.borrower_id, 'return_confirmed');
      break;
      
    case 'approved':
      await sendNotification(transaction.borrower_id, 'request_approved');
      break;
      
    case 'rejected':
      await sendNotification(transaction.borrower_id, 'request_rejected');
      break;
  }
  
  await transaction.save();
  return transaction;
}
```

#### D. ISBN Book Lookup
```javascript
// services/bookLookupService.js
const axios = require('axios');

async function lookupByISBN(isbn) {
  // Try Google Books API first
  try {
    const response = await axios.get(
      `https://www.googleapis.com/books/v1/volumes?q=isbn:${isbn}`
    );
    
    if (response.data.totalItems > 0) {
      const book = response.data.items[0].volumeInfo;
      return {
        title: book.title,
        author: book.authors?.join(', '),
        cover_image: book.imageLinks?.thumbnail,
        genre: book.categories?.[0],
        publisher: book.publisher,
        year: book.publishedDate?.substring(0, 4),
        pages: book.pageCount,
        language: book.language,
        isbn: isbn
      };
    }
  } catch (error) {
    console.error('Google Books API failed:', error);
  }
  
  // Fallback to Open Library API
  try {
    const response = await axios.get(
      `https://openlibrary.org/api/books?bibkeys=ISBN:${isbn}&format=json&jscmd=data`
    );
    
    const bookData = response.data[`ISBN:${isbn}`];
    if (bookData) {
      return {
        title: bookData.title,
        author: bookData.authors?.map(a => a.name).join(', '),
        cover_image: bookData.cover?.large,
        publisher: bookData.publishers?.[0]?.name,
        year: bookData.publish_date?.substring(0, 4),
        pages: bookData.number_of_pages,
        isbn: isbn
      };
    }
  } catch (error) {
    console.error('Open Library API failed:', error);
  }
  
  throw new Error('Book not found with this ISBN');
}
```

---

### 3. Database Optimization

#### Critical Indexes:
```sql
-- Books feed query optimization
CREATE INDEX idx_books_feed ON books(status, created_at DESC)
  WHERE deleted_at IS NULL;

-- Book visibility in groups (most frequent join)
CREATE INDEX idx_book_visibility_composite 
  ON book_group_visibility(group_id, book_id);

-- Transaction queries
CREATE INDEX idx_transactions_active 
  ON transactions(borrower_id, owner_id, status)
  WHERE status IN ('pending', 'approved', 'active');

-- Overdue detection
CREATE INDEX idx_transactions_overdue 
  ON transactions(due_date)
  WHERE status = 'active' AND due_date < CURRENT_TIMESTAMP;
```

#### Query Performance Tips:
1. **Use materialized views for complex aggregations:**
```sql
CREATE MATERIALIZED VIEW user_stats_mv AS
SELECT 
  user_id,
  COUNT(*) FILTER (WHERE role = 'owner' AND status = 'returned') as successful_lends,
  SUM(lending_fee) FILTER (WHERE role = 'owner' AND status = 'returned') as total_earned,
  AVG(rating) FILTER (WHERE rated_user_id = user_id) as average_rating
FROM transactions
GROUP BY user_id;

-- Refresh periodically (e.g., hourly via cron)
REFRESH MATERIALIZED VIEW user_stats_mv;
```

2. **Cache frequently accessed data in Redis:**
```javascript
// Cache user's groups for 1 hour
async function getUserGroups(userId) {
  const cacheKey = `user:${userId}:groups`;
  
  // Try cache first
  let groups = await redisClient.get(cacheKey);
  if (groups) {
    return JSON.parse(groups);
  }
  
  // Query database
  groups = await Group.findAll({
    include: [{
      model: GroupMembership,
      where: { user_id: userId, status: 'active' }
    }]
  });
  
  // Cache for 1 hour
  await redisClient.setex(cacheKey, 3600, JSON.stringify(groups));
  return groups;
}
```

---

### 4. Background Jobs & Cron

#### Setup (using node-cron):
```javascript
// jobs/scheduler.js
const cron = require('node-cron');

// Check for overdue books every hour
cron.schedule('0 * * * *', async () => {
  const overdueTransactions = await Transaction.findAll({
    where: {
      status: 'active',
      due_date: { [Op.lt]: new Date() },
      is_overdue: false
    }
  });
  
  for (const txn of overdueTransactions) {
    await txn.update({ is_overdue: true });
    await sendNotification(txn.borrower_id, 'book_overdue', {
      book_title: txn.book.title,
      days_overdue: Math.ceil((new Date() - txn.due_date) / (1000 * 60 * 60 * 24))
    });
  }
});

// Send due date reminders (daily at 9 AM)
cron.schedule('0 9 * * *', async () => {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  const dueSoon = await Transaction.findAll({
    where: {
      status: 'active',
      due_date: {
        [Op.gte]: new Date(),
        [Op.lte]: tomorrow
      }
    }
  });
  
  for (const txn of dueSoon) {
    await sendNotification(txn.borrower_id, 'book_due_soon', {
      book_title: txn.book.title,
      due_date: txn.due_date
    });
  }
});

// Refresh materialized views (daily at 2 AM)
cron.schedule('0 2 * * *', async () => {
  await sequelize.query('REFRESH MATERIALIZED VIEW user_stats_mv');
  await sequelize.query('REFRESH MATERIALIZED VIEW group_stats_mv');
});
```

---

### 5. Push Notifications Setup

#### Firebase Cloud Messaging Integration:
```javascript
// services/notificationService.js
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(process.env.FIREBASE_SERVICE_ACCOUNT)
});

async function sendPushNotification(userId, notification) {
  // Get user's FCM tokens (users can have multiple devices)
  const tokens = await UserDevice.findAll({
    where: { user_id: userId },
    attributes: ['fcm_token']
  });
  
  if (tokens.length === 0) return;
  
  const message = {
    notification: {
      title: notification.title,
      body: notification.message
    },
    data: notification.data || {},
    tokens: tokens.map(t => t.fcm_token)
  };
  
  try {
    const response = await admin.messaging().sendMulticast(message);
    console.log(`Sent ${response.successCount} notifications`);
    
    // Remove invalid tokens
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx].fcm_token);
        }
      });
      await UserDevice.destroy({ where: { fcm_token: failedTokens } });
    }
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}
```

---

### 6. File Upload Handling

#### Image Upload to S3:
```javascript
// services/uploadService.js
const AWS = require('aws-sdk');
const sharp = require('sharp');

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY,
  secretAccessKey: process.env.AWS_SECRET_KEY
});

async function uploadImage(buffer, type) {
  // Optimize image
  const optimized = await sharp(buffer)
    .resize(800, 1200, { fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 80 })
    .toBuffer();
  
  const key = `${type}/${Date.now()}-${Math.random().toString(36).substring(7)}.jpg`;
  
  const params = {
    Bucket: process.env.S3_BUCKET,
    Key: key,
    Body: optimized,
    ContentType: 'image/jpeg',
    ACL: 'public-read'
  };
  
  const result = await s3.upload(params).promise();
  return result.Location; // Returns public URL
}
```

---

### 7. API Rate Limiting

```javascript
// middleware/rateLimiter.js
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');

// General API rate limit
const generalLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient
  }),
  windowMs: 60 * 1000, // 1 minute
  max: 100, // 100 requests per minute
  message: 'Too many requests, please try again later.'
});

// Strict limit for auth endpoints
const authLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient
  }),
  windowMs: 60 * 1000,
  max: 5, // 5 requests per minute
  message: 'Too many login attempts, please try again later.'
});

module.exports = { generalLimiter, authLimiter };
```

---

### 8. Testing Strategy

#### Unit Tests (Jest):
```javascript
// tests/unit/otpGenerator.test.js
const { generateOTP, verifyOTP } = require('../../src/utils/otpGenerator');

describe('OTP Generator', () => {
  test('should generate 4-digit OTP', () => {
    const otp = generateOTP();
    expect(otp).toMatch(/^\d{4}$/);
  });
  
  test('should verify correct OTP', async () => {
    const transactionId = 'test-txn-123';
    const otp = '1234';
    await storeOTP(transactionId, 'handover', otp);
    
    const isValid = await verifyOTP(transactionId, 'handover', '1234');
    expect(isValid).toBe(true);
  });
  
  test('should reject incorrect OTP', async () => {
    const transactionId = 'test-txn-456';
    await storeOTP(transactionId, 'handover', '1234');
    
    await expect(verifyOTP(transactionId, 'handover', '9999'))
      .rejects.toThrow('Invalid OTP');
  });
});
```

#### Integration Tests:
```javascript
// tests/integration/transaction.test.js
describe('Borrow Transaction Flow', () => {
  test('should complete full borrow-return cycle', async () => {
    // 1. Create borrow request
    const request = await api.post('/transactions/request')
      .send({ book_id: testBookId, duration_weeks: 2 })
      .set('Authorization', `Bearer ${borrowerToken}`);
    
    expect(request.status).toBe(201);
    const txnId = request.body.data.transaction.id;
    
    // 2. Owner approves
    const approval = await api.post(`/transactions/${txnId}/respond`)
      .send({ action: 'approve' })
      .set('Authorization', `Bearer ${ownerToken}`);
    
    expect(approval.status).toBe(200);
    
    // 3. Generate handover OTP
    const otpResp = await api.post(`/transactions/${txnId}/generate-handover-otp`)
      .set('Authorization', `Bearer ${borrowerToken}`);
    
    const otp = otpResp.body.data.otp;
    
    // 4. Confirm handover
    const confirm = await api.post(`/transactions/${txnId}/confirm-handover`)
      .send({ otp })
      .set('Authorization', `Bearer ${ownerToken}`);
    
    expect(confirm.status).toBe(200);
    
    // 5. Verify book status changed
    const book = await api.get(`/books/${testBookId}`);
    expect(book.body.data.book.status).toBe('lent');
  });
});
```

---

### 9. Deployment Guide

#### Docker Setup:
```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "src/app.js"]
```

#### docker-compose.yml:
```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgres://user:pass@db:5432/bookshare
      REDIS_URL: redis://redis:6379
    depends_on:
      - db
      - redis
  
  db:
    image: postgres:14
    environment:
      POSTGRES_DB: bookshare
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

#### AWS Deployment (Recommended):
- **API:** AWS ECS (Fargate) or AWS App Runner
- **Database:** AWS RDS PostgreSQL
- **Cache:** AWS ElastiCache Redis
- **Storage:** AWS S3
- **CDN:** AWS CloudFront
- **Monitoring:** AWS CloudWatch

---

### 10. Security Checklist

- [ ] All passwords hashed with bcrypt (cost factor 12)
- [ ] JWT tokens with short expiry (24 hours)
- [ ] Refresh tokens stored securely
- [ ] SQL injection prevention (use ORMs with parameterized queries)
- [ ] XSS prevention (sanitize all user inputs)
- [ ] CORS configured properly
- [ ] Rate limiting on all endpoints
- [ ] HTTPS enforced
- [ ] Sensitive data encrypted at rest
- [ ] Environment variables never committed
- [ ] API keys rotated regularly
- [ ] Phone numbers encrypted in database
- [ ] OTPs expire after 10 minutes
- [ ] File upload size limits (5MB for images)
- [ ] File type validation (only images)

---

## Mobile Development Guide

### React Native Implementation Tips

#### 1. State Management (Redux Toolkit):
```javascript
// store/slices/booksSlice.js
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../services/api';

export const fetchBooks = createAsyncThunk(
  'books/fetchBooks',
  async (filters) => {
    const response = await api.get('/books/feed', { params: filters });
    return response.data.data;
  }
);

const booksSlice = createSlice({
  name: 'books',
  initialState: {
    items: [],
    loading: false,
    error: null,
    filters: { groups: null, availability: 'available' }
  },
  reducers: {
    setFilters: (state, action) => {
      state.filters = { ...state.filters, ...action.payload };
    }
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchBooks.pending, (state) => {
        state.loading = true;
      })
      .addCase(fetchBooks.fulfilled, (state, action) => {
        state.loading = false;
        state.items = action.payload.books;
      })
      .addCase(fetchBooks.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      });
  }
});

export const { setFilters } = booksSlice.actions;
export default booksSlice.reducer;
```

#### 2. Camera Integration (QR Scan):
```javascript
// screens/AddBookScreen.js
import { RNCamera } from 'react-native-camera';

const ScanBarcodeScreen = ({ navigation }) => {
  const handleBarCodeScanned = async ({ data }) => {
    try {
      // data contains ISBN
      const response = await api.post('/books/scan', { isbn: data });
      navigation.navigate('BookDetails', { bookInfo: response.data.data.book_info });
    } catch (error) {
      Alert.alert('Error', 'Book not found with this ISBN');
    }
  };

  return (
    <RNCamera
      style={{ flex: 1 }}
      onBarCodeRead={handleBarCodeScanned}
      barCodeTypes={[RNCamera.Constants.BarCodeType.ean13]}
    >
      <View style={styles.overlay}>
        <Text>Scan ISBN barcode</Text>
      </View>
    </RNCamera>
  );
};
```

#### 3. Push Notifications:
```javascript
// services/notificationService.js
import messaging from '@react-native-firebase/messaging';
import { Platform } from 'react-native';

export async function requestNotificationPermission() {
  if (Platform.OS === 'ios') {
    const authStatus = await messaging().requestPermission();
    return authStatus === messaging.AuthorizationStatus.AUTHORIZED;
  }
  return true; // Android doesn't need explicit permission
}

export async function getFCMToken() {
  const token = await messaging().getToken();
  // Send token to backend
  await api.post('/users/me/device', { fcm_token: token, platform: Platform.OS });
  return token;
}

export function setupNotificationListeners() {
  // Foreground messages
  messaging().onMessage(async (remoteMessage) => {
    // Show in-app notification
    showInAppNotification(remoteMessage);
  });

  // Background/Quit messages
  messaging().setBackgroundMessageHandler(async (remoteMessage) => {
    console.log('Background message:', remoteMessage);
  });

  // Notification tap handler
  messaging().onNotificationOpenedApp((remoteMessage) => {
    navigateToScreen(remoteMessage.data);
  });
}
```

---

## Launch Checklist

### Pre-Launch (2 weeks before):
- [ ] Complete all features
- [ ] API documentation finalized
- [ ] Database migration scripts ready
- [ ] All tests passing (unit + integration)
- [ ] Performance testing completed
- [ ] Security audit done
- [ ] Beta testing with 50+ users
- [ ] Bug fixes from beta feedback
- [ ] App Store assets prepared
- [ ] Terms of Service & Privacy Policy live
- [ ] Customer support channels set up

### Launch Week:
- [ ] Deploy backend to production
- [ ] Set up monitoring & alerts
- [ ] Submit apps to stores
- [ ] Prepare marketing materials
- [ ] Set up analytics
- [ ] Create onboarding tutorial
- [ ] Prepare support documentation

### Post-Launch (First Week):
- [ ] Monitor crash reports daily
- [ ] Track key metrics (DAU, retention)
- [ ] Respond to user reviews
- [ ] Hot-fix critical bugs within 24 hours
- [ ] Gather user feedback
- [ ] Plan next iteration

---

**Congratulations! You're ready to build an amazing book sharing app!** 🚀📚