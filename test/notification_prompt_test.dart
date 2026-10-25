import 'package:buslink/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () =>
            NotificationService.requestPermissionWithDialog(context),
        child: const Text('ask'),
      ),
    ),
  ));
  await tester.tap(find.text('ask'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(NotificationService.forgetAskedThisRun);

  testWidgets('after "Allow" the prompt never comes back', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'notification_prompt_answer': 'allowed'});
    await _open(tester);
    expect(find.text('Stay Updated'), findsNothing);
  });

  testWidgets('"Later" waits a week before asking again', (tester) async {
    SharedPreferences.setMockInitialValues({
      'notification_prompt_later_at': DateTime.now()
          .subtract(const Duration(days: 2))
          .millisecondsSinceEpoch
    });
    await _open(tester);
    expect(find.text('Stay Updated'), findsNothing);
  });
}
