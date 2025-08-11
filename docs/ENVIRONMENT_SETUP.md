# Environment Variables Setup Guide

## Overview

This project uses environment variables to manage sensitive configuration like API keys and credentials. This prevents hardcoding sensitive information in the codebase.

## Local Development Setup

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Fill in your credentials in `.env`:**
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_ANON_KEY`: Your Supabase anonymous key
   - `GOOGLE_WEB_CLIENT_ID`: Google OAuth client ID for web
   - `GOOGLE_IOS_CLIENT_ID`: Google OAuth client ID for iOS

3. **Never commit `.env` file** - It's already in `.gitignore`

## GitHub Actions Setup

For CI/CD, you need to add these secrets to your GitHub repository:

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add the following secrets:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `GOOGLE_WEB_CLIENT_ID`
   - `GOOGLE_IOS_CLIENT_ID`

## How It Works

### Local Development
- The app uses `flutter_dotenv` package to load variables from `.env` file
- `AppConfig.initialize()` is called at app startup to load the environment
- Variables are accessed through getters like `AppConfig.supabaseUrl`

### CI/CD Builds
- GitHub Actions runs `scripts/generate_app_config.dart`
- This script reads from environment variables and generates a static `app_config.dart`
- The generated file contains the actual values (no dotenv needed in production)

## Security Benefits

1. **No hardcoded secrets** in version control
2. **Different credentials** for development/production
3. **Easy rotation** - Just update environment variables
4. **Access control** - Only authorized users can see production secrets

## Troubleshooting

### Error: "SUPABASE_URL not found in environment variables"
- Make sure `.env` file exists and contains the variable
- Check that you've run `flutter pub get` to install dependencies
- Verify the `.env` file is in the project root

### CI/CD Build Failures
- Verify all required secrets are added in GitHub Settings
- Check that secret names match exactly (case-sensitive)
- Ensure secrets don't have extra spaces or quotes