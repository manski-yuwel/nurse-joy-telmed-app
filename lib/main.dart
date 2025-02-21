import 'package:flutter/material.dart';
import 'features/signing/ui/pages/loading_page.dart';
import 'features/signing/ui/pages/securitycheck_page.dart';
import 'features/signing/ui/pages/signin_page.dart';
import 'features/signing/ui/pages/register_page.dart';
import 'features/chat/ui/pages/chat_list_page.dart';
import 'features/dashboard/ui/pages/dashboard_page.dart';
import 'features/profile/ui/pages/profile_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];

    return MaterialApp(
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/signin' : '/home',
      routes: {
        FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/home'
        '/loading': (context) => LoadingPage(),
        '/sign-in': (context) {
          return SignInScreen(
            providers: providers,
            actions: [
              AuthStateChangeAction<UserCreated>((context, state) {
                Navigator.pushReplacementNamed(context, '/home');
              }),
              AuthStateChangeAction<SignedIn>((context, state) {
                Navigator.pushReplacementNamed(context, '/home');
              }),
            ],
          );
        },
        '/register': (context) => RegisterPage(),
        '/securitycheck': (context) => SecuritycheckPage(),
        '/home': (context) {
          return HomeScreen();
        },
      },
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
      // home: SigninScreen(),
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
    user = FirebaseAuth.instance.currentUser;
  }

  final List<Widget> _pages = [
    ChatListPage(),
    DashboardPage(),
    ProfilePage(),
  ];

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
    double appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF58f0d7),
        actions: [
          if (_selectedIndex == 0)
            buildCircleImage('assets/img/nursejoy.jpg', 5, 1.5),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
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
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.emergency_outlined),
                    title: const Text('Activate Emergency Mode'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('View Map'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout_outlined),
                    title: const Text('Logout'),
                    onTap: () {
                      Navigator.pop(context);
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
