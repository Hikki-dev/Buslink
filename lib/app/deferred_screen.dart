import 'package:flutter/material.dart';

import '../views/splash/splash_screen.dart';

/// Shows a screen whose code is downloaded the first time it is needed.
///
/// Passengers never open the admin or conductor screens, so that code (a big
/// share of the app) is not part of the first download. It is fetched the
/// moment someone signs in as an admin or a conductor, or opens the map.
/// `load` is the `loadLibrary` of a `deferred as` import; `build` makes the
/// screen once it has arrived.
class DeferredScreen extends StatefulWidget {
  final Future<void> Function() load;
  final Widget Function() build;
  final String label;
  const DeferredScreen({
    super.key,
    required this.load,
    required this.build,
    this.label = 'Opening',
  });

  @override
  State<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<DeferredScreen> {
  late Future<void> _loading = widget.load();

  void _retry() => setState(() => _loading = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return widget.build();
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('This part could not load',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('Check the connection and try again.'),
                    const SizedBox(height: 20),
                    FilledButton(
                        onPressed: _retry, child: const Text('Try again')),
                  ],
                ),
              ),
            ),
          );
        }
        return SplashScreen(status: widget.label, playIntro: false);
      },
    );
  }
}

/// Opens a screen from a deferred library on top of the current one.
/// The page slides in once its code has arrived.
Future<T?> pushDeferred<T>(
  BuildContext context, {
  required Future<void> Function() load,
  required Widget Function() build,
}) async {
  await load();
  if (!context.mounted) return null;
  return Navigator.push<T>(context, MaterialPageRoute(builder: (_) => build()));
}
