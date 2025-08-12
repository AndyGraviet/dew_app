#!/bin/bash

# Script to download Sparkle command-line tools for the GitHub Actions workflow

SPARKLE_VERSION="2.6.4"
SPARKLE_URL="https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz"

echo "📥 Downloading Sparkle ${SPARKLE_VERSION}..."

# Create directory for Sparkle tools
mkdir -p sparkle_tools
cd sparkle_tools

# Download Sparkle
curl -L -o sparkle.tar.xz "$SPARKLE_URL"

# Extract
tar -xf sparkle.tar.xz

# Copy the command-line tools we need
cp -f Sparkle.framework/Versions/Current/Resources/generate_appcast ./
cp -f Sparkle.framework/Versions/Current/Resources/sign_update ./

# Make them executable
chmod +x generate_appcast
chmod +x sign_update

echo "✅ Sparkle tools downloaded successfully!"
echo "📁 Tools location: $(pwd)"

# Clean up
rm -f sparkle.tar.xz
rm -rf Sparkle.framework

cd ..