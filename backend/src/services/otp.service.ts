import prisma from '../config/database';

/**
 * Generate a 6-digit OTP
 */
export function generateOTP(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Store OTP in database with expiry
 */
export async function storeOTP(phoneNumber: string, otp: string): Promise<void> {
    const expiryMinutes = parseInt(process.env.OTP_EXPIRY_MINUTES || '5');
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + expiryMinutes);

    // Delete any existing OTPs for this phone number
    await prisma.oTPCode.deleteMany({
        where: { phoneNumber },
    });

    // Create new OTP
    await prisma.oTPCode.create({
        data: {
            phoneNumber,
            otpCode: otp,
            expiresAt,
        },
    });

    console.log(`📱 OTP stored for ${phoneNumber}: ${otp} (expires in ${expiryMinutes} minutes)`);
}

/**
 * Check if OTP is valid without consuming it
 */
export async function checkOTP(phoneNumber: string, otp: string): Promise<string | null> {
    const otpRecord = await prisma.oTPCode.findFirst({
        where: {
            phoneNumber,
            otpCode: otp,
            verified: false,
            expiresAt: {
                gt: new Date(),
            },
        },
    });

    return otpRecord?.id || null;
}

/**
 * Consume (mark as verified) an OTP
 */
export async function consumeOTP(otpId: string): Promise<void> {
    await prisma.oTPCode.update({
        where: { id: otpId },
        data: { verified: true },
    });
}

/**
 * Verify OTP (Traditional one-step verification)
 */
export async function verifyOTP(phoneNumber: string, otp: string): Promise<boolean> {
    const otpId = await checkOTP(phoneNumber, otp);

    if (!otpId) {
        return false;
    }

    await consumeOTP(otpId);
    return true;
}

/**
 * Send OTP via WhatsApp (Twilio integration)
 * Falls back to console logging if Twilio is not configured
 */
export async function sendOTPViaWhatsApp(phoneNumber: string, otp: string): Promise<void> {
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    const whatsappFrom = process.env.TWILIO_WHATSAPP_FROM;

    // Normalize phone number - add +91 if not present (for Indian users)
    let normalizedPhone = phoneNumber.trim();
    if (!normalizedPhone.startsWith('+')) {
        // If no country code, assume India (+91)
        normalizedPhone = `+91${normalizedPhone}`;
    }
    console.log(`📞 Normalized phone: ${phoneNumber} → ${normalizedPhone}`);

    // Check if Twilio is configured
    if (!accountSid || !authToken || !whatsappFrom) {
        console.log(`📲 WhatsApp to ${normalizedPhone}: Your BookStore verification code is: ${otp}`);

        const missing = [];
        if (!accountSid) missing.push('TWILIO_ACCOUNT_SID');
        if (!authToken) missing.push('TWILIO_AUTH_TOKEN');
        if (!whatsappFrom) missing.push('TWILIO_WHATSAPP_FROM');

        console.log('⚠️  Twilio not configured - Missing:', missing.join(', '));
        console.log('💡 TIP: If you see this in Vercel, you must add these variables in the Vercel Dashboard (Settings > Environment Variables). .env files are NOT automatically uploaded.');
        return;
    }

    try {
        const twilio = require('twilio');

        // Diagnostic Logging (Redacted)
        console.log('🔧 Twilio Config Diagnostic:');
        console.log(`   - SID: ${accountSid.substring(0, 4)}...${accountSid.substring(accountSid.length - 2)}`);
        console.log(`   - Secret/Token: ${authToken.substring(0, 2)}...${authToken.substring(authToken.length - 2)}`);
        console.log(`   - From: ${whatsappFrom}`);

        // Initialize Twilio client
        // If accountSid starts with 'SK', it's an API Key SID. 
        // In that case, authToken is the API Secret.
        // NOTE: Even with API Keys, some Twilio resources need the Main Account SID.
        // We'll try to initialize with whatever is provided.
        const client = twilio(accountSid, authToken);

        console.log(`📡 Sending WhatsApp OTP to ${normalizedPhone} via Twilio...`);

        // Send WhatsApp message
        const message = await client.messages.create({
            body: `Your BookStore OTP is: ${otp}`,
            from: whatsappFrom,
            to: `whatsapp:${normalizedPhone}`,
        });

        console.log(`✅ WhatsApp OTP sent! SID: ${message.sid}, Status: ${message.status}`);

        if (whatsappFrom === 'whatsapp:+14155238886') {
            console.log('ℹ️  Using Sandbox: Make sure the recipient has joined the sandbox by sending "join <sandbox-code>" to the sandbox number.');
        }
    } catch (error: any) {
        console.error('❌ Failed to send WhatsApp OTP:');
        console.error(`   - Message: ${error.message}`);
        console.error(`   - Code: ${error.code}`);
        console.error(`   - Status: ${error.status}`);

        if (error.code === 21608) {
            console.error('👉 This error means the Sandbox was not joined by the recipient.');
        } else if (error.code === 20003) {
            console.error('👉 This error means your Account SID or Auth Token/Secret is invalid.');
        }

        // Log OTP to console as fallback
        console.log(`📲 FALLBACK - WhatsApp to ${normalizedPhone}: Your BookStore verification code is: ${otp}`);
        throw new Error(`WhatsApp delivery failed: ${error.message}`);
    }
}

/**
 * Clean up expired OTPs (can be run periodically)
 */
export async function cleanupExpiredOTPs(): Promise<void> {
    await prisma.oTPCode.deleteMany({
        where: {
            expiresAt: {
                lt: new Date(),
            },
        },
    });
}
