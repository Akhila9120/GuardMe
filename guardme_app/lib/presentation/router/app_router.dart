import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardme_app/presentation/providers/auth_provider.dart';
import 'package:guardme_app/presentation/pages/splash_page.dart';
import 'package:guardme_app/presentation/pages/login_page.dart';
import 'package:guardme_app/presentation/pages/signup_page.dart';
import 'package:guardme_app/presentation/pages/home_page.dart';
import 'package:guardme_app/presentation/pages/map_page.dart';
import 'package:guardme_app/presentation/pages/contact_list_page.dart';
import 'package:guardme_app/presentation/pages/notification_page.dart';
import 'package:guardme_app/presentation/pages/trip_details_page.dart';
import 'package:guardme_app/presentation/pages/profile_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/splash';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactListPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationPage(),
      ),
      GoRoute(
        path: '/trips',
        builder: (context, state) => const TripDetailsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );

  ref.listen<AuthState>(authProvider, (_, next) {
    router.refresh();
  });

  return router;
});
