import 'package:go_router/go_router.dart';
import '../../features/splash/views/splash_view.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/register_view.dart';
import '../../features/kyc/views/kyc_view.dart';
import '../../features/kyc/views/kyc_pending_view.dart';
import '../../features/home/views/driver_home_view.dart';
import '../../core/layouts/main_layout.dart';
import '../../features/earnings/views/earnings_view.dart';
import '../../features/history/views/ride_history_view.dart';
import '../../features/profile/views/profile_view.dart';

class AppRoutes {
  AppRoutes._();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash
      GoRoute(path: '/splash', builder: (_, _) => const SplashView()),

      // Auth
      GoRoute(path: '/login', builder: (_, _) => const LoginView()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterView()),

      // KYC
      GoRoute(path: '/kyc', builder: (_, _) => const KycView()),
      GoRoute(path: '/kyc/pending', builder: (_, _) => const KycPendingView()),

      // Home & Main Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainLayout(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const DriverHomeView()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/earnings', builder: (_, _) => const EarningsView()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/history', builder: (_, _) => const RideHistoryView()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (_, _) => const ProfileView()),
            ],
          ),
        ],
      ),
    ],
  );
}
