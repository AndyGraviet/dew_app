import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/supabase_auth_service.dart';
import 'services/auto_update_service.dart';
import 'services/deep_link_service.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables
  await AppConfig.initialize();
  
  // Initialize window manager
  await windowManager.ensureInitialized();
  
  // Set window properties for portrait-like dimensions
  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 930),
    minimumSize: Size(350, 730),
    maximumSize: Size(500, 1330),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    // Remove window-level transparency to keep cards opaque
    await windowManager.setOpacity(1.0);
    await windowManager.setIgnoreMouseEvents(false);
    // Keep window level normal but maintain transparency
    await windowManager.setAlwaysOnTop(false);
  });
  
  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    // Supabase initialization failed - handle gracefully
    debugPrint('❌ Failed to initialize Supabase: $e');
    // Continue running the app even if Supabase fails to initialize
    // Services will handle the case where Supabase is not available
  }

  // Initialize auto-updater
  try {
    await AutoUpdateService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize auto-updater: $e');
  }

  // Initialize deep link service
  try {
    await DeepLinkService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize deep link service: $e');
  }
  
  await WindowManipulator.initialize();
  await hotKeyManager.unregisterAll();

  WindowManipulator.makeTitlebarTransparent();
  WindowManipulator.enableFullSizeContentView();
  WindowManipulator.hideTitle();
  // Set visual effect for translucent background with glass morphism
  // Using popover material to maintain transparency in inactive state
  WindowManipulator.setMaterial(NSVisualEffectViewMaterial.popover);

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const DewApp());
}

class DewApp extends StatefulWidget {
  const DewApp({super.key});

  @override
  State<DewApp> createState() => _DewAppState();
}

class _DewAppState extends State<DewApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();
  final _authService = SupabaseAuthService();
  
  @override
  void initState() {
    super.initState();
    _registerGlobalHotkey();
  }
  
  Future<void> _registerGlobalHotkey() async {
    HotKey _hotKey = HotKey(
      key: PhysicalKeyboardKey.keyC,
      modifiers: [HotKeyModifier.alt],
      scope: HotKeyScope.system,
    );
    
    await hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) async {
        // Bring app to front
        await windowManager.show();
        await windowManager.focus();
        
        // Trigger add task modal
        homeScreenKey.currentState?.showAddTaskModalFromHotkey();
      },
    );
  }
  
  @override
  void dispose() {
    hotKeyManager.unregisterAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: TitlebarSafeArea(
        child: StreamBuilder<AuthState>(
          stream: _authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                body: Stack(
                  children: [
                    // Glass morphic background even during loading
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
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ),
              );
            }
            
            final session = snapshot.data?.session;
            if (session != null) {
              return HomeScreen(key: homeScreenKey);
            }
            
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}


