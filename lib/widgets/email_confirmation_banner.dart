import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';

class EmailConfirmationBanner extends StatefulWidget {
  const EmailConfirmationBanner({super.key});

  @override
  State<EmailConfirmationBanner> createState() => _EmailConfirmationBannerState();
}

class _EmailConfirmationBannerState extends State<EmailConfirmationBanner> {
  final _authService = SupabaseAuthService();
  bool _isResending = false;

  bool get _needsConfirmation {
    final user = _authService.currentUser;
    return user?.emailConfirmedAt == null && user?.email != null;
  }

  Future<void> _resendConfirmation() async {
    final user = _authService.currentUser;
    if (user?.email == null) return;

    setState(() => _isResending = true);
    
    try {
      await _authService.resetPassword(user!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 Confirmation email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_needsConfirmation) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.email_outlined, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please confirm your email',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a confirmation link to ${_authService.currentUser?.email}. Click the link to verify your account and unlock all features.',
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isResending ? null : _resendConfirmation,
                child: Text(
                  _isResending ? 'Sending...' : 'Resend Email',
                  style: TextStyle(color: Colors.orange[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}