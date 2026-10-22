import 'package:buslink/views/conductor/conductor_trip_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int?> _open(WidgetTester tester) async {
  int? result;
  var done = false;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              result = await showDialog<int>(
                  context: context, builder: (_) => const DelayDialog());
              done = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(done, isFalse);
  return result;
}

void main() {
  testWidgets('quick-pick chip then Confirm returns that many minutes',
      (tester) async {
    int? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => result = await showDialog<int>(
              context: context, builder: (_) => const DelayDialog()),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 min'));
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(result, 30);
  });

  testWidgets('empty or out-of-range input shows a message and stays open',
      (tester) async {
    await _open(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(find.text('Enter a number from 1 to 600.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '5000');
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(find.text('Enter a number from 1 to 600.'), findsOneWidget);
    expect(find.text('Report Delay'), findsOneWidget);
  });
}
