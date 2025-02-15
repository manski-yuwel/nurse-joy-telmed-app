import 'package:flutter/material.dart';
import 'features/signing/ui/pages/loading_page.dart';
import 'features/signing/ui/pages/securitycheck_page.dart';
import 'features/signing/ui/pages/signin_page.dart';
import 'features/signing/ui/pages/register_page.dart';
import 'features/chat/ui/pages/chat_list_page.dart';
import 'features/dashboard/ui/pages/dashboard_page.dart';
import 'features/profile/ui/pages/profile_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/loading',
      routes: {
        '/loading': (context) => LoadingPage(),
        '/signin': (context) => SigninPage(),
        '/register': (context) => RegisterPage(),
        '/securitycheck': (context) => SecuritycheckPage(),
        '/homescreen': (context) => HomeScreen(),
      },
      theme: ThemeData(
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 1)]
          ),
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

  final List<Widget> _pages = [
    ChatListPage(),
    DashboardPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF58f0d7),
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
          'Nurse Joy',
          style: Theme.of(context).textTheme.titleLarge
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
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
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

