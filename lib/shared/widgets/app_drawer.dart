import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:nursejoyapp/features/ai/joy_ai_chat.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final mediaQuery = MediaQuery.of(context);
    final headerHeight =
        mediaQuery.size.height * 0.25; // Make header height responsive
    final isSmallScreen =
        mediaQuery.size.height < 600; // Check for small screens

    return SlideTransition(
      position: _slideAnimation,
      child: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header with constrained height
                Container(
                  height: headerHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF58f0d7),
                        Color(0xFF4dd0e1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF58f0d7),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isSmallScreen ? 8 : 16),


                      ],
                    ),
                  ),
                ),

                // Scrollable menu items
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: AnimationLimiter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Navigation Section
                            _buildSectionHeader('Navigation'),
                            ...AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 375),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(child: widget),
                              ),
                              children: [
                                _buildModernMenuItem(
                                  icon: Icons.home_rounded,
                                  title: 'Home',
                                  subtitle: 'Dashboard & Overview',
                                  onTap: () => context.go('/home'),
                                ),
                                _buildModernMenuItem(
                                  icon: Icons.person_rounded,
                                  title: 'Profile',
                                  subtitle: 'Personal Information',
                                  onTap: () =>
                                      context.go('/profile/${auth.user!.uid}'),
                                ),
                                _buildModernMenuItem(
                                  icon: Icons.chat_bubble_rounded,
                                  title: 'Chat',
                                  subtitle: 'Chat with NurseJoy',
                                  onTap: () => context.go('/ai'),
                                ),
                              
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Tools Section
                            _buildSectionHeader('Tools & Settings'),
                            ...AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 375),
                              delay: const Duration(milliseconds: 200),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(child: widget),
                              ),
                              children: [
                                _buildModernMenuItem(
                                  icon: Icons.map_rounded,
                                  title: 'View Map',
                                  subtitle: 'Location & Navigation',
                                  onTap: () => context.go('/viewmap'),
                                ),
                                _buildModernMenuItem(
                                  icon: Icons.person_add_alt_1_rounded,
                                  title: 'Profile Setup',
                                  subtitle: 'Complete Your Profile',
                                  onTap: () => context.go('/profile-setup'),
                                ),
                                _buildModernMenuItem(
                                  icon: Icons.settings_rounded,
                                  title: 'Settings',
                                  subtitle: 'App Preferences',
                                  onTap: () => context.go('/settings'),
                                ),
                                _buildModernMenuItem(
                                  icon: Icons.exit_to_app_rounded,
                                  title: 'Entry',
                                  subtitle: 'Entry to the App',
                                  onTap: () => context.go('/entry'),
                                ),
                                _buildModernMenuItem(
                                  icon: Icons.warning_amber_rounded,
                                  title: 'Wait Verification',
                                  subtitle: 'Wait for verification',
                                  onTap: () => context.go('/wait-verification'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Logout Section
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildModernMenuItem(
                                icon: Icons.logout_rounded,
                                title: 'Sign Out',
                                subtitle: 'Logout from Account',
                                onTap: () async {
                                  await auth.signOut();
                                  if (context.mounted) {
                                    context.go('/signin');
                                  }
                                },
                                isDestructive: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: Colors.red.shade400,
                        size: isSmallScreen ? 14 : 16,
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Text(
                        'Made with care for healthcare',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isEmergency = false,
    bool isDestructive = false,
  }) {
    Color primaryColor = isEmergency
        ? Colors.orange
        : isDestructive
            ? Colors.red
            : const Color(0xFF58f0d7);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? Colors.red : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
