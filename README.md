# Rapit App - SMS OTP Verification

This document provides information on how the SMS OTP verification works in the Rapit app and how to test it.

## SMS OTP Functionality

During signup, the application sends a one-time password (OTP) to the user's phone number for verification. This ensures that the phone number provided is valid and belongs to the user. The app uses Firebase Authentication for phone verification.

### Firebase Authentication Implementation

The app uses Firebase Authentication's phone verification flow:

1. The app initiates phone verification with Firebase
2. Firebase sends an SMS with a verification code to the user's phone
3. The app either auto-detects the SMS code or allows manual entry
4. The code is verified with Firebase to complete authentication

### How It Works

1. When a user signs up, they provide their phone number
2. The app requests verification from Firebase Authentication
3. Firebase sends an SMS with a 6-digit verification code
4. The user enters the code or the app auto-detects it
5. Upon successful verification, the user proceeds to the next screen

## Testing the Firebase Phone Authentication

### Prerequisites

Before testing, ensure you have:

1. Set up Firebase in your project
2. Enabled Phone Authentication in the Firebase Console
3. Added your test phone numbers to the Firebase Console (for testing)
4. Added SHA-1 certificate fingerprint to your Firebase project (for Android)
5. Updated GoogleService-Info.plist (iOS) or google-services.json (Android)

### Testing the Authentication Flow

1. Launch the app and navigate to the signup page
2. Fill in all required fields with a valid phone number
3. Submit the form to start the verification process
4. You will be redirected to the OTP verification page
5. Wait for the SMS to arrive on your device
6. If SMS auto-detection is working, the code will be automatically verified
7. If not, enter the code manually and tap VERIFY
8. Upon successful verification, you will be redirected to the appropriate screen

## Auto-Retrieval of SMS Code

On Android devices, Firebase can automatically read the verification SMS and complete the verification process without manual input. This feature requires:

1. Google Play Services installed on the device
2. Proper configuration of SHA-1/SHA-256 certificate fingerprints in Firebase
3. The SMS to follow a specific format that Firebase can recognize

## Troubleshooting

If verification is not working:

1. Check the console logs for any Firebase Authentication errors
2. Verify that Phone Authentication is enabled in Firebase Console
3. For testing, ensure your phone number is added to the test numbers in Firebase Console
4. Verify that your app is properly connected to Firebase
5. Check your internet connection
6. Try with a different phone number

## Production Implementation Notes

When moving to production:

1. Make sure your Firebase project is on a paid plan to handle production traffic
2. Test on both Android and iOS devices
3. Implement proper error handling for all possible Firebase Authentication errors
4. Consider implementing alternative verification methods for users who don't receive SMS
5. Monitor Firebase usage and quotas

## Notes

- The OTP expires after 2 minutes (Firebase default timeout)
- The app will automatically verify the SMS code on Android if possible
- For security, use appropriate validation rules in your Firestore database
