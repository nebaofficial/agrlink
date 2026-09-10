import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/platform_config_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/public/public_dashboard_screen.dart';
import 'services/language_service.dart';
import 'widgets/connectivity_banner.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:agrilink/l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence — essential for rural farmers
  // with intermittent 3G connectivity
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Pre-load platform config before app renders
  final configProvider = PlatformConfigProvider();
  await configProvider.loadConfig();

  runApp(MyApp(configProvider: configProvider));
}

class MyApp extends StatelessWidget {
  final PlatformConfigProvider configProvider;

  const MyApp({super.key, required this.configProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),
        ChangeNotifierProvider<LanguageService>(create: (_) => LanguageService()),
        ChangeNotifierProvider<PlatformConfigProvider>.value(value: configProvider),
      ],
      child: Consumer<LanguageService>(
        builder: (context, langService, _) {
          return MaterialApp(
            title: 'AgriLink',
            theme: AppTheme.lightTheme,
            locale: langService.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('am'),
            ],
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// Routes users based on authentication state:
/// - Not logged in → PublicDashboardScreen (default boot screen, no login required)
/// - Logged in → HomeScreen (role-based navigation)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return ConnectivityBanner(
      child: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // Default boot: public dashboard (no authentication required)
          return const PublicDashboardScreen();
        },
      ),
    );
  }
}
