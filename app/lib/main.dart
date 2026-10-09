import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme/theme_manager.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/household_repository.dart';
import 'services/local_prefs_household_repository.dart';
import 'services/local_prefs_auth_service.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Warm up audio engine buffers in background for 0ms first-interaction latency
  RealAudioService().warmUp();
  AuthService authService;
  HouseholdRepository householdRepo;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    authService = FirebaseAuthService(autoRegisterIfNotFound: true);
    householdRepo = FallbackHouseholdRepository(
      primary: FirestoreHouseholdRepository(),
      fallback: LocalPrefsHouseholdRepository(),
    );
  } catch (e) {
    debugPrint("Firebase init or FirebaseAuth failed: $e");
    final localAuth = LocalPrefsAuthService();
    await localAuth.init();
    authService = localAuth;
    householdRepo = LocalPrefsHouseholdRepository();
  }

  final prefs = await SharedPreferences.getInstance();
  final initialThemeName = prefs.getString('selected_theme');
  final themeManager = ThemeManager(initialTheme: initialThemeName);

  runApp(HouseholdStratagemApp(
    authService: authService,
    householdRepo: householdRepo,
    themeManager: themeManager,
  ));
}

class HouseholdStratagemApp extends StatefulWidget {
  final AuthService authService;
  final HouseholdRepository householdRepo;
  final ThemeManager themeManager;
  final AudioService? audioService;

  const HouseholdStratagemApp({
    super.key,
    required this.authService,
    required this.householdRepo,
    required this.themeManager,
    this.audioService,
  });

  @override
  State<HouseholdStratagemApp> createState() => _HouseholdStratagemAppState();
}

class _HouseholdStratagemAppState extends State<HouseholdStratagemApp>
    with WidgetsBindingObserver {
  late final AudioService _audioService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioService = widget.audioService ?? RealAudioService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _audioService.handleAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      notifier: widget.themeManager,
      child: Builder(
        builder: (context) {
          final themeData = ThemeProvider.of(context).currentTheme;
          return MaterialApp(
            title: 'Household Stratagem',
            theme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: themeData.primary,
              scaffoldBackgroundColor: themeData.background,
              colorScheme: ColorScheme.dark(
                primary: themeData.primary,
                secondary: themeData.secondary,
                surface: themeData.surface,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: themeData.surface,
                elevation: 1,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  color: themeData.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            home: SplashScreen(
              authService: widget.authService,
              householdRepo: widget.householdRepo,
            ),
          );
        },
      ),
    );
  }
}
