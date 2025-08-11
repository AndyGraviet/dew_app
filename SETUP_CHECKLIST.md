# Google Sign-In + Supabase Setup Checklist

## ✅ Completed
- [x] Added Supabase URL and Anon Key
- [x] Added Google Web Client ID
- [x] Created authentication service
- [x] Created login screen with Google Sign-In
- [x] Updated app to handle auth state

## 📋 Required Steps

### 1. Supabase Configuration
Go to your Supabase project dashboard (https://supabase.com/dashboard/project/thsitslpyddlctxsywki):

1. Navigate to **Authentication > Providers**
2. Find **Google** in the list and click to enable it
3. Add your Google OAuth credentials:
   - **Client ID**: `1011903996076-p9104o1s5metrea9cifcb0jsdlugvgqg.apps.googleusercontent.com`
   - **Client Secret**: (from Google Cloud Console)
4. Save the configuration

### 2. Google Cloud Console Configuration
Go to your Google Cloud Console (https://console.cloud.google.com/):

1. Navigate to **APIs & Services > Credentials**
2. Click on your OAuth 2.0 Client ID
3. Add Authorized redirect URIs:
   - Add: `https://thsitslpyddlctxsywki.supabase.co/auth/v1/callback`
4. Save the changes

### 3. Platform-Specific Setup (if needed)

#### For iOS/macOS:
1. Download `GoogleService-Info.plist` from Google Cloud Console
2. Add it to:
   - `/ios/Runner/GoogleService-Info.plist`
   - `/macos/Runner/GoogleService-Info.plist`
3. Update Info.plist files with your reversed client ID

#### For Android:
1. Download `google-services.json` from Google Cloud Console
2. Add it to `/android/app/google-services.json`
3. Ensure your SHA-1 certificate is added in Google Cloud Console

## 🧪 Testing

1. Run the app: `flutter run`
2. Click "Continue with Google"
3. Complete the Google sign-in flow
4. You should be redirected to the home screen

## 🔍 Troubleshooting

If you encounter issues:
1. Check that Google provider is enabled in Supabase
2. Verify the redirect URI is correctly added in Google Cloud Console
3. Ensure you have the correct Client Secret in Supabase
4. Check the console logs for specific error messages

## 📝 Notes
- Your Supabase project: https://supabase.com/dashboard/project/thsitslpyddlctxsywki
- The app will store authentication state locally
- Users can sign out using the logout button in the home screen