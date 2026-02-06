import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'config/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/accessibility_provider.dart';
import 'providers/connectivity_provider.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/dashboard/home_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/events/create_event_screen.dart';
import 'screens/events/gig_detail_screen.dart';
import 'screens/connections/connections_screen.dart';
import 'screens/reports/create_report_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/messages/chat_screen.dart';
import 'screens/premium/subscription_screen.dart';
import 'screens/portfolio/portfolio_screen.dart';
import 'screens/portfolio/ratings_screen.dart';
import 'screens/portfolio/upload_media_screen.dart';
import 'screens/rankings/rankings_screen.dart';
import 'screens/settings/blocked_users_screen.dart';
import 'screens/connections/connection_requests_screen.dart';
import 'screens/profile/unified_profile_screen.dart';
import 'screens/events/event_history_screen.dart';
import 'screens/events/event_calendar_screen.dart';
import 'screens/events/event_invitations_screen.dart';
import 'screens/settings/change_password_screen.dart';
import 'screens/settings/help_center_screen.dart';
import 'screens/settings/terms_screen.dart';
import 'screens/settings/privacy_policy_screen.dart';
import 'screens/settings/notifications_settings_screen.dart';
import 'screens/settings/privacy_settings_screen.dart';
import 'screens/settings/account_settings_screen.dart';
import 'screens/settings/suspend_account_screen.dart';
import 'screens/settings/delete_account_screen.dart';
import 'screens/settings/cache_settings_screen.dart';
import 'screens/settings/font_size_screen.dart';
import 'screens/settings/accessibility_screen.dart';
import 'screens/settings/data_usage_screen.dart';
import 'screens/settings/sound_settings_screen.dart';
import 'screens/settings/change_email_screen.dart';
import 'screens/settings/language_screen.dart';
import 'widgets/connectivity_wrapper.dart';

