import 'package:flutter/material.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/features/signing/ui/pages/loading_page.dart';
import 'features/signing/ui/pages/securitycheck_page.dart';
import 'features/signing/ui/pages/signin_page.dart';
import 'features/signing/ui/pages/register_page.dart';
import 'features/chat/ui/pages/chat_list_page.dart';
import 'features/dashboard/ui/pages/dashboard_page.dart';
import 'features/profile/ui/pages/profile_page.dart';
import 'features/emergency/ui/pages/emergency_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/router.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'features/Settings/ui/pages/settings.dart';
import 'features/map/ui/pages/viewmap.dart';

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
        if (snapshot.connectionState == ConnectionState.done) {
          return const MaterialApp(home: SplashScreen());
        } else if (snapshot.hasError) {
          return MaterialApp(home: ErrorScreen(error: snapshot.error.toString()));
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
  String _appBarTitle = 'Nurse Joy';

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _updateTitle('Nurse Joy');
      } else if (index == 1) {
        _updateTitle('Dashboard');
      } else if (index == 2) {
        _updateTitle('Profile');
      }
    });
  }

  void _updateTitle(String title) {
    setState(() {
      _appBarTitle = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final List<Widget> _pages = [
      ChatListPage(),
      DashboardPage(),
      ProfilePage(userID: auth.user!.uid),
    ];
    final mediaQuery = MediaQuery.of(context);
    final appBarHeight = kToolbarHeight + mediaQuery.padding.top;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF58f0d7),
        actions: [
          if (_selectedIndex == 0)
            buildCircleImage('assets/img/nursejoy.jpg', 5, 1.5),
          if (_selectedIndex == 1)
            TextButton.icon(
              onPressed: () {
                context.go('/emergency');
              },
              label: const Text(
                'E.M.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.warning_sharp, color: Colors.red),
            ),
        ],
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          _appBarTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(1, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: appBarHeight,
              width: double.infinity,
              color: const Color(0xFF58f0d7),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Home'),
                    onTap: () {
                      context.go('/home');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.emergency_outlined),
                    title: const Text('Activate Emergency Mode'),
                    onTap: () {
                      context.go('/emergency');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    onTap: () {
                      context.go('/settings');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('View Map'),
                    onTap: () {
                      context.go('/viewmap');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout_outlined),
                    title: const Text('Logout'),
                    onTap: () async {
                      await auth.signOut();
                      context.go('/signin');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.messenger),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF58f0d7),
      ),
    );
  }
}

// Function to create image widget with the cropped image
Widget buildCircleImage(String imagePath, double size, double scale) {
  return Padding(
    padding: EdgeInsets.all(size),
    child: ClipOval(
      child: Transform.scale(
        scale: scale, // Adjust the scale to zoom in
        alignment: Alignment.topCenter,
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover, // Ensure the image covers the entire area
        ),
      ),
    ),
  );
}
