# GitHub Secrets Setup Guide

To enable automatic building, signing, and notarization of your Dew app, you need to set up the following secrets in your GitHub repository.

## Required GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions → New repository secret

### Apple Developer Certificates (macOS)

1. **APPLE_CERT_DATA**
   - Export your "Developer ID Application" certificate from Keychain Access
   - File → Export Items → Choose .p12 format
   - Convert to base64: `base64 -i certificate.p12 | pbcopy`
   - Paste the base64 string as the secret value

2. **APPLE_CERT_PASSWORD**
   - The password you set when exporting the .p12 certificate

3. **KEYCHAIN_PASSWORD** 
   - Any password for the temporary keychain (e.g., "build-keychain-password")

4. **APPLE_SIGNING_IDENTITY**
   - Your Developer ID Application certificate identity
   - Format: "Developer ID Application: Your Name (TEAM_ID)"
   - Find this in Keychain Access or Apple Developer portal

### Apple Notarization

5. **APPLE_ID**
   - Your Apple ID email address

6. **APPLE_PASSWORD**
   - App-specific password for your Apple ID
   - Generate at: https://appleid.apple.com/account/manage → Sign-In and Security → App-Specific Passwords

7. **APPLE_TEAM_ID**
   - Your Apple Developer Team ID
   - Find at: https://developer.apple.com/account/#!/membership/

### Sparkle Update Signing

8. **SPARKLE_PRIVATE_KEY**
   - Content of the private_key.pem file we generated
   - Run: `cat .secrets/private_key.pem | pbcopy`
   - Paste the entire PEM content including headers

## How to Set Up Each Secret

### 1. Export Apple Developer Certificate

```bash
# Open Keychain Access
# Find your "Developer ID Application" certificate
# Right-click → Export "Developer ID Application: Your Name"
# Save as certificate.p12 with a password
# Convert to base64:
base64 -i certificate.p12 | pbcopy
```

### 2. Generate App-Specific Password

1. Go to https://appleid.apple.com/account/manage
2. Sign-In and Security → App-Specific Passwords
3. Generate new password with label "GitHub Actions Notarization"
4. Copy the generated password

### 3. Find Your Team ID

1. Go to https://developer.apple.com/account/#!/membership/
2. Copy the Team ID (10-character string)

### 4. Find Signing Identity

```bash
# List available identities
security find-identity -v -p codesigning
# Look for "Developer ID Application" certificate
# Copy the full name in quotes
```

### 5. Copy Sparkle Private Key

```bash
# Copy the private key content
cat .secrets/private_key.pem | pbcopy
```

## Verification

After setting up all secrets, you can test the workflow by:

1. Creating a test tag: `git tag v1.0.0-test && git push origin v1.0.0-test`
2. Check the Actions tab in GitHub to see if the workflow runs successfully
3. Verify that all build matrices complete and artifacts are uploaded

## Security Notes

- Never commit certificates or private keys to your repository
- Use app-specific passwords instead of your main Apple ID password
- Regularly rotate app-specific passwords
- The KEYCHAIN_PASSWORD can be any secure password (it's temporary)

## Troubleshooting

- If notarization fails, check that your app-specific password is correct
- If code signing fails, verify the certificate is valid and not expired
- If builds fail, check the Flutter version and dependencies
- View detailed logs in the GitHub Actions tab