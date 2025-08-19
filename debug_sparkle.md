# Debugging Sparkle Auto-Updates

## Things to check:

1. **Check the app's actual version**:
   - Right-click on dew_app.app → Show Package Contents
   - Open Contents/Info.plist
   - Look for CFBundleShortVersionString - this should be "1.2.2"

2. **Check Console.app for Sparkle logs**:
   - Open Console.app
   - Start capturing logs
   - Filter for "dew" or "Sparkle"
   - Click "Check for Updates" in your app
   - Look for any error messages

3. **Common issues**:
   - **Code signing**: Sparkle might reject updates if code signing doesn't match
   - **Network**: Firewall or proxy blocking GitHub
   - **Version format**: Sparkle expects semantic versioning (1.2.3)
   - **SUFeedURL mismatch**: The Info.plist feed URL must match exactly

4. **Manual Sparkle test**:
   If you have Sparkle tools installed:
   ```bash
   # Check if your app can read the appcast
   curl -I https://AndyGraviet.github.io/dew_app/appcast.xml
   ```

5. **Verify the running app's Info.plist has**:
   - SUFeedURL: https://AndyGraviet.github.io/dew_app/appcast.xml
   - SUPublicEDKey: MCowBQYDK2VwAyEAXE/VHKpnX9zyT5GzHbFPGkPTJeTdoT+sRTG01GPisXo=
   - SUEnableAutomaticChecks: true

## Potential fix:

The issue might be that the auto_updater Flutter plugin isn't properly triggering Sparkle. We might need to add a native call to force Sparkle to check.