import 'package:flutter/material.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:nursejoyapp/migrations/profile/profile_migrate.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  int _selectedIndex =
      2; // Initialize to a value that doesn't match any bottom nav item.
  String _appBarTitle = "Settings";
  bool _isMigrating = false;
  String _migrationStatus = "";

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        Navigator.pushReplacementNamed(context, "/homescreen");
      } else if (index == 1) {
        Navigator.pushReplacementNamed(context, "/homescreen");
      } else if (index == 2) {
        Navigator.pushReplacementNamed(context, "/homescreen");
      }
    });
  }

  Future<void> _runChatMigration() async {
    setState(() {
      _isMigrating = true;
      _migrationStatus = "Running chat messages migration...";
    });

    try {
      final chatInstance = Chat();
      await chatInstance.migrateMessages();
      setState(() {
        _migrationStatus = "Chat migration completed successfully!";
      });
    } catch (e) {
      setState(() {
        _migrationStatus = "Chat migration failed: $e";
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _runProfileMigration() async {
    setState(() {
      _isMigrating = true;
      _migrationStatus = "Running profile migration...";
    });

    try {
      final profileMigrate = ProfileMigrate();
      await profileMigrate.migrateProfileData();
      setState(() {
        _migrationStatus = "Profile migration completed successfully!";
      });
    } catch (e) {
      setState(() {
        _migrationStatus = "Profile migration failed: $e";
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context); // Access AuthService
    double appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF58f0d7),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
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
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.emergency_outlined),
                    title: const Text('Activate Emergency Mode'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/emergency');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
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
                      auth.signOut(); //Use the AuthService instance
                      Navigator.pushReplacementNamed(context, '/signin');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          // Notifications
          ListTile(
            title: const Text('Notifications'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),

          // Language
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                }
              },
              items: _languages.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),

          // Clear Cache
          ListTile(title: const Text('Clear Cache')),

          // Divider for migration section
          const Divider(thickness: 2, height: 40),

          // Migration section title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Database Migration Tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),

          // Chat Migration Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: _isMigrating ? null : _runChatMigration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Migrate Chat Messages'),
            ),
          ),

          // Profile Migration Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: _isMigrating ? null : _runProfileMigration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Migrate Profile Data'),
            ),
          ),

          // Migration Status
          if (_migrationStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _migrationStatus.contains('failed')
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _migrationStatus.contains('failed')
                            ? Colors.red.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _migrationStatus,
                      style: TextStyle(
                        color: _migrationStatus.contains('failed')
                            ? Colors.red.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator during migration
          if (_isMigrating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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
