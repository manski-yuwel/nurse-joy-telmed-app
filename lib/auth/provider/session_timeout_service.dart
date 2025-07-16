import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:go_router/go_router.dart';

/// Service to handle session timeout and automatic logout after user inactivity
///
/// This service monitors user activity and automatically logs out users after
/// a period of inactivity (default: 10 minutes) for security purposes.
///
/// Test Case TC38: Validate session expiration and security after user inactivity
class SessionTimeoutService extends ChangeNotifier with WidgetsBindingObserver {
  static const Duration _timeoutDuration = Duration(minutes: 10);
  static const Duration _warningDuration =
      Duration(minutes: 8); // Warning at 8 minutes

  final Logger _logger = Logger();
  final AuthService _authService;

  Timer? _sessionTimer;
  Timer? _warningTimer;
  DateTime? _lastActivity;
  bool _isWarningShown = false;
  bool _isActive = false;
  BuildContext? _context;
  String _currentRoute = '';

  /// Callback for when session expires
  VoidCallback? onSessionExpired;

  /// Callback for when warning is shown
  VoidCallback? onWarningShown;

  SessionTimeoutService(this._authService) {
    WidgetsBinding.instance.addObserver(this);
    _authService.addListener(_onAuthStateChanged);
  }

  /// Initialize the session timeout service with context
  void initialize(BuildContext context) {
    _context = context;
    _logger.i('SessionTimeoutService initialized');
  }

  /// Set current route for timeout exclusion check
  void setCurrentRoute(String route) {
    _currentRoute = route;
    _logger.d('Current route set to: $route');
  }

  /// Start session monitoring when user is authenticated
  void startSession() {
    if (_authService.user == null) return;

    _isActive = true;
    _lastActivity = DateTime.now();
    _resetTimers();
    _logger.i('Session monitoring started for user: ${_authService.user?.uid}');
  }

  /// Stop session monitoring
  void stopSession() {
    _isActive = false;
    _cancelTimers();
    _lastActivity = null;
    _isWarningShown = false;
    _logger.i('Session monitoring stopped');
  }

  /// Record user activity to reset the timeout
  void recordActivity() {
    if (!_isActive || _authService.user == null) return;

    _lastActivity = DateTime.now();
    _isWarningShown = false;
    _resetTimers();

    // Log activity (only in debug mode to avoid spam)
    _logger.d('User activity recorded at ${_lastActivity}');
  }

  /// Check if session is still valid
  bool get isSessionValid {
    if (!_isActive || _lastActivity == null) return false;

    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(_lastActivity!);
    return timeSinceLastActivity < _timeoutDuration;
  }

  /// Get remaining session time
  Duration get remainingTime {
    if (!_isActive || _lastActivity == null) return Duration.zero;

    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(_lastActivity!);
    final remaining = _timeoutDuration - timeSinceLastActivity;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Reset session timers
  void _resetTimers() {
    _cancelTimers();

    // Set warning timer (8 minutes)
    _warningTimer = Timer(_warningDuration, _showSessionWarning);

    // Set session timeout timer (10 minutes)
    _sessionTimer = Timer(_timeoutDuration, _handleSessionTimeout);
  }

  /// Cancel all active timers
  void _cancelTimers() {
    _sessionTimer?.cancel();
    _warningTimer?.cancel();
    _sessionTimer = null;
    _warningTimer = null;
  }

  /// Show session warning dialog
  void _showSessionWarning() {
    if (!_isActive || _isWarningShown || _context == null) return;

    _isWarningShown = true;
    _logger.w('Session warning shown - 2 minutes remaining');

    // Trigger warning callback
    onWarningShown?.call();

    // Show warning dialog
    _showWarningDialog();
  }

  /// Show warning dialog to user
  void _showWarningDialog() {
    if (_context == null || !_context!.mounted) return;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Session Expiring'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your session will expire in 2 minutes due to inactivity.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Do you want to continue your session?',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleSessionTimeout();
            },
            child: Text('Logout'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              recordActivity(); // Extend session
              HapticFeedback.lightImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF58f0d7),
              foregroundColor: Colors.black87,
            ),
            child: Text('Continue Session'),
          ),
        ],
      ),
    );
  }

  /// Handle session timeout - logout user
  void _handleSessionTimeout() {
    if (!_isActive) return;

    _logger.w('Session timeout - logging out user: ${_authService.user?.uid}');

    // Trigger session expired callback
    onSessionExpired?.call();

    // Stop session monitoring
    stopSession();

    // Show timeout message
    _showTimeoutMessage();

    // Logout user
    _performLogout();
  }

  /// Show session timeout message
  void _showTimeoutMessage() {
    if (_context == null || !_context!.mounted) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.timer_off, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Session expired due to inactivity. Please sign in again.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Perform logout operation
  Future<void> _performLogout() async {
    try {
      await _authService.signOut();

      // Navigate to entry page
      if (_context != null && _context!.mounted) {
        _context!.go('/entry');
      }
    } catch (e) {
      _logger.e('Error during session timeout logout: $e');
    }
  }

  /// Listen to auth state changes
  void _onAuthStateChanged() {
    if (_authService.user == null) {
      // User logged out, stop session monitoring
      stopSession();
    } else {
      // User logged in, start session monitoring
      startSession();
    }
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed, record activity
        if (_isActive) {
          recordActivity();
          _logger.i('App resumed - session activity recorded');
        }
        break;
      case AppLifecycleState.paused:
        // App paused, but don't stop session (continues in background)
        _logger.i('App paused - session continues in background');
        break;
      case AppLifecycleState.detached:
        // App detached, stop session
        stopSession();
        _logger.i('App detached - session stopped');
        break;
      case AppLifecycleState.inactive:
        // App inactive, continue session
        break;
      case AppLifecycleState.hidden:
        // App hidden, continue session
        break;
    }
  }

  /// Dispose and cleanup
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authService.removeListener(_onAuthStateChanged);
    _cancelTimers();
    super.dispose();
  }

  /// Check if user should be prompted for re-authentication when accessing secure areas
  bool shouldRequireReauth() {
    if (!_isActive || _lastActivity == null)
      return true; // Require re-auth if session is not active or last activity is unknown

    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(_lastActivity!);

    // Require re-auth if inactive for more than 5 minutes when accessing secure areas
    return timeSinceLastActivity > Duration(minutes: 5);
  }

  /// Force logout (for security checks)
  Future<void> forceLogout({String? reason}) async {
    _logger.w('Force logout initiated. Reason: ${reason ?? 'Security check'}');

    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content:
              Text(reason ?? 'Security check required. Please sign in again.'),
          backgroundColor: Colors.orange[600],
          duration: Duration(seconds: 4),
        ),
      );
    }

    await _performLogout();
  }

  /// Get session status for debugging
  Map<String, dynamic> getSessionStatus() {
    return {
      'isActive': _isActive,
      'isSessionValid': isSessionValid,
      'lastActivity': _lastActivity?.toIso8601String(),
      'remainingTime': remainingTime.inMinutes,
      'isWarningShown': _isWarningShown,
      'userId': _authService.user?.uid,
    };
  }
}
