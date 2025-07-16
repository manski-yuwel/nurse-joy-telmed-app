import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/auth/provider/session_timeout_service.dart';
import 'package:nursejoyapp/auth/provider/session_activity_detector.dart';
import 'features/chat/ui/pages/chat_list_page.dart';
import 'features/dashboard/ui/pages/dashboard_page.dart';
import 'features/profile/ui/pages/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

Future<void> backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message received: ${message.notification}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize firebase and load env variables
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // initialie supabase connection for storage
  await supabase.Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANONKEY']!,
  );

  // set up background message handler
  FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);

  runApp(
    const StartUpApp(),
  );
}

class StartUpApp extends StatelessWidget {
  const StartUpApp({super.key});

  Future<Map<String, dynamic>> _initialize() async {
    final authService = AuthService();
    return {
      'authService': authService,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(home: SplashScreen());
        } else if (snapshot.hasError) {
          return MaterialApp(
              home: ErrorScreen(error: snapshot.error.toString()));
        } else {
          final authService = snapshot.data!['authService'] as AuthService;

          // Create session timeout service
          final sessionTimeoutService = SessionTimeoutService(authService);

          return MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthService>.value(value: authService),
              ChangeNotifierProvider<SessionTimeoutService>.value(
                  value: sessionTimeoutService),
            ],
            child: MyApp(
              authService: authService,
              sessionTimeoutService: sessionTimeoutService,
            ),
          );
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Text('Error: $error')),
      );
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final SessionTimeoutService sessionTimeoutService;

  const MyApp({
    super.key,
    required this.authService,
    required this.sessionTimeoutService,
  });

  @override
  Widget build(BuildContext context) {
    // Create router configuration with session timeout service
    final appRouter =
        AppRouter(authService, sessionTimeoutService: sessionTimeoutService);

    return SessionActivityDetector(
      child: MaterialApp.router(
        title: 'NurseJoy',
        routerConfig: appRouter.router,
        theme: ThemeData(
          textTheme: const TextTheme(
            titleLarge: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                      color: Colors.black45,
                      offset: Offset(1, 1),
                      blurRadius: 1)
                ]),
          ),
        ),
        builder: (context, child) {
          // Initialize session timeout service with context
          WidgetsBinding.instance.addPostFrameCallback((_) {
            sessionTimeoutService.initialize(context);
          });
          return child ?? Container();
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;
  User? user;
  late AuthService auth;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    auth = Provider.of<AuthService>(context);
    user = auth.user;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      context.go('/chat');
    } else if (index == 2) {
      context.go('/profile/${auth.user!.uid}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      body: const DashboardPage(),
    );
  }
}

// Function to create image widget with the cropped image
Widget buildCircleImage(String imagePath, double size, double scale) {
  return Padding(
    padding: EdgeInsets.all(size),
    child: ClipOval(
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

Widget buildPage(int index, User? user) {
  switch (index) {
    case 0:
      return const ChatListPage();
    case 1:
      return const DashboardPage();
    case 2:
      return ProfilePage(userID: user!.uid);
    default:
      return const SizedBox.shrink();
  }
}
