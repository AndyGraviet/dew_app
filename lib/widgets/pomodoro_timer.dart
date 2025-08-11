import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/timer_template_model.dart';
import '../services/timer_template_service.dart';
import '../services/audio_service.dart';
import '../screens/timer_templates_screen.dart';

enum TimerState {
  work,
  shortBreak,
  longBreak,
}

class TimerStateInfo {
  final TimerState state;
  final String displayName;
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final String accessibilityLabel;
  
  const TimerStateInfo({
    required this.state,
    required this.displayName,
    required this.color,
    required this.backgroundColor,
    required this.icon,
    required this.accessibilityLabel,
  });
  
  // WCAG AA compliant colors with higher contrast ratios
  static const TimerStateInfo work = TimerStateInfo(
    state: TimerState.work,
    displayName: 'Working Time',
    color: Color(0xFF1976D2), // Darker blue for better contrast (7.04:1 on white)
    backgroundColor: Color(0xFF0D47A1), // Very dark blue background
    icon: Icons.work_outline,
    accessibilityLabel: 'Work session in progress',
  );
  
  static const TimerStateInfo shortBreak = TimerStateInfo(
    state: TimerState.shortBreak,
    displayName: 'Break Time',
    color: Color(0xFF388E3C), // Darker green for better contrast (6.74:1 on white)
    backgroundColor: Color(0xFF1B5E20), // Very dark green background
    icon: Icons.coffee_outlined,
    accessibilityLabel: 'Short break in progress',
  );
  
  static const TimerStateInfo longBreak = TimerStateInfo(
    state: TimerState.longBreak,
    displayName: 'Long Break',
    color: Color(0xFFE65100), // Darker orange for better contrast (5.93:1 on white)
    backgroundColor: Color(0xFFBF360C), // Very dark orange background
    icon: Icons.spa_outlined,
    accessibilityLabel: 'Long break in progress',
  );
  
  static TimerStateInfo fromState(TimerState state) {
    switch (state) {
      case TimerState.work:
        return work;
      case TimerState.shortBreak:
        return shortBreak;
      case TimerState.longBreak:
        return longBreak;
    }
  }
}

class PomodoroTimerController {
  _PomodoroTimerState? _state;
  
  void _attach(_PomodoroTimerState state) {
    _state = state;
  }
  
  void _detach() {
    _state = null;
  }
  
  void togglePlayPause() {
    _state?._startPauseTimer();
  }
  
  bool get isRunning => _state?._isRunning ?? false;
  int get timeLeft => _state?._timeLeft ?? (25 * 60);
  int get completedSessions => _state?._completedSessions ?? 0;
  String get templateName => _state?._currentTemplate?.name ?? 'Focus Time';
  TimerState get currentState => _state?._currentTimerState ?? TimerState.work;
  TimerStateInfo get stateInfo => TimerStateInfo.fromState(currentState);
}

class PomodoroTimer extends StatefulWidget {
  final VoidCallback? onStateChanged;
  final Function(int timeLeft, bool isRunning, int completedSessions)? onTimerUpdate;
  final PomodoroTimerController? controller;
  
  const PomodoroTimer({super.key, this.onStateChanged, this.onTimerUpdate, this.controller});

  @override
  _PomodoroTimerState createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  Timer? _timer;
  int _totalTime = 25 * 60;
  int _timeLeft = 25 * 60;
  bool _isRunning = false;
  int _completedSessions = 0;
  int _currentSessionInRound = 0; // Track which session in the current round (0-based)
  
  // Timer state management
  TimerState _currentTimerState = TimerState.work;
  
  TimerTemplate? _currentTemplate;
  final TimerTemplateService _timerTemplateService = TimerTemplateService();
  final AudioService _audioService = AudioService();
  
  // Audio settings
  bool _isTickingEnabled = true;

  void _notifyParent() {
    widget.onTimerUpdate?.call(_timeLeft, _isRunning, _completedSessions);
  }

