import 'package:flutter/material.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const StartUpApp(),
  );
}

class StartUpApp extends StatelessWidget {
  const StartUpApp({super.key});

  Future<Map<String, dynamic>> _initialize() async {
    await dotenv.load(fileName: '.env');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
          return MultiProvider(providers: [
            ChangeNotifierProvider<AuthService>.value(value: authService),
          ], child: MyApp(authService: authService));
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

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    // Create router configuration
    final appRouter = AppRouter(authService);

    return MaterialApp.router(
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
                    color: Colors.black45, offset: Offset(1, 1), blurRadius: 1)
              ]),
        ),
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
