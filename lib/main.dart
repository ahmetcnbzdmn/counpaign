import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'features/business/manager_dashboard.dart';
import 'features/business/standard_dashboard.dart';
import 'features/business/qr_scanner_screen.dart';
import 'features/customer/scanner_screen.dart';
import 'features/customer/add_firm_screen.dart';
import 'features/customer/business_detail_screen.dart';
import 'features/customer/business_scanner_screen.dart';
import 'features/customer/my_firms_screen.dart';
import 'features/customer/order_history_screen.dart';
import 'features/customer/my_reviews_screen.dart';
import 'features/customer/participations_screen.dart';
import 'features/customer/campaign_detail_screen.dart';
import 'features/customer/notifications_screen.dart';
import 'core/models/campaign_model.dart';

import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/splash/splash_screen.dart';

import 'core/providers/business_provider.dart';
import 'features/business/terminals_screen.dart';
import 'core/providers/terminal_provider.dart';
import 'core/providers/terminal_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/campaign_provider.dart';
import 'core/providers/participation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final storageService = StorageService();
  final apiService = ApiService(storageService);
  final authService = AuthService(apiService, storageService);
  final authProvider = AuthProvider(authService, storageService);
  final businessProvider = BusinessProvider(apiService);
  final terminalProvider = TerminalProvider(apiService);

  await authProvider.loadUserSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: businessProvider),
        ChangeNotifierProvider.value(value: terminalProvider),
        ChangeNotifierProvider(create: (_) => CampaignProvider(apiService)),
        ChangeNotifierProvider(create: (_) => ParticipationProvider(apiService)),
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
    final authProvider = context.read<AuthProvider>();
    
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
          path: '/login',
          builder: (context, state) => const LoginScreen(),
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
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'edit-profile',
                      builder: (context, state) => const EditProfileScreen(),
                    ),
                    GoRoute(
                      path: 'my-firms',
                      builder: (context, state) => const MyFirmsScreen(),
                    ),
                    GoRoute(
                      path: 'order-history',
                      builder: (context, state) => const OrderHistoryScreen(),
                    ),
                    GoRoute(
                      path: 'my-reviews',
                      builder: (context, state) => const MyReviewsScreen(),
                    ),
                    GoRoute(
                      path: 'notifications',
                      builder: (context, state) => const NotificationsScreen(), // New Route
                    ),
                  ],
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
          builder: (context, state) => const CustomerScannerScreen(),
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
          path: '/business/manager',
          builder: (context, state) => const ManagerDashboard(),
        ),
        GoRoute(
          path: '/business/standard',
          builder: (context, state) => const StandardDashboard(),
        ),
        GoRoute(
          path: '/business/scanner',
          builder: (context, state) => const QRScannerScreen(),
        ),
        GoRoute(
          path: '/business/terminals',
          builder: (context, state) => const TerminalsScreen(),
        ),
        GoRoute(
          path: '/business-campaigns',
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>;
            return CampaignsScreen(
              firmId: extras['firmId'],
              firmName: extras['firmName'],
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
          path: '/participations',
          builder: (context, state) => const ParticipationsScreen(),
        ),
      ],
      redirect: (context, state) {
        // SPLASH GUARD
        if (state.uri.toString() == '/') return null; // Allow splash

        // AUTH GUARD
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.uri.toString() == '/login';

        if (!isLoggedIn && !isLoggingIn) return '/login';

        if (isLoggedIn && isLoggingIn) {
          // Redirect based on role
          if (authProvider.currentUser?.role == 'business') return '/business/manager';
          if (authProvider.currentUser?.role == 'terminal') return '/business/scanner'; // Assuming terminal goes to scanner
          return '/home'; // Customer
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
