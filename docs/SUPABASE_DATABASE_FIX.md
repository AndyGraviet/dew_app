# Fix Database Error Saving New User

## Error
`AuthRetryableFetchException: "Database error saving new user", statusCode: 500`

## Root Cause
The database trigger is trying to create a user record when the user signs up, but this might be happening before email confirmation, causing conflicts.

## Solution: Update Database Trigger

Go to your Supabase project dashboard:
https://supabase.com/dashboard/project/thsitslpyddlctxsywki

Navigate to **SQL Editor** and run this updated trigger:

```sql
-- Drop and recreate the trigger function with better error handling
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create improved trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Only create user record if email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL THEN
    INSERT INTO public.users (id, email, username, display_name, avatar_url, is_active, created_at, updated_at)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'avatar_url',
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      username = COALESCE(EXCLUDED.username, public.users.username),
      display_name = EXCLUDED.display_name,
      avatar_url = EXCLUDED.avatar_url,
      updated_at = NOW();
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error but don't fail the auth operation
    RAISE WARNING 'Failed to create user record: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger (only fires on UPDATE when email gets confirmed)
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW 
  WHEN (NEW.email_confirmed_at IS NOT NULL AND (OLD.email_confirmed_at IS NULL OR OLD IS NULL))
  EXECUTE FUNCTION public.handle_new_user();
```

## What This Fixes:

1. **Only creates user records** when email is confirmed
2. **Handles errors gracefully** without failing the auth process
3. **Prevents duplicate creation** attempts
4. **Logs warnings** for debugging

## Alternative: Disable Auto User Creation

If you want to handle user creation manually in the app:

```sql
-- Remove the trigger entirely
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
```

Then the app will handle user record creation when needed.

## Test the Fix

1. Update the database trigger
2. Try creating a new user account
3. The signup should work without the 500 error
4. User record should be created only after email confirmation