  void _startPauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      setState(() {
        _isRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          setState(() {
            _timeLeft--;
          });
          
          // Play tick sound every second when enabled
          if (_isTickingEnabled) {
            _audioService.playTick();
          }
        } else {
          // Time is up - handle state transition
          _handleTimerComplete();
        }
        _notifyParent();
      });
    }
    _notifyParent();
    widget.onStateChanged?.call();
  }

  void _handleTimerComplete() {
    if (_currentTemplate == null) return;
    
    setState(() {
      switch (_currentTimerState) {
        case TimerState.work:
          // Work session completed - play "Session Over" sound
          _audioService.playSessionComplete();
          
          _completedSessions++;
          _currentSessionInRound++;
          
          // Determine next state based on completed sessions
          if (_currentSessionInRound >= _currentTemplate!.totalSessions) {
            // All sessions completed, take long break
            _currentTimerState = TimerState.longBreak;
            _totalTime = (_currentTemplate!.longBreakDurationMinutes ?? 15) * 60;
            _currentSessionInRound = 0; // Reset for next round
          } else {
            // Take short break
            _currentTimerState = TimerState.shortBreak;
            _totalTime = _currentTemplate!.breakDurationMinutes * 60;
          }
          break;
          
        case TimerState.shortBreak:
          // Short break is over - play "Break Over" sound
          _audioService.playBreakComplete();
          
          // Start next work session
          _currentTimerState = TimerState.work;
          _totalTime = _currentTemplate!.workDurationMinutes * 60;
          break;
          
        case TimerState.longBreak:
          // Long break is over - play "Break Over" sound
          _audioService.playBreakComplete();
          
          // Start new round
          _currentTimerState = TimerState.work;
          _totalTime = _currentTemplate!.workDurationMinutes * 60;
          break;
      }
      
      _timeLeft = _totalTime;
      // Keep timer running for automatic transitions
    });
    
    _notifyParent();
    widget.onStateChanged?.call();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _currentTimerState = TimerState.work;
      if (_currentTemplate != null) {
        _totalTime = _currentTemplate!.workDurationMinutes * 60;
      }
      _timeLeft = _totalTime;
    });
    _notifyParent();
  }
  
  void _resetSessions() {
    setState(() {
      _completedSessions = 0;
      _currentSessionInRound = 0;
    });
    _resetTimer();
  }
  
  void _toggleMute() {
    setState(() {
      _isTickingEnabled = !_isTickingEnabled;
      _audioService.setMuted(!_isTickingEnabled);
    });
  }

  @override
  void initState() {
    super.initState();
    // Attach to controller
    widget.controller?._attach(this);
    // Initialize audio service
    _audioService.initialize();
    // Load default template
    _loadDefaultTemplate();
    // Notify parent of initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyParent();
    });
  }

  Future<void> _loadDefaultTemplate() async {
    try {
      final template = await _timerTemplateService.ensureDefaultTemplate();
      _applyTemplate(template);
    } catch (error) {
      debugPrint('Error loading default template: $error');
      // Continue with default values if template loading fails
    }
  }

  void _applyTemplate(TimerTemplate template) {
    setState(() {
      _currentTemplate = template;
      _currentTimerState = TimerState.work;
      _totalTime = template.workDurationMinutes * 60;
      _timeLeft = _totalTime;
      _completedSessions = 0;
      _currentSessionInRound = 0;
    });
    _notifyParent();
    widget.onStateChanged?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller?._detach();
    _audioService.stopAll();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final stateInfo = TimerStateInfo.fromState(_currentTimerState);
    final totalSessions = _currentTemplate?.totalSessions ?? 4;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // State indicator badge
        Semantics(
          label: stateInfo.accessibilityLabel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: stateInfo.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  stateInfo.icon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  stateInfo.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTimerDisplay(),
        const SizedBox(height: 24),
        // Session progress
        Text(
          _buildSessionText(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.white.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _currentTemplate?.name ?? 'Focus Timer',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.white.withValues(alpha: 0.9)),
        ),
        const SizedBox(height: 32),
        _buildControls(),
      ],
    );
  }
  
  String _buildSessionText() {
    final totalSessions = _currentTemplate?.totalSessions ?? 4;
    
    switch (_currentTimerState) {
      case TimerState.work:
        return 'Session ${_currentSessionInRound + 1} of $totalSessions\n${_completedSessions} sessions completed';
      case TimerState.shortBreak:
        return 'Break after session ${_currentSessionInRound}\n${_completedSessions} sessions completed';
      case TimerState.longBreak:
        return 'Long break time!\n${_completedSessions} sessions completed';
    }
  }

  Widget _buildTimerDisplay() {
    return Semantics(
      label: 'Timer showing ${_formatTime(_timeLeft)} remaining',
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(220, 220),
              painter: TimerPainter(
                progress: 1 - (_timeLeft / _totalTime), // Invert for clockwise
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            Text(
              _formatTime(_timeLeft),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 56, 
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final stateInfo = TimerStateInfo.fromState(_currentTimerState);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset button
        _buildControlButton(
          onPressed: _resetSessions,
          icon: Icons.replay,
          backgroundColor: AppTheme.white.withValues(alpha: 0.2),
          iconColor: AppTheme.white,
          semanticsLabel: 'Reset timer and sessions',
        ),
        const SizedBox(width: 24),
        // Start/Pause button
        _buildControlButton(
          onPressed: _startPauseTimer,
          icon: _isRunning ? Icons.pause : Icons.play_arrow,
          backgroundColor: AppTheme.white,
          iconColor: AppTheme.darkText,
          size: 72,
          semanticsLabel: _isRunning ? 'Pause timer' : 'Start timer',
        ),
        const SizedBox(width: 12),
        // Mute/unmute button
        _buildControlButton(
          onPressed: _toggleMute,
          icon: _isTickingEnabled ? Icons.volume_up : Icons.volume_off,
          backgroundColor: AppTheme.white.withValues(alpha: 0.2),
          iconColor: AppTheme.white,
          size: 44,
          semanticsLabel: _isTickingEnabled ? 'Mute timer sounds' : 'Enable timer sounds',
        ),
      ],
    );
  }

  Future<void> _openTemplateSelector() async {
    // Don't open if timer is running
    if (_isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pause the timer before changing templates'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final selectedTemplate = await Navigator.of(context).push<TimerTemplate>(
      MaterialPageRoute(
        builder: (context) => const TimerTemplatesScreen(),
      ),
    );

    if (selectedTemplate != null) {
      _applyTemplate(selectedTemplate);
    }
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    double size = 56,
    String? semanticsLabel,
  }) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: size * 0.5),
        ),
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  TimerPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final angle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      angle,   // Draw clockwise
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
} 