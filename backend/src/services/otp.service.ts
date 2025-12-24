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
 * Verify OTP
 */
export async function verifyOTP(phoneNumber: string, otp: string): Promise<boolean> {
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

    if (!otpRecord) {
        return false;
    }

    // Mark as verified
    await prisma.oTPCode.update({
        where: { id: otpRecord.id },
        data: { verified: true },
    });

    return true;
}

/**
 * Send OTP via SMS (Twilio integration)
 * For development, we'll just log it
 */
export async function sendOTPViaSMS(phoneNumber: string, otp: string): Promise<void> {
    // TODO: Integrate with Twilio
    // For now, just log the OTP for development
    console.log(`📲 SMS to ${phoneNumber}: Your BookStore verification code is: ${otp}`);

    // In production, use Twilio:
    /*
    const twilio = require('twilio');
    const client = twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );
    
    await client.messages.create({
      body: `Your BookStore verification code is: ${otp}`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phoneNumber
    });
    */
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
