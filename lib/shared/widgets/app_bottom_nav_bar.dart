import 'package:flutter/material.dart';

class AppBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 65,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: widget.currentIndex.clamp(0, 2), // Handle -1 by clamping to valid range
      onDestinationSelected: widget.onTap,
      destinations: [
        _buildNavDestination(
          index: 0,
          icon: Icons.chat_bubble_rounded,
          label: 'Chat',
          isSelected: widget.currentIndex == 0 && widget.currentIndex != -1,
        ),
        _buildNavDestination(
          index: 1,
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          isSelected: widget.currentIndex == 1 && widget.currentIndex != -1,
        ),
        _buildNavDestination(
          index: 2,
          icon: Icons.person_rounded,
          label: 'Profile',
          isSelected: widget.currentIndex == 2 && widget.currentIndex != -1,
        ),
      ],
    );
  }

  NavigationDestination _buildNavDestination({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return NavigationDestination(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle for selected state
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isSelected ? 40 : 0,
            height: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF58f0d7).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          // Icon with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Icon(
              icon,
              size: isSelected ? 26 : 24,
              color:
                  isSelected ? const Color(0xFF58f0d7) : Colors.grey.shade600,
            ),
          ),
        ],
      ),
      label: label,
      selectedIcon: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF58f0d7).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            icon,
            size: 26,
            color: const Color(0xFF58f0d7),
          ),
        ],
      ),
    );
  }
}

// Alternative Floating Action Button Style Navigation
class AppBottomNavBarFloating extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavBarFloating({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNavBarFloating> createState() =>
      _AppBottomNavBarFloatingState();
}

class _AppBottomNavBarFloatingState extends State<AppBottomNavBarFloating>
    with TickerProviderStateMixin {
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
      begin: Offset(widget.currentIndex.toDouble(), 0),
      end: Offset(widget.currentIndex.toDouble(), 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AppBottomNavBarFloating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _slideAnimation = Tween<Offset>(
        begin: Offset(oldWidget.currentIndex.toDouble(), 0),
        end: Offset(widget.currentIndex.toDouble(), 0),
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeInOut,
      ));
      _slideController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Background container
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF58f0d7).withOpacity(0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFloatingNavItem(
                  index: 0,
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                ),
                _buildFloatingNavItem(
                  index: 1,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                ),
                _buildFloatingNavItem(
                  index: 2,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
          // Sliding indicator
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Positioned(
                left: (MediaQuery.of(context).size.width - 80) /
                        3 *
                        _slideAnimation.value.dx +
                    20,
                top: 10,
                child: Container(
                  width: (MediaQuery.of(context).size.width - 80) / 3,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF58f0d7),
                        Color(0xFF4dd0e1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF58f0d7).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        child: SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Minimal Pill Style Navigation
class AppBottomNavBarPill extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavBarPill({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF58f0d7).withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPillNavItem(
                  index: 0,
                  icon: Icons.chat_bubble_rounded,
                  isSelected: currentIndex == 0,
                ),
                const SizedBox(width: 8),
                _buildPillNavItem(
                  index: 1,
                  icon: Icons.dashboard_rounded,
                  isSelected: currentIndex == 1,
                ),
                const SizedBox(width: 8),
                _buildPillNavItem(
                  index: 2,
                  icon: Icons.person_rounded,
                  isSelected: currentIndex == 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillNavItem({
    required int index,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF58f0d7) : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF58f0d7).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }
}
