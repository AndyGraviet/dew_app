import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../widgets/pomodoro_timer.dart';

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  bool _isInitialized = false;
  PomodoroTimerController? _timerController;

  // Current timer state
  int _timeLeft = 25 * 60;
  bool _isRunning = false;
  int _completedSessions = 0;
  String _templateName = 'Focus Timer';
  TimerState _currentState = TimerState.work;

  Future<void> initialize(PomodoroTimerController timerController) async {
    if (!Platform.isMacOS || _isInitialized) return;

    _timerController = timerController;
    trayManager.addListener(this);

    try {
      // Try without icon first - just show the title
      await trayManager.setTitle('⏰ 25:00');
      await trayManager.setToolTip('Dew Timer - Click for menu');
      
      debugPrint('🔍 Attempting to set tray icon...');
      
      // Try to set icon - if it fails, we'll still have the title
      try {
        await trayManager.setIcon(
          'assets/icons/tray/timer_idle.png',
          isTemplate: true,
        );
        debugPrint('✅ Tray icon set successfully');
      } catch (iconError) {
        debugPrint('⚠️ Could not set tray icon, using text-only mode: $iconError');
      }
      
      // Set initial context menu
      await _updateContextMenu();
      
      _isInitialized = true;
      debugPrint('✅ Tray service initialized successfully');
      debugPrint('📍 Look for tray icon in macOS menu bar (top-right corner)');
      debugPrint('   If you don\'t see it, check if the menu bar is visible and not hidden');
      debugPrint('   You can also try clicking where the icon should be');
    } catch (e) {
      debugPrint('❌ Failed to initialize tray service: $e');
      debugPrint('   Error details: ${e.toString()}');
      debugPrint('   This might be due to macOS permissions or system tray settings');
      debugPrint('   Try restarting the app or checking macOS System Preferences > Privacy');
    }
  }

  Future<void> updateTimerState({
    required int timeLeft,
    required bool isRunning,
    required int completedSessions,
    required String templateName,
    required TimerState currentState,
  }) async {
    if (!_isInitialized) return;

    _timeLeft = timeLeft;
    _isRunning = isRunning;
    _completedSessions = completedSessions;
    _templateName = templateName;
    _currentState = currentState;

    // Update tray icon based on state
    await _updateTrayIcon();
    
    // Update context menu with current state
    await _updateContextMenu();
  }

  Future<void> _updateTrayIcon() async {
    if (!_isInitialized) return;

    try {
      // For now, we'll just update the tooltip since custom icons may not work
      String stateIcon = '';
      if (_isRunning) {
        switch (_currentState) {
          case TimerState.work:
            stateIcon = '🔵'; // Blue circle for work
            break;
          case TimerState.shortBreak:
          case TimerState.longBreak:
            stateIcon = '🟢'; // Green circle for break
            break;
        }
      } else {
        stateIcon = '⚪'; // White circle for idle
      }
      
      String timeDisplay = _formatTime(_timeLeft);
      await trayManager.setToolTip('$stateIcon Dew Timer: $timeDisplay');
      
      // Update the title shown in menu bar
      if (_isRunning) {
        await trayManager.setTitle('$stateIcon $timeDisplay');
      } else {
        await trayManager.setTitle(timeDisplay);
      }
    } catch (e) {
      debugPrint('Failed to update tray icon: $e');
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  String _getStateDisplayName() {
    final stateInfo = TimerStateInfo.fromState(_currentState);
    return stateInfo.displayName;
  }

  Future<void> _updateContextMenu() async {
    if (!_isInitialized) return;

    final timeDisplay = _formatTime(_timeLeft);
    final stateDisplay = _getStateDisplayName();
    final statusText = _isRunning 
        ? '$stateDisplay - $timeDisplay' 
        : 'Timer Stopped - $timeDisplay';

    final menu = Menu(
      items: [
        MenuItem(
          key: 'status',
          label: statusText,
          disabled: true,
        ),
        MenuItem(
          key: 'template',
          label: _templateName,
          disabled: true,
        ),
        MenuItem(
          key: 'sessions',
          label: 'Sessions completed: $_completedSessions',
          disabled: true,
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'show_hide',
          label: await windowManager.isVisible() ? 'Hide Window' : 'Show Window',
        ),
        MenuItem(
          key: 'toggle_timer',
          label: _isRunning ? '⏸️ Pause Timer' : '▶️ Start Timer',
        ),
        MenuItem(
          key: 'reset_timer',
          label: '🔄 Reset Timer',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: 'Quit App',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() async {
    // Left click - toggle window visibility
    if (await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    // Right click - show context menu (handled automatically by trayManager)
    await _updateContextMenu();
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_hide':
        if (await windowManager.isVisible()) {
          await windowManager.hide();
        } else {
          await windowManager.show();
          await windowManager.focus();
        }
        break;
        
      case 'toggle_timer':
        _timerController?.togglePlayPause();
        break;
        
      case 'reset_timer':
        // For reset, we need to show the window since there's no direct reset method
        // on the controller. The user will need to reset from the UI.
        await windowManager.show();
        await windowManager.focus();
        break;
        
      case 'quit':
        await windowManager.close();
        break;
    }
    
    // Update menu after action
    await Future.delayed(const Duration(milliseconds: 100));
    await _updateContextMenu();
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      trayManager.removeListener(this);
      await trayManager.destroy();
      _isInitialized = false;
    }
  }
}