import * as admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT;

if (serviceAccountKey) {
    try {
        let credential;
        if (serviceAccountKey.startsWith('{') || serviceAccountKey.startsWith('ew')) {
            const jsonKey = serviceAccountKey.startsWith('ew')
                ? Buffer.from(serviceAccountKey, 'base64').toString('utf8')
                : serviceAccountKey;
            credential = admin.credential.cert(JSON.parse(jsonKey));
        } else {
            credential = admin.credential.cert(serviceAccountKey);
        }

        admin.initializeApp({
            credential: credential
        });
        console.log('Firebase Admin initialized successfully');
    } catch (error) {
        console.error('Failed to initialize Firebase Admin:', error);
    }
} else {
    console.warn('FIREBASE_SERVICE_ACCOUNT not set. Push notifications will not be sent.');
}

export default admin;
