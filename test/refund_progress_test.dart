import 'package:buslink/models/refund_model.dart';
import 'package:buslink/views/booking/refund_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(RefundStatus s) => MaterialApp(
    home: Scaffold(
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: RefundProgress(status: s))));

void main() {
  test('pending is "in review", every decided state is step 3', () {
    expect(RefundProgress.stepFor(RefundStatus.pending), 1);
    for (final s in [
      RefundStatus.approved,
      RefundStatus.processed,
      RefundStatus.rejected,
      RefundStatus.failed
    ]) {
      expect(RefundProgress.stepFor(s), 2);
    }
  });

  testWidgets('pending shows Sent, In review, Decision', (tester) async {
    await tester.pumpWidget(_wrap(RefundStatus.pending));
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('In review'), findsOneWidget);
    expect(find.text('Decision'), findsOneWidget);
  });

  testWidgets('decided states name the outcome', (tester) async {
    await tester.pumpWidget(_wrap(RefundStatus.approved));
    expect(find.text('Approved'), findsOneWidget);
    await tester.pumpWidget(_wrap(RefundStatus.rejected));
    expect(find.text('Rejected'), findsOneWidget);
  });
}