// Handler para notificaciones en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Handling background message: ${message.messageId}');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp();
    debugPrint('✅ Firebase inicializado');
    
    // Configurar handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background handler configurado');
    
    // Inicializar Supabase
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseKey,
    );
    debugPrint('✅ Supabase inicializado');
    
    // Inicializar NotificationService
    await NotificationService.initialize();
    
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error initializing app: $e');
    runApp(ErrorApp(message: e.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[900],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Error de Inicialización',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Configuración de rutas
    final GoRouter router = GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.status == AuthStatus.authenticated;
        final isLoggingIn = state.uri.toString() == '/login';
        final isRegistering = state.uri.toString() == '/register';
        final isForgotPassword = state.uri.toString() == '/forgot-password';
        final isAtRoot = state.uri.toString() == '/';
        
        debugPrint('ROUTER: path=${state.uri}, status=${authProvider.status}, isLoggedIn=$isLoggedIn');

        if (authProvider.status == AuthStatus.checking) return null;

        if (!isLoggedIn) {
          return (isLoggingIn || isRegistering || isForgotPassword) ? null : '/login';
        }

        if (isLoggedIn) {
          if (isLoggingIn || isAtRoot || isRegistering) return '/dashboard';
        }
        
        return null;
      },
      routes: [
         GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/create-event',
          builder: (context, state) => const CreateEventScreen(),
        ),
        GoRoute(
          path: '/connections',
          builder: (context, state) => const ConnectionsScreen(),
        ),
        GoRoute(
          path: '/create-report',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final reportedUserId = extra['reportedUserId'] as int? ?? 0;
            final reportedUserName = extra['reportedUserName'] as String? ?? 'User';
            return CreateReportScreen(
              reportedUserId: reportedUserId,
              reportedUserName: reportedUserName,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesScreen(),
        ),
        GoRoute(
          path: '/messages/:id',
          builder: (context, state) {
            final userId = state.pathParameters['id'] ?? '';
            final userName = state.extra as String? ?? 'Artist';
            return ChatScreen(userId: userId, userName: userName);
          },
        ),
        GoRoute(
          path: '/premium',
          builder: (context, state) => const PremiumScreen(),
        ),
        GoRoute(
          path: '/gig/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
            return GigDetailScreen(gigId: id);
          },
        ),
        GoRoute(
          path: '/portfolio/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            return PortfolioScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/ratings/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            return RatingsScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/upload-media',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final userId = extra['userId'] as String? ?? '';
            final onUploadComplete = extra['onUploadComplete'] as VoidCallback? ?? () {};
            return UploadMediaScreen(userId: userId, onUploadComplete: onUploadComplete);
          },
        ),
        GoRoute(
          path: '/rankings',
          builder: (context, state) => const RankingsScreen(),
        ),
        GoRoute(
          path: '/blocked-users',
          builder: (context, state) => const BlockedUsersScreen(),
        ),
        GoRoute(
          path: '/connection-requests',
          builder: (context, state) => const ConnectionRequestsScreen(),
        ),
        GoRoute(
          path: '/profile/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            return UnifiedProfileScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/event-history',
          builder: (context, state) => const EventHistoryScreen(),
        ),
        GoRoute(
          path: '/event-calendar',
          builder: (context, state) => const EventCalendarScreen(),
        ),
        GoRoute(
          path: '/event-invitations',
          builder: (context, state) => const EventInvitationsScreen(),
        ),
        GoRoute(
          path: '/settings/change-password',
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: '/settings/account-settings',
          builder: (context, state) => const AccountSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/help',
          builder: (context, state) => const HelpCenterScreen(),
        ),
        GoRoute(
          path: '/settings/terms',
          builder: (context, state) => const TermsScreen(),
        ),
        GoRoute(
          path: '/settings/privacy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        GoRoute(
          path: '/settings/notifications',
          builder: (context, state) => const NotificationsSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/privacy-settings',
          builder: (context, state) => const PrivacySettingsScreen(),
        ),
        GoRoute(
          path: '/settings/delete-account',
          builder: (context, state) => const DeleteAccountScreen(),
        ),
        GoRoute(
          path: '/settings/cache',
          builder: (context, state) => const CacheSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/font-size',
          builder: (context, state) => const FontSizeScreen(),
        ),
        GoRoute(
          path: '/settings/accessibility',
          builder: (context, state) => const AccessibilityScreen(),
        ),
        GoRoute(
          path: '/settings/data-usage',
          builder: (context, state) => const DataUsageScreen(),
        ),
        GoRoute(
          path: '/settings/sounds',
          builder: (context, state) => const SoundSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/change-email',
          builder: (context, state) => const ChangeEmailScreen(),
        ),
        GoRoute(
          path: '/settings/language',
          builder: (context, state) => const LanguageScreen(),
        ),
        GoRoute(
          path: '/settings/account-settings',
          builder: (context, state) => const AccountSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/suspend-account',
          builder: (context, state) => const SuspendAccountScreen(),
        ),
      ],
    );

    final themeProvider = Provider.of<ThemeProvider>(context);

    return ConnectivityWrapper(
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.bgLight,
        cardColor: AppConstants.cardLight,
        dividerColor: AppConstants.borderLight,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
          bodyColor: AppConstants.textLightPrimary,
          displayColor: AppConstants.textLightPrimary,
        ),
        colorScheme: const ColorScheme.light(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.accentColor,
          surface: AppConstants.cardLight,
          background: AppConstants.bgLight,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: AppConstants.textLightPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.bgLight,
          elevation: 0,
          scrolledUnderElevation: 0, // Evita cambio de color al scroll
          iconTheme: const IconThemeData(color: AppConstants.textLightPrimary),
          titleTextStyle: GoogleFonts.outfit(
            color: AppConstants.textLightPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppConstants.cardLight,
          elevation: 4, // Elevación para profundidad real
          shadowColor: const Color(0xFF0F172A).withOpacity(0.08), // Sombra azulada premium
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white, width: 1), // Borde interior limpio
          ),
        ),
        iconTheme: const IconThemeData(color: AppConstants.textLightPrimary, size: 24),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppConstants.bgLightSecondary,
          labelStyle: GoogleFonts.outfit(color: AppConstants.textLightPrimary, fontSize: 13),
          secondaryLabelStyle: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: AppConstants.borderLight),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: AppConstants.textLightSecondary.withOpacity(0.4)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppConstants.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppConstants.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppConstants.primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        cardColor: AppConstants.cardColor,
        dividerColor: AppConstants.borderColor,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: AppConstants.textPrimary,
          displayColor: AppConstants.textPrimary,
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.accentColor,
          surface: AppConstants.cardColor,
          background: AppConstants.backgroundColor,
          onPrimary: Colors.black,
          onSurface: AppConstants.textPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: AppConstants.textPrimary),
          titleTextStyle: GoogleFonts.outfit(
            color: AppConstants.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppConstants.cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppConstants.borderColor, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConstants.bgDarkSecondary,
          hintStyle: TextStyle(color: AppConstants.textSecondary.withOpacity(0.3)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppConstants.primaryColor, width: 1),
          ),
        ),
      ),
      routerConfig: router,
      ),
    );
  }
}
