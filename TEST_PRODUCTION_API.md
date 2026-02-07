# Production API Testing Guide

## Production URL
**Base URL:** `https://bookapp-iota-nine.vercel.app/api/v1`

## Quick Health Check

```bash
# Test health endpoint
curl https://bookapp-iota-nine.vercel.app/health

# Test API info
curl https://bookapp-iota-nine.vercel.app/api/v1

# View API documentation in browser
open https://bookapp-iota-nine.vercel.app/api-docs
```

## Authentication Flow Test

### 1. Send OTP
```bash
curl -X POST https://bookapp-iota-nine.vercel.app/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+919876543210"}'
```

**Expected Response:**
```json
{
  "message": "OTP sent successfully",
  "expiresIn": 300
}
```

> **Note:** In production, check Vercel logs for the OTP code since SMS is not configured.

### 2. Verify OTP (Login)
```bash
# Replace OTP_CODE with the actual OTP from Vercel logs
curl -X POST https://bookapp-iota-nine.vercel.app/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+919876543210",
    "otp": "OTP_CODE"
  }'
```

**Expected Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "...",
    "phoneNumber": "+919876543210",
    "name": "Demo User",
    ...
  }
}
```

### 3. Test Protected Endpoint
```bash
# Replace ACCESS_TOKEN with the token from step 2
export TOKEN="your-access-token-here"

curl -X GET https://bookapp-iota-nine.vercel.app/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"
```

## Book Endpoints Test

### Get Books Feed
```bash
curl -X GET "https://bookapp-iota-nine.vercel.app/api/v1/books/feed?page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN"
```

### Get Available Genres
```bash
curl -X GET https://bookapp-iota-nine.vercel.app/api/v1/books/genres \
  -H "Authorization: Bearer $TOKEN"
```

## iOS App Configuration

The iOS app is already configured to use the production URL:
- **File:** `bookApp/bookApp/bookApp/Services/APIConfiguration.swift`
- **Production URL:** `https://bookapp-iota-nine.vercel.app/api/v1`
- **Current Environment:** `production`

## Testing Checklist

- [x] Backend deployed on Vercel
- [x] Health endpoint responding
- [x] API info endpoint responding
- [x] iOS app configured with production URL
- [ ] Test authentication flow from iOS app
- [ ] Test book browsing from iOS app
- [ ] Test user profile from iOS app
- [ ] Test on iOS Simulator
- [ ] Test on physical iOS device

## How to Test iOS App

### On Simulator
1. Open Xcode
2. Open `bookApp/bookApp/bookApp.xcodeproj`
3. Select a simulator (iPhone 14 Pro or later recommended)
4. Press `Cmd + R` to build and run
5. Test the authentication flow
6. Verify API calls are working

### On Physical Device
1. Connect your iPhone via USB
2. In Xcode, select your device from the device menu
3. Ensure your Apple Developer account is configured
4. Press `Cmd + R` to build and run
5. Test all features including camera (for ISBN scanning)

## Monitoring Production

### View Vercel Logs
1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select the `bookapp` project
3. Click on the latest deployment
4. View **Runtime Logs** to see API requests and OTP codes

### Check for Errors
```bash
# Monitor logs in real-time (if you have Vercel CLI access)
vercel logs --follow
```

## Common Issues

### Issue: "Network request failed"
- **Cause:** iOS App Transport Security blocking HTTP
- **Solution:** Ensure using HTTPS (already configured)

### Issue: "Cannot connect to server"
- **Cause:** Backend cold start on Vercel
- **Solution:** Wait 2-3 seconds and retry

### Issue: "Unauthorized" error
- **Cause:** Token expired or invalid
- **Solution:** Re-authenticate to get a new token

### Issue: OTP not received
- **Cause:** SMS not configured in production
- **Solution:** Check Vercel logs for the OTP code

## Next Steps

1. ✅ Backend is live on Vercel
2. ✅ iOS app is configured
3. ⏳ Test on iOS Simulator
4. ⏳ Test on physical device
5. ⏳ Verify all features work end-to-end

---

**Production API is ready for testing! 🚀**
