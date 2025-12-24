# Authentication API Testing

## Test Authentication Flow

### 1. Send OTP

```bash
curl -X POST http://localhost:3000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+919876543999"}'
```

**Expected Response:**
```json
{
  "message": "OTP sent successfully",
  "expiresIn": 300
}
```

**Check console for OTP** - The OTP will be printed in the server console like:
```
📲 SMS to +919876543999: Your BookStore verification code is: 123456
```

### 2. Verify OTP (New User Registration)

```bash
curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+919876543999",
    "otp": "123456",
    "name": "Test User",
    "bio": "Testing authentication"
  }'
```

**Expected Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "...",
    "phoneNumber": "+919876543999",
    "name": "Test User",
    "email": null,
    "bio": "Testing authentication",
    ...
  }
}
```

### 3. Verify OTP (Existing User Login)

For existing users (like the seeded demo user):

```bash
# First, send OTP
curl -X POST http://localhost:3000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+919876543210"}'

# Then verify (name/bio optional for existing users)
curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+919876543210",
    "otp": "REPLACE_WITH_OTP_FROM_CONSOLE"
  }'
```

### 4. Refresh Token

```bash
curl -X POST http://localhost:3000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "REPLACE_WITH_REFRESH_TOKEN"}'
```

**Expected Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

### 5. Test Protected Route (Coming in next phase)

Once we add user endpoints:

```bash
curl -X GET http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

## Testing with Postman/Insomnia

1. Import the collection (or create manually)
2. Set variables:
   - `base_url`: http://localhost:3000
   - `access_token`: (will be set after login)
   - `refresh_token`: (will be set after login)

3. Run the authentication flow:
   - Send OTP → Copy OTP from server console
   - Verify OTP → Save tokens to variables
   - Use access token for authenticated requests

## Notes

- **Development Mode**: OTPs are printed to console (not sent via SMS)
- **Token Expiry**: Access tokens expire in 15 minutes, refresh tokens in 7 days
- **OTP Expiry**: OTPs expire in 5 minutes
- **Rate Limiting**: Not yet implemented (coming in Phase 11)
