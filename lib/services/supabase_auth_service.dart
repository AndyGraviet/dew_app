import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart' as app_models;
import '../config/app_config.dart';

class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Configure GoogleSignIn - use iOS client ID for native sign-in
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: AppConfig.googleIosClientId,
  );

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Ensure user record exists in database
  Future<void> _ensureUserRecord(User supabaseUser) async {
    try {
      final email = supabaseUser.email ?? '';
      final username = supabaseUser.userMetadata?['username'] ?? 
                      email.split('@').first;
      final displayName = supabaseUser.userMetadata?['full_name'];

      // First check if user already exists
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('id', supabaseUser.id)
          .maybeSingle();

      if (existingUser == null) {
        // User doesn't exist, create new record
        await _supabase.from('users').insert({
          'id': supabaseUser.id,
          'email': email,
          'username': username,
          'display_name': displayName,
          'avatar_url': supabaseUser.userMetadata?['avatar_url'],
          'bio': supabaseUser.userMetadata?['bio'],
          'is_active': true,
        });
        print('✅ User record created in database for: $email');
      } else {
        print('✅ User record already exists for: $email');
      }
    } catch (error) {
      print('⚠️ Error ensuring user record: $error');
      // Don't rethrow - we want the app to continue working even if user record creation fails
    }
  }

  // Convert Supabase User to app User model
  app_models.User? _convertUser(User? supabaseUser) {
    if (supabaseUser == null) return null;
    
    return app_models.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      username: supabaseUser.userMetadata?['username'] ?? 
                supabaseUser.email?.split('@').first ?? 'user',
      displayName: supabaseUser.userMetadata?['full_name'],
      avatarUrl: supabaseUser.userMetadata?['avatar_url'],
      bio: supabaseUser.userMetadata?['bio'],
      isActive: supabaseUser.userMetadata?['is_active'] ?? true,
      createdAt: DateTime.tryParse(supabaseUser.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.now(), // Supabase auth doesn't track updated_at
    );
  }

  // Sign in with email and password
  Future<app_models.User?> signInWithEmail(String email, String password) async {
    try {
      print('🔄 Signing in with email: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('✅ Email sign-in successful: ${response.user?.email}');
      
      // Ensure user record exists in database
      if (response.user != null) {
        await _ensureUserRecord(response.user!);
      }
      
      return _convertUser(response.user);
    } catch (error) {
      print('❌ Error signing in with email: $error');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<app_models.User?> signUpWithEmail(String email, String password, String name) async {
    try {
      print('🔄 Signing up with email: $email');
      print('🔄 Name: $name');
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'username': email.split('@').first,
        },
      );
      
      print('✅ Email sign-up successful: ${response.user?.email}');
      
      // Ensure user record exists in database
      if (response.user != null) {
        await _ensureUserRecord(response.user!);
      }
      
      return _convertUser(response.user);
    } catch (error) {
      print('❌ Error signing up with email: $error');
      rethrow;
    }
  }


  // Sign in with Google
  Future<app_models.User?> signInWithGoogle() async {
    try {
      print('🔄 Starting Google Sign-In...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('❌ User cancelled Google Sign-In');
        return null;
      }
      
      print('✅ Google Sign-In successful: ${googleUser.email}');
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      
      if (accessToken == null) {
        print('❌ No access token found');
        throw Exception('No access token found');
      }
      
      if (idToken == null) {
        print('❌ No ID token found'); 
        throw Exception('No ID token found');
      }
      
      print('🔄 Signing in to Supabase with Google tokens...');
      
      // Sign in to Supabase with the Google ID token
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      print('✅ Supabase sign-in successful: ${response.user?.email}');
      
      // Ensure user record exists in database
      if (response.user != null) {
        await _ensureUserRecord(response.user!);
      }
      
      return _convertUser(response.user);
      
    } catch (error) {
      print('❌ Error signing in with Google: $error');
      rethrow;
    }
  }

  // Sign out (including Google)
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      // Sign out from Supabase
      await _supabase.auth.signOut();
      print('✅ Signed out successfully');
    } catch (error) {
      print('❌ Error signing out: $error');
      rethrow;
    }
  }

  // Ensure current user record exists in database
  Future<void> ensureCurrentUserRecord() async {
    final user = currentUser;
    if (user != null) {
      await _ensureUserRecord(user);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      print('✅ Password reset email sent to: $email');
    } catch (error) {
      print('❌ Error resetting password: $error');
      rethrow;
    }
  }
}