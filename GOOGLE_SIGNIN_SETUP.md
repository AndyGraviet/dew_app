# Google Sign-In Setup Guide

## Prerequisites
1. Google Cloud Project created
2. OAuth 2.0 Client IDs created for your platforms

## iOS/macOS Configuration

1. Download your `GoogleService-Info.plist` from Google Cloud Console
2. Add it to your iOS Runner folder: `/ios/Runner/GoogleService-Info.plist`
3. Add it to your macOS Runner folder: `/macos/Runner/GoogleService-Info.plist`

4. Update `/ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

5. Update `/macos/Runner/Info.plist` with the same configuration

## Android Configuration

1. Add your SHA-1 certificate fingerprint to Google Cloud Console
2. Download `google-services.json` from Google Cloud Console
3. Place it in `/android/app/google-services.json`

## Supabase Configuration

1. In Supabase Dashboard:
   - Go to Authentication > Providers
   - Enable Google
   - Add your Google OAuth Client ID and Client Secret

2. In Google Cloud Console:
   - Add Supabase callback URL to authorized redirect URIs:
     `https://YOUR_PROJECT_ID.supabase.co/auth/v1/callback`

## Environment Variables

Create a `.env` file in your project root:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_WEB_CLIENT_ID=your_web_client_id_from_google
```