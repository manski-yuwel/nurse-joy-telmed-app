import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/gestures.dart';
import 'package:nursejoyapp/features/signing/ui/widgets/tos_widget.dart';

class AppEntry extends StatefulWidget {
  const AppEntry({Key? key}) : super(key: key);

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  int _currentPage = 0;
  final int _numPages = 3;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      icon: Icons.health_and_safety_rounded,
      title: 'Welcome to NurseJoy',
      subtitle: 'Your Health, Our Priority',
      description:
          'Connect with healthcare professionals, schedule appointments, and manage your health records all in one secure platform.',
      color: const Color(0xFF4CAF50),
    ),
    OnboardingData(
      icon: Icons.video_call_rounded,
      title: 'Telemedicine Made Simple',
      subtitle: 'Virtual Care Anywhere',
      description:
          'Consult with doctors through secure video calls, chat messaging, and receive expert medical advice from home.',
      color: const Color(0xFF2196F3),
    ),
    OnboardingData(
      icon: Icons.medical_information_rounded,
      title: 'Nurse Joy At Your Service',
      subtitle: 'Your Personal Nurse',
      description:
          'Your personal nurse is here to help you with your health needs. We are here to support you in your health journey.',
      color: const Color(0xFF9C27B0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupSystemUI();
  }

  void _initializeAnimations() {
    _pageController = PageController();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _numPages - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF58f0d7),
              Color(0xFF4dd0e1),
              Color(0xFF26c6da),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Skip button
                  if (_currentPage < _numPages - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, right: 20),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _skipToEnd,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Main content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                        // Add haptic feedback
                        HapticFeedback.lightImpact();
                      },
                      itemCount: _numPages,
                      itemBuilder: (context, index) {
                        return _buildOnboardingPage(_onboardingData[index]);
                      },
                    ),
                  ),

                  // Page indicators
                  _buildPageIndicators(),

                  // Bottom action section
                  _buildBottomSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Animated icon container
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _currentPage == _onboardingData.indexOf(data)
                      ? _pulseAnimation.value
                      : 1.0,
                  child: Container(
                    width: 100, // Reduced from 120
                    height: 100, // Reduced from 120
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      data.icon,
                      size: 50, // Reduced from 60
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40), // Reduced from 48

            // Title with animation
            AnimationLimiter(
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 600),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 30.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 26, // Reduced from 28
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12), // Reduced from 16
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        fontSize: 17, // Reduced from 18
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20), // Reduced from 24
                    Text(
                      data.description,
                      style: TextStyle(
                        fontSize: 15, // Reduced from 16
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5, // Reduced from 1.6
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16), // Reduced from 24
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_numPages, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentPage == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Reduced top margin
      padding: const EdgeInsets.all(20), // Reduced from 24
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20), // Reduced from 24

          if (_currentPage < _numPages - 1) ...[
            // Continue button for onboarding pages
            _buildActionButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              isPrimary: true,
              onPressed: _nextPage,
            ),

            const SizedBox(height: 12), // Reduced from 16

            Text(
              'Swipe to explore features',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ] else ...[
            // Final page - authentication options
            AnimationLimiter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 400),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    const Text(
                      'Ready to Get Started?',
                      style: TextStyle(
                        fontSize: 20, // Reduced from 22
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6), // Reduced from 8
                    Text(
                      'Choose how you\'d like to continue',
                      style: TextStyle(
                        fontSize: 14, // Reduced from 16
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24), // Reduced from 32
                    _buildActionButton(
                      label: 'Sign In',
                      icon: Icons.login_rounded,
                      isPrimary: true,
                      onPressed: () => context.go('/signin'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New to Nurse Joy? Sign up as:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'Patient',
                            icon: Icons.person_add_rounded,
                            isPrimary: false,
                            onPressed: () =>
                                context.go('/register/user'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            label: 'Doctor',
                            icon: Icons.medical_services_rounded,
                            isPrimary: false,
                            onPressed: () =>
                                context.go('/register/doctor'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // Reduced from 16
                    Text.rich(
                      TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms & Privacy Policy',
                            style: const TextStyle(
                              color: Color(0xFF00BCD4), // cyan
                              decorationColor: Color(0xFF00BCD4), // cyan
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const TermsAndPrivacyDialog(), // Your TOS widget
                                );
                              },
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48, // Reduced from 52
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        icon: Icon(
          icon,
          color: isPrimary ? Colors.black87 : const Color(0xFF58f0d7),
          size: 20,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15, // Reduced from 16
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.black87 : const Color(0xFF58f0d7),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF58f0d7) : Colors.white,
          foregroundColor: isPrimary ? Colors.black87 : const Color(0xFF58f0d7),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF58f0d7), width: 2),
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;

  OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
  });
}
