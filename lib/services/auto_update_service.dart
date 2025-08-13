import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auto_updater/auto_updater.dart';

class AutoUpdateService {
  static final AutoUpdateService _instance = AutoUpdateService._internal();
  factory AutoUpdateService() => _instance;
  AutoUpdateService._internal();

  // Feed URL for appcast.xml (will be hosted on GitHub Pages)
  static const String _feedURL = 'https://AndyGraviet.github.io/dew_app/appcast.xml';
  
  bool _isInitialized = false;
  bool _updateAvailable = false;

  bool get isUpdateAvailable => _updateAvailable;

  /// Initialize auto-updater (call this in main.dart)
  Future<void> initialize() async {
    if (_isInitialized || !_isDesktopPlatform()) return;

    try {
      // Set the feed URL for update checks
      await autoUpdater.setFeedURL(_feedURL);
      
      // Schedule automatic update checks every 24 hours
      await autoUpdater.setScheduledCheckInterval(86400);
      
      // For macOS, Sparkle handles everything automatically
      // The Info.plist settings control the behavior:
      // - SUEnableAutomaticChecks: true (checks on startup and periodically)
      // - SUAutomaticallyUpdate: true (downloads and installs automatically)
      // - SUAllowsAutomaticUpdates: true (enables automatic updates)
      
      _isInitialized = true;
      print('✅ Auto-updater initialized successfully');
      print('📍 Feed URL: $_feedURL');
      print('🔄 Automatic checks enabled (every 24 hours)');
      
      // Note: We don't call checkForUpdates() here because Sparkle
      // automatically checks on app launch when SUEnableAutomaticChecks is true
    } catch (error) {
      print('❌ Error initializing auto-updater: $error');
    }
  }

  /// Manually check for updates
  Future<void> checkForUpdates() async {
    if (!_isDesktopPlatform()) return;

    try {
      // Let Sparkle handle the UI and update process
      // This will show Sparkle's built-in update dialog if an update is available
      await autoUpdater.checkForUpdates();
      print('🔍 Manual update check triggered');
    } catch (error) {
      print('❌ Error checking for updates: $error');
    }
  }

  /// Add menu item or button to manually check for updates
  /// This can be called from settings or menu bar
  Future<void> checkForUpdatesManually() async {
    print('👤 User requested manual update check');
    await checkForUpdates();
  }

  /// Get the current state of automatic updates
  Future<bool> getAutomaticUpdatesEnabled() async {
    if (!_isDesktopPlatform()) return false;
    
    try {
      // This would need plugin support to query Sparkle's state
      // For now, we know it's enabled via Info.plist
      return true;
    } catch (error) {
      print('❌ Error checking automatic update state: $error');
      return false;
    }
  }

  /// Check if running on desktop platform
  bool _isDesktopPlatform() {
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Get current app version from package info
  Future<String> getCurrentVersion() async {
    try {
      // For now return the version from pubspec.yaml
      // In a production app, you'd use package_info_plus:
      // final info = await PackageInfo.fromPlatform();
      // return info.version;
      return '1.2.0'; // Current version
    } catch (error) {
      print('❌ Error getting app version: $error');
      return 'Unknown';
    }
  }

  /// Create a menu item or settings option for update checks
  Widget buildUpdateMenuItem({VoidCallback? onTap}) {
    return ListTile(
      leading: const Icon(Icons.system_update),
      title: const Text('Check for Updates'),
      subtitle: FutureBuilder<String>(
        future: getCurrentVersion(),
        builder: (context, snapshot) {
          return Text('Current version: ${snapshot.data ?? 'Loading...'}');
        },
      ),
      onTap: onTap ?? () => checkForUpdatesManually(),
    );
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
    _updateAvailable = false;
  }
}