import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/auth/provider/session_activity_detector.dart';
import 'package:nursejoyapp/auth/provider/session_timeout_service.dart';
import 'package:nursejoyapp/features/chat/ui/pages/chat_list_page.dart';
import 'package:nursejoyapp/features/chat/ui/pages/chat_room_page.dart';
import 'package:nursejoyapp/features/dashboard/ui/pages/activity_list.dart';
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
import 'package:nursejoyapp/features/admin/ui/pages/doctor_application_details_page.dart';
import 'package:nursejoyapp/features/admin/ui/pages/doctor_applications_page.dart';

import 'features/payments/ui/pages/payments_page.dart';

class AppRouter {
  final AuthService authService;
  final SessionTimeoutService? sessionTimeoutService;

  AppRouter(this.authService, {this.sessionTimeoutService});

  // get the user doc

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authService),
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) async {
      final isLoggedIn = authService.user != null;

      // Update current route in session timeout service
      if (sessionTimeoutService != null) {
        sessionTimeoutService!.setCurrentRoute(state.uri.toString());
      }

      // 1. If the user isn’t logged-in go to /entry (unless they’re already on an auth page)
      final isOnAuthPage = [
        '/signin',
        '/register/user',
        '/register/doctor',
        '/securitycheck',
      ].contains(state.uri.toString());
      if (!isLoggedIn && !isOnAuthPage) return '/entry';

      if (isLoggedIn) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(authService.user!.uid).get();
        final userData = userDoc.data();
        final userRole = userData?['role'];

        if (state.uri.toString().startsWith('/admin') && userRole != 'admin') {
          return '/home'; // Or any other non-admin page
        }

        final setup = await authService.isUserSetup();

        if (setup['is_doctor'] == true) {
          if (setup['doc_info_is_setup'] == false) {
            return '/profile-setup/doctor';
          }
          if (setup['is_verified'] == false) return '/wait-verification';
        }

        if (setup['is_setup'] == false) {
          return '/profile-setup';
        }
      }

      // No redirect needed
      return null;
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
      // Secure routes - require session validation (TC38 implementation)
      GoRoute(
        path: '/chat',
        builder: (context, state) => SessionGuard(
          child: const ChatListPage(),
        ),
      ),
      GoRoute(
        path: '/chat/:chatRoomID',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null) {
            return SessionGuard(
              child: ChatRoomPage(
                  chatRoomID: state.pathParameters['chatRoomID']!,
                  recipientID: extra['recipientID'] as String,
                  recipientFullName: extra['recipientFullName'] as String,
              ),
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
              patientData: extra['patientData'] as Map<String, dynamic>,
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
              doctorData: extra['doctorData'] as Map<String, dynamic>,
            );
          }
          throw Exception('No extra data found');
        },
      ),
      GoRoute(
        path: '/activity-list',
        builder: (context, state) => const ActivityListPage(),
      ),
      GoRoute(
        path: '/doctor-list',
        builder: (context, state) =>
            DoctorList(initialData: state.extra as Map<String, dynamic>),
      ),
      GoRoute(
        path: '/doctor/:doctorId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null) {
            return DoctorPage(
              doctorId: state.pathParameters['doctorId']!,
              doctorDetails: extra['doctorDetails'] as DocumentSnapshot,
            );
          }
          throw Exception('No extra data found');
        },
      ),

      // Profile route - requires re-authentication for sensitive data access
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId =
              state.pathParameters['userId'] ?? authService.user!.uid;
          return SessionGuard(
            requireReauth:
                true, // Require recent authentication for profile access
            child: ProfilePage(userID: userId),
          );
        },
      ),

      GoRoute(
        path: '/admin/applications',
        builder: (context, state) => const DoctorApplicationsPage(),
      ),
      GoRoute(
        path: '/admin/applications/:doctorId',
        builder: (context, state) => DoctorApplicationDetailsPage(
          doctorId: state.pathParameters['doctorId']!,
        ),
      ),

      // Payments route - highly sensitive, requires re-authentication
      GoRoute(
        path: '/payments',
        builder: (context, state) => SessionGuard(
          requireReauth: true,
          child: const PaymentsPage(),
        ),
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
