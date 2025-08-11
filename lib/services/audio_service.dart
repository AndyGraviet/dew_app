import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _sessionCompletePlayer = AudioPlayer();
  final AudioPlayer _breakCompletePlayer = AudioPlayer();
  
  bool _isInitialized = false;
  bool _isMuted = false;
  double _volume = 0.5; // Default to 50% volume
  
  static const String _volumeKey = 'timer_audio_volume';
  static const String _mutedKey = 'timer_audio_muted';

  // Initialize audio players
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load saved settings
      await _loadSavedSettings();
      
      // Configure players for low latency
      await _tickPlayer.setReleaseMode(ReleaseMode.stop);
      await _tickPlayer.setPlayerMode(PlayerMode.lowLatency);
      
      await _sessionCompletePlayer.setReleaseMode(ReleaseMode.stop);
      await _sessionCompletePlayer.setPlayerMode(PlayerMode.lowLatency);
      
      await _breakCompletePlayer.setReleaseMode(ReleaseMode.stop);
      await _breakCompletePlayer.setPlayerMode(PlayerMode.lowLatency);
      
      // Set loaded volume
      await setVolume(_volume);
      
      _isInitialized = true;
      debugPrint('✅ Audio service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize audio service: $e');
    }
  }

  // Load saved settings from SharedPreferences
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _volume = prefs.getDouble(_volumeKey) ?? 0.5;
      _isMuted = prefs.getBool(_mutedKey) ?? false;
    } catch (e) {
      debugPrint('Failed to load audio settings: $e');
      // Use defaults
      _volume = 0.5;
      _isMuted = false;
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_volumeKey, _volume);
      await prefs.setBool(_mutedKey, _isMuted);
    } catch (e) {
      debugPrint('Failed to save audio settings: $e');
    }
  }

  // Play tick sound every second
  Future<void> playTick() async {
    if (!_isInitialized || _isMuted) return;
    
    try {
      await _tickPlayer.stop(); // Stop any currently playing tick
      await _tickPlayer.play(AssetSource('sounds/tick.wav'));
    } catch (e) {
      debugPrint('Failed to play tick sound: $e');
    }
  }

  // Play session over sound (work session completed)
  Future<void> playSessionComplete() async {
    if (!_isInitialized || _isMuted) return;
    
    try {
      await _sessionCompletePlayer.stop();
      await _sessionCompletePlayer.play(AssetSource('sounds/sessionover.wav'));
    } catch (e) {
      debugPrint('Failed to play session complete sound: $e');
    }
  }

  // Play break over sound (break completed)
  Future<void> playBreakComplete() async {
    if (!_isInitialized || _isMuted) return;
    
    try {
      await _breakCompletePlayer.stop();
      await _breakCompletePlayer.play(AssetSource('sounds/breakover.wav'));
    } catch (e) {
      debugPrint('Failed to play break complete sound: $e');
    }
  }

  // Legacy method for backwards compatibility
  Future<void> playTimerComplete() async {
    await playSessionComplete();
  }

  // Stop all sounds
  Future<void> stopAll() async {
    await _tickPlayer.stop();
    await _sessionCompletePlayer.stop();
    await _breakCompletePlayer.stop();
  }

  // Mute/unmute
  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      stopAll();
    }
    _saveSettings();
  }

  bool get isMuted => _isMuted;

  // Volume control (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _tickPlayer.setVolume(_volume);
    await _sessionCompletePlayer.setVolume(_volume);
    await _breakCompletePlayer.setVolume(_volume);
    _saveSettings();
  }

  double get volume => _volume;

  // Test volume by playing a tick sound
  Future<void> previewVolume() async {
    if (!_isInitialized) return;
    playTick();
  }

  // Cleanup
  void dispose() {
    _tickPlayer.dispose();
    _sessionCompletePlayer.dispose();
    _breakCompletePlayer.dispose();
  }
}