# Dew App Deployment Guide

This guide covers the complete deployment setup for the Dew productivity app, including auto-updates, GitHub Actions, and distribution website.

## 🚀 Quick Start

1. **Set up GitHub Secrets** (see GITHUB_SECRETS_SETUP.md)
2. **Enable GitHub Pages** in repository settings
3. **Create a release tag** to trigger the build pipeline
4. **Users can download** from your GitHub Pages site

## 📁 Project Structure

```
dew_app/
├── .github/workflows/release.yml    # Automated build & release
├── .secrets/                        # Sparkle signing keys (gitignored)
├── docs/                            # GitHub Pages website
│   ├── _config.yml                 # Jekyll configuration
│   ├── _layouts/default.html       # Website template
│   ├── index.html                  # Main download page
│   ├── appcast.xml                 # Sparkle update feed
│   └── assets/                     # CSS, JS, images
├── lib/services/auto_update_service.dart  # Auto-update logic
├── macos/Runner/Info.plist         # Sparkle configuration
└── GITHUB_SECRETS_SETUP.md         # Secret setup instructions
```

## 🔧 Features Implemented

### ✅ Auto-Update System
- **Sparkle Framework**: Native macOS auto-updates
- **Cross-platform**: Windows and Linux support via auto_updater package  
- **Signed Updates**: EdDSA signatures for security
- **Automatic Checks**: Daily update checks with user notifications

### ✅ GitHub Actions Pipeline
- **Multi-platform Builds**: macOS (Intel/Apple Silicon), Windows, Linux
- **Code Signing**: Apple Developer certificates for macOS
- **Notarization**: Automatic Apple notarization for macOS apps
- **Release Automation**: Creates GitHub releases with all binaries

### ✅ Distribution Website
- **GitHub Pages**: Professional download site
- **Platform Detection**: Automatically detects user's OS
- **Responsive Design**: Works on all devices
- **Real-time Data**: Pulls release info from GitHub API

### ✅ Update Feed
- **Sparkle Appcast**: XML feed for auto-updates
- **Jekyll Generation**: Automatically generated from releases
- **Secure Signatures**: Each update is cryptographically signed

## 🛠 Setup Instructions

### 1. Repository Setup

Make sure your repository is set up correctly:

```bash
# If not already a git repository
git init
git add .
git commit -m "Initial commit with deployment setup"

# Push to GitHub (replace with your repository URL)
git remote add origin https://github.com/andygraviet/dew_app.git
git push -u origin main
```

### 2. GitHub Pages Configuration

1. Go to repository Settings → Pages
2. Source: Deploy from a branch
3. Branch: `main` / `docs`
4. Click Save

Your site will be available at: `https://andygraviet.github.io/dew_app/`

### 3. GitHub Secrets Setup

Follow the detailed instructions in `GITHUB_SECRETS_SETUP.md` to configure:

- Apple Developer certificates
- Notarization credentials  
- Sparkle signing keys

### 4. First Release

Create your first release to test the pipeline:

```bash
# Update version in pubspec.yaml first
git add .
git commit -m "Prepare for v1.0.0 release"
git tag v1.0.0
git push origin main --tags
```

This will trigger the GitHub Actions workflow to:
1. Build apps for all platforms
2. Sign and notarize macOS apps
3. Create GitHub release with binaries
4. Update the website and appcast.xml

## 🔄 Release Process

### Automated Releases (Recommended)

1. Update version in `pubspec.yaml`
2. Commit changes
3. Create and push a git tag:
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```
4. GitHub Actions handles the rest automatically

### Manual Releases

You can also trigger releases manually:

1. Go to Actions tab in GitHub
2. Select "Build and Release" workflow
3. Click "Run workflow"
4. Enter version number (e.g., v1.1.0)

## 📱 User Experience

### Download Process
1. Users visit your GitHub Pages site
2. Platform is automatically detected
3. Appropriate download button is highlighted
4. Files are served directly from GitHub Releases

### Auto-Update Process
1. App checks for updates on startup and daily
2. If update available, user sees notification
3. User clicks "Update" → Download starts
4. Update installs automatically and app restarts

## 🔍 Monitoring & Analytics

### Release Analytics
- Download counts available in GitHub Releases
- Website analytics via GitHub Pages (if configured)
- User agent data from download requests

### Update Analytics  
The auto-update service includes hooks for analytics:

```dart
// In auto_update_service.dart
void trackDownload(String platform) {
    // Integrate with your analytics service
    analytics.track('app_download', {'platform': platform});
}
```

## 🛡 Security Features

### Code Signing
- **macOS**: Apple Developer ID certificates
- **Windows**: Authenticode signing (optional)
- **Verification**: Automatic signature validation

### Update Security
- **EdDSA Signatures**: Each update is cryptographically signed
- **HTTPS Only**: All downloads over secure connections
- **Notarization**: Apple-verified malware scanning

## 🐛 Troubleshooting

### Build Issues
- Check GitHub Actions logs in the Actions tab
- Verify all secrets are configured correctly
- Ensure Flutter version matches workflow

### Update Issues
- Verify appcast.xml is accessible
- Check Sparkle signatures are valid
- Confirm feed URL in Info.plist matches GitHub Pages

### Website Issues
- GitHub Pages can take a few minutes to update
- Check Jekyll build logs in Actions tab
- Verify _config.yml configuration

## 📈 Performance Optimizations

### Build Speed
- Dependencies are cached between runs
- Matrix builds run in parallel
- Artifacts are compressed for faster uploads

### Download Speed
- CDN delivery via GitHub
- Optimized binary sizes
- Delta updates (future enhancement)

### Website Performance
- CSS/JS minification
- Image optimization
- Lazy loading for large assets

## 🔮 Future Enhancements

### Planned Features
- [ ] Delta updates for smaller downloads
- [ ] Beta channel support
- [ ] Crash reporting integration
- [ ] Usage analytics dashboard
- [ ] Windows code signing
- [ ] Linux package repositories

### Community Features
- [ ] User feedback system
- [ ] Feature request voting
- [ ] Community-driven translations
- [ ] Plugin system

## 📞 Support

### For Developers
- Check the GitHub Actions logs for build issues
- Review the auto_update_service.dart for update logic
- Modify the Jekyll templates for website changes

### For Users
- Download issues: Check system requirements
- Update issues: Restart the app to retry
- General support: Create GitHub issue

---

**Built with ❤️ using Flutter, GitHub Actions, and Sparkle**