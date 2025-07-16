import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/auth/provider/session_timeout_service.dart';

/// A wrapper widget that monitors user interactions for session timeout
///
/// This widget intercepts all user gestures and notifies the SessionTimeoutService
/// to reset the inactivity timer whenever the user interacts with the app.
///
/// Usage: Wrap your main app widget with this detector
class SessionActivityDetector extends StatefulWidget {
  final Widget child;

  const SessionActivityDetector({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<SessionActivityDetector> createState() =>
      _SessionActivityDetectorState();
}

class _SessionActivityDetectorState extends State<SessionActivityDetector> {
  SessionTimeoutService? _sessionService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sessionService =
        Provider.of<SessionTimeoutService>(context, listen: false);
  }

  /// Record user activity when any gesture is detected
  void _onUserActivity() {
    _sessionService?.recordActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onUserActivity(),
      onPointerMove: (_) => _onUserActivity(),
      onPointerUp: (_) => _onUserActivity(),
      child: GestureDetector(
        onTap: _onUserActivity,
        onScaleStart: (_) => _onUserActivity(),
        onScaleUpdate: (_) => _onUserActivity(),
        onScaleEnd: (_) => _onUserActivity(),
        behavior: HitTestBehavior.translucent,
        child: widget.child,
      ),
    );
  }
}

/// A mixin for widgets that need to be aware of session status
///
/// This mixin provides easy access to session timeout functionality
/// and can be used in pages that contain sensitive information.
mixin SessionAwareMixin<T extends StatefulWidget> on State<T> {
  SessionTimeoutService? _sessionService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sessionService =
        Provider.of<SessionTimeoutService>(context, listen: false);
  }

  /// Check if the session is still valid
  bool get isSessionValid => _sessionService?.isSessionValid ?? false;

  /// Get remaining session time
  Duration get remainingSessionTime =>
      _sessionService?.remainingTime ?? Duration.zero;

  /// Record activity manually (useful for specific interactions)
  void recordActivity() => _sessionService?.recordActivity();

  /// Check if re-authentication should be required for sensitive operations
  bool shouldRequireReauth() => _sessionService?.shouldRequireReauth() ?? true;

  /// Force logout with optional reason
  Future<void> forceLogout({String? reason}) async {
    await _sessionService?.forceLogout(reason: reason);
  }
}

/// A widget that displays session information (for debugging/admin purposes)
class SessionStatusWidget extends StatefulWidget {
  const SessionStatusWidget({Key? key}) : super(key: key);

  @override
  State<SessionStatusWidget> createState() => _SessionStatusWidgetState();
}

class _SessionStatusWidgetState extends State<SessionStatusWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SessionTimeoutService>(
      builder: (context, sessionService, child) {
        final status = sessionService.getSessionStatus();
        final remainingTime = sessionService.remainingTime;

        return Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: sessionService.isSessionValid
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sessionService.isSessionValid ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    sessionService.isSessionValid
                        ? Icons.check_circle
                        : Icons.error,
                    color: sessionService.isSessionValid
                        ? Colors.green
                        : Colors.red,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Session Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Valid: ${status['isSessionValid']}',
                style: TextStyle(fontSize: 10),
              ),
              Text(
                'Remaining: ${remainingTime.inMinutes}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 10),
              ),
              if (status['lastActivity'] != null)
                Text(
                  'Last Activity: ${DateTime.parse(status['lastActivity']).toLocal().toString().substring(11, 19)}',
                  style: TextStyle(fontSize: 10),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A route guard that checks session validity before allowing access to secure pages
class SessionGuard extends StatelessWidget {
  final Widget child;
  final bool requireReauth;
  final String? redirectRoute;

  const SessionGuard({
    Key? key,
    required this.child,
    this.requireReauth = false,
    this.redirectRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionTimeoutService>(
      builder: (context, sessionService, _) {
        // Check if session is valid
        if (!sessionService.isSessionValid) {
          return _buildSessionExpiredView(context);
        }

        // Check if re-authentication is required for sensitive operations
        if (requireReauth && sessionService.shouldRequireReauth()) {
          return _buildReauthRequiredView(context, sessionService);
        }

        // Session is valid, show the protected content
        return child;
      },
    );
  }

  Widget _buildSessionExpiredView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session Expired'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_off,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Session Expired',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your session has expired due to inactivity. Please sign in again to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/entry');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF58f0d7),
                  foregroundColor: Colors.black87,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text('Sign In Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReauthRequiredView(
      BuildContext context, SessionTimeoutService sessionService) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Re-authentication Required'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: Colors.orange,
              ),
              SizedBox(height: 16),
              Text(
                'Security Check',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This secure area requires recent authentication. Please verify your identity to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Go Back'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      sessionService.forceLogout(
                        reason:
                            'Re-authentication required for secure area access',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF58f0d7),
                      foregroundColor: Colors.black87,
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text('Re-authenticate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
