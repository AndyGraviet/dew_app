import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/supabase_auth_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';
import 'email_pending_screen.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = SupabaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = await _authService.signInWithGoogle();
      
      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('❌ Google sign-in error: $e');
      setState(() {
        _errorMessage = 'Failed to sign in with Google: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = _isSignUp
          ? await _authService.signUpWithEmail(
              _emailController.text,
              _passwordController.text,
              _nameController.text.isEmpty ? 'User' : _nameController.text,
            )
          : await _authService.signInWithEmail(
              _emailController.text,
              _passwordController.text,
            );
      
      if (user != null && mounted) {
        // User signed in successfully
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (_isSignUp && mounted) {
        // Sign up initiated - show email pending screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EmailPendingScreen(email: _emailController.text),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password.';
        });
      }
    } catch (e) {
      print('❌ Email auth error: $e');
      setState(() {
        // Clean up error messages for better UX
        String errorMsg = e.toString();
        if (errorMsg.contains('Please check your email to confirm')) {
          _errorMessage = '📧 Please check your email to confirm your account before signing in.';
        } else if (errorMsg.contains('Please confirm your email')) {
          _errorMessage = '⚠️ Please confirm your email first. Check your inbox for the confirmation link.';
        } else if (errorMsg.contains('Invalid login credentials')) {
          _errorMessage = '❌ Invalid email or password.';
        } else if (errorMsg.contains('User already registered')) {
          _errorMessage = '⚠️ This email is already registered. Please sign in instead.';
        } else {
          // Remove "Exception: " prefix if present
          _errorMessage = errorMsg.replaceAll('Exception: ', '');
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Glass morphic background layer
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.08),
                    AppTheme.accentRed.withOpacity(0.08),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  color: Colors.black.withOpacity(0.05),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isSignUp ? 'Create Account' : 'Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp 
                          ? 'Sign up to get started'
                          : 'Sign in to continue',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Google Sign-In Button
                    CustomButton(
                      text: 'Continue with Google',
                      icon: Icons.g_mobiledata,
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      textColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Divider with "OR"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Theme.of(context).dividerColor.withOpacity(0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Theme.of(context).dividerColor.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Name field (sign up only)
                    if (_isSignUp) ...[ 
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter your name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Email field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      ),
                    ),
                    
                    if (_errorMessage != null || _successMessage != null) ...[ 
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _successMessage != null 
                              ? Colors.green.withOpacity(0.1)
                              : Theme.of(context).colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _successMessage != null
                                ? Colors.green.withOpacity(0.3)
                                : Theme.of(context).colorScheme.error.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _successMessage ?? _errorMessage!,
                          style: TextStyle(
                            color: _successMessage != null
                                ? Colors.green[700]
                                : Theme.of(context).colorScheme.error,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Sign in/up button
                    CustomButton(
                      text: _isSignUp ? 'Sign Up' : 'Sign In',
                      onPressed: _isLoading ? null : _signInWithEmail,
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Toggle sign in/up
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _errorMessage = null;
                          _successMessage = null;
                        });
                      },
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign In'
                            : "Don't have an account? Sign Up",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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