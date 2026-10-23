import 'dart:async';

import 'package:flutter/foundation.dart';

/// What the start-up screen should be showing.
enum StartupPhase { loading, slow, failed, ready }

/// One thing the app does before it shows its first real screen.
class StartupStep {
  const StartupStep(
    this.name,
    this.run, {
    this.critical = true,
    this.after = const [],
  });

  final String name;
  final Future<void> Function() run;

  /// A critical step that fails stops the app and shows "We couldn't start".
  /// A step that is not critical is logged and the app carries on without it.
  final bool critical;

  /// Names of steps that must finish before this one begins.
  final List<String> after;
}

/// How start-up went.
class StartupResult {
  const StartupResult({
    required this.timings,
    this.error,
    this.stackTrace,
    this.failedStep,
  });

  /// How long each step took. A step that never started is missing.
  final Map<String, Duration> timings;
  final Object? error;
  final StackTrace? stackTrace;

  /// The step that failed (or `timeout` if start-up took too long).
  final String? failedStep;

  bool get ok => error == null;
}

/// Runs the start-up steps all at once, so the app is ready as soon as the
/// slowest one is, instead of as soon as all of them have run one after
/// another. A step may wait for others with [StartupStep.after].
///
/// It knows nothing about Firebase or screens, so it can be tested on its own.
class AppStartup {
  AppStartup(
    this.steps, {
    this.slowAfter = const Duration(seconds: 8),
    this.giveUpAfter = const Duration(seconds: 30),
  });

  final List<StartupStep> steps;

  /// After this long, [run] calls its `onSlow` so the screen can say so.
  final Duration slowAfter;

  /// After this long, start-up is treated as failed.
  final Duration giveUpAfter;

  Future<StartupResult> run({VoidCallback? onSlow}) async {
    final byName = {for (final s in steps) s.name: s};
    final timings = <String, Duration>{};
    final started = <String, Future<void>>{};
    Object? error;
    StackTrace? stackTrace;
    String? failedStep;

    Future<void> start(String name) {
      final already = started[name];
      if (already != null) return already;
      final step = byName[name];
      if (step == null) {
        throw ArgumentError('Start-up step "$name" does not exist.');
      }

      Future<void> go() async {
        for (final dependency in step.after) {
          await start(dependency);
        }
        // Do not begin new work once a critical step has already failed.
        if (error != null) return;
        final clock = Stopwatch()..start();
        try {
          await step.run();
        } catch (e, trace) {
          if (step.critical) {
            error ??= e;
            stackTrace ??= trace;
            failedStep ??= step.name;
          } else {
            debugPrint('Start-up step "${step.name}" failed, carrying on: $e');
          }
        }
        timings[step.name] = clock.elapsed;
      }

      return started[name] = go();
    }

    final slowTimer = onSlow == null ? null : Timer(slowAfter, onSlow);
    try {
      await Future.wait([for (final s in steps) start(s.name)])
          .timeout(giveUpAfter);
    } on TimeoutException catch (e, trace) {
      error ??= e;
      stackTrace ??= trace;
      failedStep ??= 'timeout';
    } finally {
      slowTimer?.cancel();
    }

    if (kDebugMode) {
      final report = timings.entries
          .map((e) => '${e.key} ${e.value.inMilliseconds} ms')
          .join(', ');
      debugPrint('Start-up: $report');
    }
    return StartupResult(
      timings: timings,
      error: error,
      stackTrace: stackTrace,
      failedStep: failedStep,
    );
  }
}
