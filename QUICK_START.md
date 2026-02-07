# 🚀 Quick Start - iOS App Testing

## ⚡ Fast Track

### 1. Open Xcode
```bash
cd /Users/ayushyachitransh/development/bookstore/bookApp/bookApp
open bookApp.xcodeproj
```

### 2. Select Device
- **Simulator:** iPhone 15 Pro (or any iPhone 14+)
- **Physical Device:** Your connected iPhone

### 3. Build & Run
- Press `Cmd + R`
- Wait for build to complete
- App launches automatically

### 4. Test Login
- **Phone:** `+919876543210`
- **OTP:** Check Vercel logs at https://vercel.com/dashboard
- Or use any 6-digit code in development mode

---

## 🔗 Important URLs

| Resource | URL |
|----------|-----|
| **Production API** | `https://bookapp-iota-nine.vercel.app/api/v1` |
| **Health Check** | `https://bookapp-iota-nine.vercel.app/health` |
| **API Docs** | `https://bookapp-iota-nine.vercel.app/api-docs` |
| **Vercel Dashboard** | `https://vercel.com/dashboard` |

---

## ✅ Current Status

- ✅ Backend deployed on Vercel
- ✅ Database migrated and seeded
- ✅ iOS app configured for production
- ✅ All API endpoints working
- ✅ Demo data available

---

## 🧪 Quick API Test

```bash
# From project root
cd /Users/ayushyachitransh/development/bookstore
./test-production.sh
```

---

## 📱 What to Test

1. **Authentication** - Login with phone + OTP
2. **Books Feed** - Browse available books
3. **Book Details** - View individual book info
4. **User Profile** - Check profile and stats
5. **Groups** - View and join groups
6. **Search** - Search for books
7. **Filters** - Filter by genre, price, etc.

---

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Can't connect | Wait 2-3 seconds (cold start) |
| Unauthorized | Re-login to get fresh token |
| No OTP | Check Vercel Runtime Logs |
| Build fails | Clean build folder: `Cmd + Shift + K` |

---

## 📚 Full Documentation

- **iOS Testing Guide:** `/Users/ayushyachitransh/development/bookstore/iOS_TESTING_GUIDE.md`
- **API Testing Guide:** `/Users/ayushyachitransh/development/bookstore/TEST_PRODUCTION_API.md`
- **Backend Deployment:** `/Users/ayushyachitransh/development/bookstore/backend/DEPLOYMENT.md`

---

**Ready to test! 🎉**
