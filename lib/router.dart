import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/features/chat/ui/pages/chat_list_page.dart';
import 'package:nursejoyapp/features/chat/ui/pages/chat_room_page.dart';
import 'package:nursejoyapp/features/doctor/ui/appointment_detail.dart';
import 'package:nursejoyapp/features/doctor/ui/appointment_list.dart';
import 'package:nursejoyapp/features/doctor/ui/doctor_list.dart';
import 'package:nursejoyapp/features/doctor/ui/doctor_page.dart';
import 'package:nursejoyapp/features/doctor/ui/user_appointment_detail.dart';
import 'package:nursejoyapp/features/doctor/ui/user_appointment_list.dart';
import 'package:nursejoyapp/features/map/ui/pages/viewmap.dart';
import 'package:nursejoyapp/features/profile/ui/pages/profile_page.dart';
import 'package:nursejoyapp/features/profile/ui/pages/profile_setup.dart';
import 'package:nursejoyapp/features/profile/ui/pages/doctor_profile_setup.dart';
import 'package:nursejoyapp/features/Settings/ui/pages/settings.dart';
import 'package:nursejoyapp/features/signing/ui/pages/register_doctor_page.dart';
import 'package:nursejoyapp/features/signing/ui/pages/register_page.dart';
import 'package:nursejoyapp/features/signing/ui/pages/securitycheck_page.dart';
import 'package:nursejoyapp/features/signing/ui/pages/signin_page.dart';
import 'package:nursejoyapp/features/signing/ui/pages/wait_verification.dart';
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
    redirect: (context, state) async {
      final isLoggedIn = authService.user != null;

      // 1. If the user isn’t logged-in go to /entry (unless they’re already on an auth page)
      final isOnAuthPage = [
        '/signin',
        '/register/user',
        '/register/doctor',
        '/securitycheck',
      ].contains(state.uri.toString());
      if (!isLoggedIn && !isOnAuthPage) return '/entry';

      if (isLoggedIn) {
        final setup = await authService.isUserSetup();

        if (setup['is_doctor'] == true) {
          if (setup['doc_info_is_setup'] == false)
            return '/profile-setup/doctor';
          if (setup['is_verified'] == false) return '/wait-verification';
        }

        if (setup['is_setup'] == false) {
          return '/profile-setup';
        }
      }
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: '/wait-verification',
        builder: (context, state) => const WaitVerificationPage(),
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
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/viewmap',
        builder: (context, state) => const ViewMapPage(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListPage(),
      ),
      GoRoute(
        path: '/chat/:chatRoomID',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null) {
            return ChatRoomPage(
              chatRoomID: state.pathParameters['chatRoomID']!,
              recipientID: extra['recipientID'] as String,
              recipientFullName: extra['recipientFullName'] as String,
            );
          }
          throw Exception('No extra data found');
        },
      ),
      GoRoute(
        path: '/appointment-list',
        builder: (context, state) => const AppointmentList(),
      ),

      GoRoute(
        path: '/appointment-detail/:appointmentId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null) {
            return AppointmentDetail(
              appointmentId: state.pathParameters['appointmentId']!,
              patientData: extra['patientData'] as DocumentSnapshot,
            );
          }
          throw Exception('No extra data found');
        },
      ),

      GoRoute(
        path: '/user-appointment-list',
        builder: (context, state) => const UserAppointmentList(),
      ),

      GoRoute(
        path: '/user-appointment-detail/:appointmentId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null) {
            return UserAppointmentDetail(
              appointmentId: state.pathParameters['appointmentId']!,
              doctorData: extra['doctorData'] as DocumentSnapshot,
            );
          }
          throw Exception('No extra data found');
        },
      ),  
      GoRoute(
        path: '/doctor-list',
        builder: (context, state) => const DoctorList(),
      ),
      GoRoute(
        path: '/doctor/:doctorId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null) {
            return DoctorPage(
              doctorId: state.pathParameters['doctorId']!,
              doctorDetails: extra['doctorDetails'] as DocumentSnapshot,
              userDetails: extra['userDetails'] as DocumentSnapshot,
            );
          }
          throw Exception('No extra data found');
        },
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
    ],
  );
}

// Helper class to convert authService to a listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(AuthService authService) {
    authService.addListener(notifyListeners);
  }
}
