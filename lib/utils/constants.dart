import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Dew App';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A Y2K-inspired Flutter application';

  // API Constants
  static const String baseUrl = 'https://api.example.com';
  static const int apiTimeout = 30000; // milliseconds
  static const int maxRetries = 3;

  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String userPrefsKey = 'user_preferences';
  static const String authTokenKey = 'auth_token';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Spacing
  static const double xsSpacing = 4.0;
  static const double smSpacing = 8.0;
  static const double mdSpacing = 16.0;
  static const double lgSpacing = 24.0;
  static const double xlSpacing = 32.0;
  static const double xxlSpacing = 48.0;

  // Border Radius
  static const double xsRadius = 4.0;
  static const double smRadius = 8.0;
  static const double mdRadius = 12.0;
  static const double lgRadius = 16.0;
  static const double xlRadius = 24.0;

  // Elevation
  static const double xsElevation = 1.0;
  static const double smElevation = 2.0;
  static const double mdElevation = 4.0;
  static const double lgElevation = 8.0;
  static const double xlElevation = 16.0;

  // Font Sizes
  static const double xsFontSize = 10.0;
  static const double smFontSize = 12.0;
  static const double mdFontSize = 14.0;
  static const double lgFontSize = 16.0;
  static const double xlFontSize = 18.0;
  static const double xxlFontSize = 20.0;
  static const double titleFontSize = 24.0;
  static const double headlineFontSize = 28.0;
  static const double displayFontSize = 32.0;

  // Error Messages
  static const String networkError = 'Network connection error';
  static const String serverError = 'Server error occurred';
  static const String unknownError = 'An unknown error occurred';
  static const String invalidInput = 'Invalid input provided';

  // Success Messages
  static const String operationSuccess = 'Operation completed successfully';
  static const String dataSaved = 'Data saved successfully';
  static const String loginSuccess = 'Login successful';

  // Validation Messages
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidPassword = 'Password must be at least 8 characters';
  static const String passwordMismatch = 'Passwords do not match';

  // Navigation Routes
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
}

class AppColors {
  // Y2K Color Palette
  static const Color hotPink = Color(0xFFFF1493);
  static const Color electricBlue = Color(0xFF00BFFF);
  static const Color limeGreen = Color(0xFF32CD32);
  static const Color purple = Color(0xFF9932CC);
  static const Color orange = Color(0xFFFF8C00);
  static const Color yellow = Color(0xFFFFD700);

  // Neutral Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGrey = Color(0xFF1A1A1A);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color grey = Color(0xFF808080);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradient Colors
  static const List<Color> y2kGradient = [
    hotPink,
    electricBlue,
    limeGreen,
  ];

  static const List<Color> sunsetGradient = [
    hotPink,
    orange,
    yellow,
  ];

  static const List<Color> oceanGradient = [
    electricBlue,
    purple,
    limeGreen,
  ];
}

class AppStrings {
  // Common
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String remove = 'Remove';
  static const String close = 'Close';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String submit = 'Submit';
  static const String confirm = 'Confirm';
  static const String yes = 'Yes';
  static const String no = 'No';

  // Navigation
  static const String home = 'Home';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String about = 'About';
  static const String help = 'Help';
  static const String support = 'Support';

  // Authentication
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String register = 'Register';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String username = 'Username';
  static const String fullName = 'Full Name';

  // Messages
  static const String welcomeMessage = 'Welcome to Dew App!';
  static const String loadingMessage = 'Loading...';
  static const String noDataMessage = 'No data available';
  static const String retryMessage = 'Tap to retry';
  static const String refreshMessage = 'Pull to refresh';
} 