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
      
      // Check for updates immediately on startup
      await checkForUpdates();
      
      // Schedule automatic update checks every 24 hours
      await autoUpdater.setScheduledCheckInterval(86400);
      
      _isInitialized = true;
      print('✅ Auto-updater initialized successfully');
    } catch (error) {
      print('❌ Error initializing auto-updater: $error');
    }
  }

  /// Manually check for updates
  Future<void> checkForUpdates({bool silent = true}) async {
    if (!_isDesktopPlatform()) return;

    try {
      if (silent) {
        // Silent check - updates _updateAvailable flag
        _updateAvailable = await _hasUpdate();
      } else {
        // Show update dialog if available
        await autoUpdater.checkForUpdates();
      }
    } catch (error) {
      print('❌ Error checking for updates: $error');
    }
  }

  /// Show update dialog to user
  Future<void> showUpdateDialog(BuildContext context) async {
    if (!_updateAvailable) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.system_update, color: Colors.blue),
              SizedBox(width: 8),
              Text('Update Available'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A new version of Dew is available.'),
              SizedBox(height: 8),
              Text('The update will be downloaded and installed automatically.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _startUpdate();
    }
  }

  /// Check if update is available without showing UI
  Future<bool> _hasUpdate() async {
    try {
      // This would need to be implemented by checking the feed manually
      // For now, we'll use the built-in check
      await autoUpdater.checkForUpdates();
      return false; // The actual check is handled by Sparkle
    } catch (error) {
      print('❌ Error checking update availability: $error');
      return false;
    }
  }

  /// Start the update process
  Future<void> _startUpdate() async {
    try {
      await autoUpdater.checkForUpdates();
    } catch (error) {
      print('❌ Error starting update: $error');
    }
  }

  /// Check if running on desktop platform
  bool _isDesktopPlatform() {
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Get current app version
  String getCurrentVersion() {
    // This will be populated from pubspec.yaml
    return '1.0.0'; // TODO: Get from package info
  }

  /// Show update notification badge
  Widget updateBadge({required Widget child}) {
    if (!_updateAvailable) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
    _updateAvailable = false;
  }
}