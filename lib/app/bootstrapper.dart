import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/platform/platform_utils.dart';
import '../views/splash/splash_screen.dart';
import 'background_services.dart';
import 'buslink_app.dart';
import 'startup.dart';
import 'startup_steps.dart';

/// Starts the app. It shows the start-up screen while [AppStartup] runs, the
/// real [BusLinkApp] when it is done, or "We couldn't start BusLink" with a
/// button if something essential failed.
///
/// On the web, the page itself shows the splash from the first paint (see
/// web/index.html), so people see it while the app is still downloading. This
/// widget fades it out once the first real screen is ready.
class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key, this.startup, this.readyBuilder});

  /// What to run before the app opens. Tests pass their own.
  final AppStartup? startup;

  /// What to show when start-up succeeds. Tests pass their own, so they do not
  /// need Firebase.
  final Widget Function(BuildContext context)? readyBuilder;

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  StartupPhase _phase = StartupPhase.loading;
  AuthService? _authService;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (_phase != StartupPhase.loading) {
      setState(() => _phase = StartupPhase.loading);
    }
    final result = await (widget.startup ?? standardStartup()).run(onSlow: () {
      if (mounted && _phase == StartupPhase.loading) {
        setState(() => _phase = StartupPhase.slow);
        showWebSplashSlow();
      }
    });
    if (!mounted) return;

    if (result.ok) {
      if (widget.readyBuilder == null) {
        _authService = AuthService();
      }
      setState(() => _phase = StartupPhase.ready);
      // Fade the page splash out once the first real screen has been drawn.
      WidgetsBinding.instance.addPostFrameCallback((_) => hideWebSplash());
      if (_authService != null) {
        // Not needed for the first screen, so it starts after it.
        BackgroundServices.start(_authService!);
      }
    } else {
      debugPrint(
          'Start-up failed at "${result.failedStep}": ${result.error}\n${result.stackTrace}');
      setState(() {
        _phase = StartupPhase.failed;
        _error = result.error;
      });
      // The failure screen is the app's own, so uncover it.
      hideWebSplash();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case StartupPhase.ready:
        final custom = widget.readyBuilder;
        if (custom != null) return Builder(builder: custom);
        return BusLinkApp(authService: _authService!);
      case StartupPhase.failed:
        return _shell(StartupFailedScreen(
          onRetry: _start,
          detail: _error?.toString(),
        ));
      case StartupPhase.loading:
      case StartupPhase.slow:
        return _shell(SplashScreen(slow: _phase == StartupPhase.slow));
    }
  }

  /// A bare app around a start-up screen, before the real app exists.
  Widget _shell(Widget child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        // The app always opens in light mode (see ThemeController), so the
        // start-up screens do too.
        theme: AppTheme.lightTheme,
        home: Material(child: child),
      );
}
