import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _completePlayer = AudioPlayer();
  
  bool _isInitialized = false;
  bool _isMuted = false;
  double _volume = 0.5; // Default to 50% volume

  // Initialize audio players
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Configure players for low latency
      await _tickPlayer.setReleaseMode(ReleaseMode.stop);
      await _tickPlayer.setPlayerMode(PlayerMode.lowLatency);
      
      await _completePlayer.setReleaseMode(ReleaseMode.stop);
      await _completePlayer.setPlayerMode(PlayerMode.lowLatency);
      
      // Set initial volume
      await setVolume(_volume);
      
      _isInitialized = true;
      debugPrint('✅ Audio service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize audio service: $e');
    }
  }

  // Play tick sound
  Future<void> playTick() async {
    if (!_isInitialized || _isMuted) return;
    
    try {
      await _tickPlayer.stop(); // Stop any currently playing tick
      await _tickPlayer.play(AssetSource('sounds/tick.mp3'));
    } catch (e) {
      debugPrint('Failed to play tick sound: $e');
    }
  }

  // Play timer complete sound
  Future<void> playTimerComplete() async {
    if (!_isInitialized || _isMuted) return;
    
    try {
      await _completePlayer.stop();
      await _completePlayer.play(AssetSource('sounds/timer_complete.mp3'));
    } catch (e) {
      debugPrint('Failed to play timer complete sound: $e');
    }
  }

  // Stop all sounds
  Future<void> stopAll() async {
    await _tickPlayer.stop();
    await _completePlayer.stop();
  }

  // Mute/unmute
  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      stopAll();
    }
  }

  bool get isMuted => _isMuted;

  // Volume control (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _tickPlayer.setVolume(_volume);
    await _completePlayer.setVolume(_volume);
  }

  double get volume => _volume;

  // Cleanup
  void dispose() {
    _tickPlayer.dispose();
    _completePlayer.dispose();
  }
}