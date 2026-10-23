import 'package:flutter/material.dart';

import 'app/bootstrapper.dart';

// Kept so older tests that import main.dart still find these.
export 'app/auth_gate.dart' show AuthWrapper, RoleDispatcher;
export 'app/bootstrapper.dart' show AppBootstrapper;

/// Draws the start-up screen straight away. Everything slow (Firebase, the
/// settings file, notifications, Stripe) happens after that, in
/// `lib/app/startup_steps.dart` and `lib/app/background_services.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrapper());
}
