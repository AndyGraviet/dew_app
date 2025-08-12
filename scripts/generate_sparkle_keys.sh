#!/bin/bash

# Script to generate Ed25519 key pair for Sparkle auto-updater

echo "🔑 Generating Sparkle Ed25519 key pair..."

# Create a temporary directory for keys
mkdir -p temp_keys
cd temp_keys

# Generate Ed25519 private key
openssl genpkey -algorithm ed25519 -out sparkle_private_key.pem

# Extract public key
openssl pkey -in sparkle_private_key.pem -pubout -out sparkle_public_key.pem

# Convert public key to base64 format for Info.plist
PUBLIC_KEY_BASE64=$(openssl pkey -in sparkle_private_key.pem -pubout -outform DER | base64 | tr -d '\n')

echo ""
echo "✅ Keys generated successfully!"
echo ""
echo "📋 IMPORTANT: Save these values:"
echo ""
echo "1. PUBLIC KEY for Info.plist (SUPublicEDKey):"
echo "   $PUBLIC_KEY_BASE64"
echo ""
echo "2. PRIVATE KEY for GitHub Secrets (SPARKLE_PRIVATE_KEY):"
echo "   Copy the entire content below including BEGIN/END lines:"
echo ""
cat sparkle_private_key.pem
echo ""
echo "⚠️  SECURITY NOTES:"
echo "   - Keep the private key SECRET - never commit it to your repository"
echo "   - Add the private key to GitHub Secrets as SPARKLE_PRIVATE_KEY"
echo "   - The public key goes in your Info.plist file"
echo ""
echo "📁 Keys saved in: $(pwd)"
echo "   - sparkle_private_key.pem (KEEP THIS SECRET!)"
echo "   - sparkle_public_key.pem (for reference)"

# Move back to parent directory
cd ..