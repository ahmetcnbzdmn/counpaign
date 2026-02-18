import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/scaffold_with_navbar.dart';
import 'core/widgets/animated_branch_container.dart';

import 'features/customer/home_screen.dart';
import 'features/customer/campaigns_screen.dart';
import 'features/customer/explore_cafes_screen.dart';
import 'features/customer/settings_screen.dart';
import 'features/customer/edit_profile_screen.dart';
import 'features/customer/scanner_screen.dart';
import 'features/customer/add_firm_screen.dart';
import 'features/customer/business_detail_screen.dart';
import 'features/customer/business_scanner_screen.dart';
import 'features/customer/my_firms_screen.dart';
import 'features/customer/order_history_screen.dart';
import 'features/customer/my_reviews_screen.dart';

import 'features/customer/menu_screen.dart';

import 'features/auth/forgot_password_screen.dart';
import 'features/auth/verification_screen.dart';
import 'features/customer/campaign_detail_screen.dart';
import 'features/customer/notifications_screen.dart';
import 'core/models/campaign_model.dart';

import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/providers/auth_provider.dart' as app;
import 'features/auth/login_screen.dart';
import 'features/auth/introduction_screen.dart';
import 'features/splash/splash_screen.dart';

import 'core/providers/business_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/campaign_provider.dart';

import 'core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background handler must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Notifications
  await NotificationService.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final storageService = StorageService();
  final apiService = ApiService(storageService);
  final authService = AuthService(apiService, storageService);
  final authProvider = app.AuthProvider(authService, storageService);
  final businessProvider = BusinessProvider(apiService);

  // Link ApiService 401 handling to AuthProvider logout
  apiService.onUnauthorized = () {
    authProvider.logout();
  };

  // Don't await here! It blocks runApp if network is slow/down.
  authProvider.loadUserSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<app.AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider.value(value: businessProvider),
        ChangeNotifierProvider(create: (_) => CampaignProvider(apiService)),

        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
        ChangeNotifierProvider(create: (_) => LanguageProvider(storageService)),
      ],
      child: const CounpaignApp(),
    ),
  );
}


class CounpaignApp extends StatefulWidget {
  const CounpaignApp({super.key});

  @override
  State<CounpaignApp> createState() => _CounpaignAppState();
}

class _CounpaignAppState extends State<CounpaignApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<app.AuthProvider>();
    
    _router = GoRouter(
      initialLocation: '/', // Start at Splash
      refreshListenable: authProvider,
      observers: [
        _KeyboardDismissObserver(),
      ], 
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/intro',
          builder: (context, state) => const IntroductionScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>?;
            return LoginScreen(initialPageIndex: extras?['pageIndex'] ?? 0);
          },
        ),
        StatefulShellRoute(
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/campaigns',
                  builder: (context, state) => const CampaignsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/qr',
                  builder: (context, state) => const SizedBox(), // Placeholder, tapped intercepted
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/explore-cafes',
                  builder: (context, state) => const ExploreCafesScreen(),
                ),
              ],
            ),

          ],
          navigatorContainerBuilder: (context, navigationShell, children) {
            return ScaffoldWithNavBar(
              navigationShell: navigationShell,
              // We could pass children here if we modified ScaffoldWithNavBar,
              // but ScaffoldWithNavBar currently extends just the Shell.
              // Actually, we need to pass the Animated Container into ScaffoldWithNavBar,
              // or let ScaffoldWithNavBar build it.
              
              // Let's modify ScaffoldWithNavBar to accept 'body' instead of using navigationShell as body?
              // No, let's keep ScaffoldWithNavBar API, but we need to inject our Animated Container.
              
              // navigationShell itself is NOT the widget here.
              // The 'children' argument contains the Navigators for each branch.
              
              body: AnimatedBranchContainer(
                currentIndex: navigationShell.currentIndex,
                children: children,
                onTabSelect: (index) => navigationShell.goBranch(index),
              ),
            );
          },
          builder: (context, state, navigationShell) {
             // With navigatorContainerBuilder, this builder's navigationShell argument 
             // effectively represents the widget returned by navigatorContainerBuilder.
             // So we just return it.
             return navigationShell;
          },
        ),

        // Business Routes (Outside the bottom nav shell)
        GoRoute(
          path: '/customer-scanner',
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>?;
            return CustomerScannerScreen(extra: extras);
          },
        ),
        GoRoute(
          path: '/business-campaigns',
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>?;
            return CampaignsScreen(
              firmId: extras?['firmId'],
              firmName: extras?['firmName'],
            );
          },
        ),
        GoRoute(
          path: '/add-firm',
          builder: (context, state) => const AddFirmScreen(),
        ),
        GoRoute(
          path: '/business-detail',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            return BusinessDetailScreen(businessData: data);
          },
        ),
        GoRoute(
          path: '/business-scanner',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            return BusinessScannerScreen(businessData: data);
          },
        ),
        GoRoute(
          path: '/menu',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            return MenuScreen(
              businessId: data['businessId'],
              businessName: data['businessName'],
              businessColor: data['businessColor'],
              businessImage: data['businessImage'],
            );
          },
        ),
        GoRoute(
          path: '/campaign-detail',
          builder: (context, state) {
            final campaign = state.extra as CampaignModel;
            return CampaignDetailScreen(campaign: campaign);
          },
        ),

        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/my-firms',
          builder: (context, state) => const MyFirmsScreen(),
        ),
        GoRoute(
          path: '/order-history',
          builder: (context, state) => const OrderHistoryScreen(),
        ),
        GoRoute(
          path: '/my-reviews',
          builder: (context, state) => const MyReviewsScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/verify-phone',
          builder: (context, state) {
            final phone = state.extra as String? ?? '';
            return VerificationScreen(phoneNumber: phone);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
      redirect: (context, state) {
        // SPLASH GUARD
        if (state.uri.toString() == '/') return null; // Allow splash

        // AUTH GUARD
        if (!authProvider.isInitialized) return null; // Wait for initialization (Stay on Splash)

        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.uri.toString() == '/login';
        final isIntro = state.uri.toString() == '/intro';

        final isForgotPassword = state.uri.toString() == '/forgot-password';

        final isVerifyPhone = state.uri.toString() == '/verify-phone';

        if (!isLoggedIn && !isLoggingIn && !isIntro && !isForgotPassword && !isVerifyPhone) return '/intro';

        if (isLoggedIn && (isLoggingIn || isIntro)) {
          return '/home'; // All users go to Customer Home
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'Counpaign',
      debugShowCheckedModeBanner: false,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // Global keyboard dismissal
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child,
        );
      },
    );
  }
}

class _KeyboardDismissObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    FocusManager.instance.primaryFocus?.unfocus();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    FocusManager.instance.primaryFocus?.unfocus();
    super.didPop(route, previousRoute);
  }
}
