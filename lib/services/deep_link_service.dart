import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  // Stream controller for auth callbacks
  final StreamController<Uri> _authCallbackController = StreamController<Uri>.broadcast();
  
  // Public stream for listening to auth callbacks
  Stream<Uri> get authCallbacks => _authCallbackController.stream;

  Future<void> initialize() async {
    try {
      // Listen for incoming links when app is already running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          debugPrint('📱 Deep link received: $uri');
          _handleDeepLink(uri);
        },
        onError: (err) {
          debugPrint('❌ Deep link error: $err');
        },
      );

      // Check if app was launched via deep link
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🚀 App launched with deep link: $initialUri');
        _handleDeepLink(initialUri);
      }
      
      debugPrint('✅ Deep link service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize deep link service: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 Processing deep link: ${uri.toString()}');
    
    // Check if this is an auth callback
    if (uri.scheme == 'dewapp' && uri.host == 'auth') {
      debugPrint('🔐 Auth callback detected');
      _authCallbackController.add(uri);
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _authCallbackController.close();
  }
}