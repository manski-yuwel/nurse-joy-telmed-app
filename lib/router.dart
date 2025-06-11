import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/features/chat/ui/pages/chat_list_page.dart';
import 'package:nursejoyapp/features/map/ui/pages/viewmap.dart';
import 'package:nursejoyapp/features/profile/ui/pages/profile_page.dart';
import 'package:nursejoyapp/features/profile/ui/pages/profile_setup.dart';
import 'package:nursejoyapp/features/profile/ui/pages/doctor_profile_setup.dart';
import 'package:nursejoyapp/features/Settings/ui/pages/settings.dart';
import 'package:nursejoyapp/features/signing/ui/pages/register_doctor_page.dart';
import 'package:nursejoyapp/features/signing/ui/pages/register_page.dart';
import 'package:nursejoyapp/features/signing/ui/pages/securitycheck_page.dart';
import 'package:nursejoyapp/features/signing/ui/pages/signin_page.dart';
import 'package:nursejoyapp/features/entry/ui/app_entry.dart';
import 'package:nursejoyapp/features/ai/joy_ai_chat.dart';
import 'package:nursejoyapp/main.dart';
import 'package:flutter/foundation.dart';

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  // get the user doc

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authService),
    debugLogDiagnostics: kDebugMode,
    initialLocation: '/entry',
    redirect: (context, state) async {
      final isLoggedIn = authService.user != null;
      final isLoggingIn = state.uri.path == '/signin' ||
          state.uri.path == '/register/user' ||
          state.uri.path == '/register/doctor';

      // If not logged in and not on a login page, redirect to signin
      if (!isLoggedIn && !isLoggingIn) {
        return '/entry';
      }

      // If logged in and on a login page, redirect to home
      if (isLoggedIn && isLoggingIn) {
        // Check if user setup is completed
        final isSetup = await authService.isUserSetup();
        if (isSetup['is_setup'] == false && isSetup['is_doctor'] == false) {
          return '/profile-setup';
        } else if (isSetup['is_setup'] == false &&
            isSetup['is_doctor'] == true) {
          return '/profile-setup/doctor';
        }
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: '/entry',
        builder: (context, state) => const AppEntry(),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SigninPage(),
      ),
      GoRoute(
        path: '/register/user',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/register/doctor',
        builder: (context, state) => const RegisterDoctorPage(),
      ),
      GoRoute(
        path: '/securitycheck',
        builder: (context, state) => const SecuritycheckPage(),
      ),

      // Main application routes
      GoRoute(
        path: '/ai',
        builder: (context, state) => const JoyAIChat(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetup(),
      ),
      GoRoute(
        path: '/profile-setup/doctor',
        builder: (context, state) => const DoctorProfileSetup(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const Settings(),
      ),
      GoRoute(
        path: '/viewmap',
        builder: (context, state) => const ViewMapPage(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListPage(),
      ),

      // Individual feature routes
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId =
              state.pathParameters['userId'] ?? authService.user!.uid;
          return ProfilePage(userID: userId);
        },
      ),

      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetup(),
      ),
    ],
  );
}

// Helper class to convert authService to a listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(AuthService authService) {
    authService.addListener(notifyListeners);
  }
}
