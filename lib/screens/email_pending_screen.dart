import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/supabase_auth_service.dart';
import '../services/deep_link_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class EmailPendingScreen extends StatefulWidget {
  final String email;
  
  const EmailPendingScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailPendingScreen> createState() => _EmailPendingScreenState();
}

class _EmailPendingScreenState extends State<EmailPendingScreen>
    with TickerProviderStateMixin {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final DeepLinkService _deepLinkService = DeepLinkService();
  
  bool _isResending = false;
  String? _message;
  
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Listen for deep link auth callbacks
    _deepLinkService.authCallbacks.listen((Uri uri) {
      debugPrint('📧 Email confirmation callback received: $uri');
      _handleAuthCallback(uri);
    });
    
    // Also listen for auth state changes (in case confirmation happens in background)
    _authService.authStateChanges.listen((authState) {
      final user = authState.session?.user;
      if (mounted && user != null && user.emailConfirmedAt != null) {
        debugPrint('✅ Email confirmed via auth state change');
        _showSuccessAndNavigate();
      }
    });
  }
  
  void _handleAuthCallback(Uri uri) async {
    if (mounted) {
      debugPrint('🎉 Processing email confirmation...');
      
      // Extract the authorization code from the deep link
      final code = uri.queryParameters['code'];
      
      if (code != null) {
        try {
          // Exchange the code for a session
          await _authService.confirmEmailWithCode(code);
          
          // The auth state should update automatically, but we can show immediate feedback
          _showSuccessAndNavigate();
        } catch (e) {
          debugPrint('❌ Error confirming email: $e');
          setState(() {
            _message = 'Error confirming email. Please try the link again.';
          });
        }
      } else {
        debugPrint('⚠️ No authorization code found in deep link: ${uri.toString()}');
      }
    }
  }
  
  void _showSuccessAndNavigate() {
    setState(() {
      _message = '✅ Email confirmed successfully! Welcome to Dew.';
    });
    
    _fadeController.forward().then((_) {
      // Give a brief moment for success message, then navigate to authenticated state
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          debugPrint('🚀 Navigating to authenticated state after email confirmation');
          
          // Directly navigate to HomeScreen and clear the navigation stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      });
    });
  }

  Future<void> _resendConfirmation() async {
    if (_isResending) return;
    
    setState(() {
      _isResending = true;
      _message = null;
    });
    
    try {
      // Use password reset as a workaround to resend confirmation
      // This is a common pattern since Supabase doesn't have a direct "resend confirmation" method
      await _authService.resetPassword(widget.email);
      
      if (mounted) {
        setState(() {
          _message = '📧 New confirmation email sent! Check your inbox.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Failed to resend email. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }
  
  void _goBack() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Glass morphic background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.08),
                    AppTheme.accentRed.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          
          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated email icon
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.1),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.email_outlined,
                                size: 40,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Title
                      Text(
                        'Check Your Email',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Instructions
                      Text(
                        'We sent a confirmation link to:',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.darkText.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Email address
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.email,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Instructions text
                      Text(
                        'Click the link in your email to confirm your account. The link will automatically open this app.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.darkText.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      if (_message != null) ...[
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _fadeController,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _message!.startsWith('✅') || _message!.startsWith('📧')
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _message!.startsWith('✅') || _message!.startsWith('📧')
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _message!.startsWith('✅') || _message!.startsWith('📧')
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Resend button
                      CustomButton(
                        text: _isResending ? 'Sending...' : 'Resend Email',
                        onPressed: _isResending ? null : _resendConfirmation,
                        isLoading: _isResending,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Back to login
                      TextButton(
                        onPressed: _goBack,
                        child: Text(
                          'Back to Login',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}