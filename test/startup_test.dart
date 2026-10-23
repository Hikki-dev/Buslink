import 'package:buslink/app/startup.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  group('AppStartup', () {
    test('runs steps at the same time, not one after another', () async {
      final clock = Stopwatch()..start();
      final result = await AppStartup([
        StartupStep('a', () => _wait(120)),
        StartupStep('b', () => _wait(120)),
        StartupStep('c', () => _wait(120)),
      ]).run();
      expect(result.ok, isTrue);
      // One after another would take 360 ms or more.
      expect(clock.elapsedMilliseconds, lessThan(300));
      expect(result.timings.keys, containsAll(['a', 'b', 'c']));
    });

    test('a step waits for the steps named in `after`', () async {
      final order = <String>[];
      await AppStartup([
        StartupStep('second', () async => order.add('second'),
            after: ['first']),
        StartupStep('first', () async {
          await _wait(60);
          order.add('first');
        }),
      ]).run();
      expect(order, ['first', 'second']);
    });

    test('a step that is not critical can fail without stopping the app',
        () async {
      final result = await AppStartup([
        StartupStep('nice', () async => throw StateError('no .env'),
            critical: false),
        StartupStep('needed', () async {}),
      ]).run();
      expect(result.ok, isTrue);
      expect(result.failedStep, isNull);
    });

    test('a critical step that fails fails start-up and names the step',
        () async {
      final result = await AppStartup([
        StartupStep('firebase', () async => throw StateError('no network')),
        StartupStep('other', () async {}),
      ]).run();
      expect(result.ok, isFalse);
      expect(result.failedStep, 'firebase');
      expect(result.error, isA<StateError>());
    });

    test('work that depends on a failed step is not started', () async {
      var ran = false;
      final result = await AppStartup([
        StartupStep('firebase', () async => throw StateError('down')),
        StartupStep('auth', () async => ran = true, after: ['firebase']),
      ]).run();
      expect(result.ok, isFalse);
      expect(ran, isFalse);
    });

    test('says so when start-up is slow, and not when it is quick', () async {
      var slow = 0;
      await AppStartup(
        [StartupStep('slowpoke', () => _wait(120))],
        slowAfter: const Duration(milliseconds: 40),
      ).run(onSlow: () => slow++);
      expect(slow, 1);

      slow = 0;
      await AppStartup(
        [StartupStep('quick', () async {})],
        slowAfter: const Duration(milliseconds: 40),
      ).run(onSlow: () => slow++);
      expect(slow, 0);
    });

    test('gives up after the time limit instead of waiting for ever', () async {
      final result = await AppStartup(
        [StartupStep('stuck', () => _wait(500))],
        giveUpAfter: const Duration(milliseconds: 60),
      ).run();
      expect(result.ok, isFalse);
      expect(result.failedStep, 'timeout');
    });

    test('a step that waits for a step that does not exist is a mistake',
        () async {
      expect(
        () => AppStartup([
          StartupStep('x', () async {}, after: ['missing'])
        ]).run(),
        throwsArgumentError,
      );
    });
  });
}
