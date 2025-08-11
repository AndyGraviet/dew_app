# Supabase Email Authentication Setup

## Issue: Email Confirmation Redirect

When users sign up with email, they receive a confirmation link that currently redirects to `http://localhost:3000`. This needs to be fixed in your Supabase dashboard.

## Steps to Fix:

### 1. Update Redirect URLs in Supabase Dashboard

1. Go to your Supabase project dashboard: https://supabase.com/dashboard/project/thsitslpyddlctxsywki
2. Navigate to **Authentication** → **URL Configuration**
3. Update the following settings:

   **Site URL:**
   ```
   https://andygraviet.github.io/dew_app/
   ```

   **Redirect URLs (add all of these):**
   ```
   https://andygraviet.github.io/dew_app/
   https://andygraviet.github.io/dew_app/auth/callback
   com.dewapp://auth/callback
   dewapp://auth/callback
   ```

### 2. Email Template Configuration

1. In Supabase dashboard, go to **Authentication** → **Email Templates**
2. For the **Confirm signup** template, ensure the confirmation URL uses your domain:
   - The template should contain: `{{ .ConfirmationURL }}`
   - Supabase will automatically use your configured redirect URLs

### 3. How It Works Now

With the current implementation:

1. **Sign Up**: When users sign up, they'll see an error message asking them to confirm their email
2. **Email Confirmation**: Users must click the link in their email before they can sign in
3. **Sign In**: After confirmation, users can sign in normally

### 4. Desktop App Deep Linking (Future Enhancement)

For a better desktop app experience, you could implement deep linking:

1. Register a custom URL scheme (e.g., `dewapp://`)
2. Handle the auth callback in your app
3. This would allow the confirmation link to open directly in your desktop app

For now, users will be redirected to your website after confirming their email, and then they can sign in through the desktop app.

## Current Protection

The app now:
- ✅ Prevents unconfirmed users from accessing the app
- ✅ Shows clear error messages about email confirmation
- ✅ Creates user records only after email confirmation
- ✅ Prevents the "null check operator" error for unconfirmed users

## Testing

1. Sign up with a new email
2. You should see: "Please check your email to confirm your account before signing in."
3. Check your email and click the confirmation link
4. The link will redirect to your configured URL
5. Go back to the app and sign in - it should work now!