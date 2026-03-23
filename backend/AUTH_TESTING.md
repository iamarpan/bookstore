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

**Check console for OTP** - If Twilio is not configured, the OTP will be printed in the server console like:
```
📞 Normalized phone: 8888888888 → +918888888888
📲 WhatsApp to +918888888888: Your BookStore verification code is: 123456
⚠️  Twilio not configured - OTP logged to console only
```

**Note:** Phone numbers without a country code are automatically prefixed with `+91` (India).

**With Twilio configured** - The OTP will be sent via WhatsApp and you'll see:
```
✅ WhatsApp OTP sent to +918888888888 (Message SID: SM...)
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

- **Development Mode**: OTPs are printed to console if Twilio is not configured
- **WhatsApp Setup**: Configure `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_WHATSAPP_FROM` in `.env` to enable WhatsApp delivery
- **Twilio Sandbox**: For testing, use Twilio's WhatsApp Sandbox (users must send join code first)
- **Production WhatsApp**: Requires approved WhatsApp Business Account from Twilio
- **Token Expiry**: Access tokens expire in 15 minutes, refresh tokens in 7 days
- **OTP Expiry**: OTPs expire in 5 minutes
- **Rate Limiting**: Not yet implemented (coming in Phase 11)

## Troubleshooting WhatsApp OTP

### Error 63007: "Could not find a Channel with the specified From address"

**Cause**: You're trying to use a regular Twilio phone number for WhatsApp. WhatsApp requires a separate channel setup.

**Solution**:
1. **For Testing**: Use the Twilio WhatsApp Sandbox
   - Go to: https://console.twilio.com/us1/develop/sms/try-it-out/whatsapp-learn
   - Send the join code (e.g., `join <word>`) from your WhatsApp to the sandbox number
   - Set `TWILIO_WHATSAPP_FROM=whatsapp:+14155238886` (or your sandbox number)
   - **Important**: Every recipient must join the sandbox first

2. **For Production**: Apply for WhatsApp Business API
   - Go to Twilio Console → Messaging → WhatsApp → Senders
   - Request WhatsApp Business Account approval
   - Use your approved number once verified

### Error 21608: "The number is not a valid WhatsApp account"

**Cause**: The recipient hasn't joined the Twilio WhatsApp Sandbox (if using sandbox).

**Solution**: Have the recipient send the join code to the sandbox number first.

### Error 20003: "Authentication Error"

**Cause**: Invalid Account SID or Auth Token.

**Solution**: Double-check your credentials in Twilio Console → Account → API Keys & Tokens.
