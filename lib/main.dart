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
          builder: (context, state) => const Scaffold(
            backgroundColor: AppConstants.backgroundColor,
            body: Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
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
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE0E0E0),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
          bodyColor: const Color(0xFF1A1A1A),
          displayColor: const Color(0xFF1A1A1A),
        ),
        colorScheme: const ColorScheme.light(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.accentColor,
          surface: Colors.white,
          background: Color(0xFFF8F9FA),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Color(0xFF1A1A1A),
          onBackground: Color(0xFF1A1A1A),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
          titleTextStyle: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: const Color(0xFF1A1A1A).withOpacity(0.4)),
          labelStyle: const TextStyle(color: Color(0xFF666666)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.accentColor,
          surface: AppConstants.cardColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConstants.cardColor,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      routerConfig: router,
      ),
    );
  }
}
