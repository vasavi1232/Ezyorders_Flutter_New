import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/session_service.dart';
import '../providers/auth_provider.dart';
import '../../config/routes/app_router.dart';

class GlobalSessionListener extends StatefulWidget {
  final Widget child;

  const GlobalSessionListener({super.key, required this.child});

  @override
  State<GlobalSessionListener> createState() => _GlobalSessionListenerState();
}

class _GlobalSessionListenerState extends State<GlobalSessionListener> {
  StreamSubscription? _sessionSubscription;
  bool _isSessionDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _sessionSubscription =
        getIt<SessionService>().sessionExpiredStream.listen((_) {
      _handleSessionExpired();
    });
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }

  void _handleSessionExpired() {
    if (_isSessionDialogShowing) return;

    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;

    _isSessionDialogShowing = true;

    // Clear Session
    context.read<AuthProvider>().clearSession();

    // Show Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Session Expired",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Your session has expired. Please login again to continue.",
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
      ),
    );

    // Auto-dismiss after 3 seconds and navigate to companies
    Timer(const Duration(seconds: 3), () {
      if (_isSessionDialogShowing && mounted) {
        _isSessionDialogShowing = false;
        final navContext = AppRouter.navigatorKey.currentContext;
        if (navContext != null) {
          Navigator.pop(navContext);
          navContext.go('/companies');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
