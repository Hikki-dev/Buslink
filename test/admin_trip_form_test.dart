import 'package:buslink/controllers/trip_controller.dart';
import 'package:buslink/services/auth_service.dart';
import 'package:buslink/utils/app_theme.dart';
import 'package:buslink/views/admin/admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/app_fonts.dart';

/// AuthService creates Firebase objects in its field initialisers, so tests
/// use a stand-in that never touches Firebase.
class _FakeAuth implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('trip form: Next is blocked until step 1 is valid, then advances',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<TripController>(create: (_) => TripController()),
        Provider<AuthService>.value(value: _FakeAuth()),
      ],
      child: MaterialApp(
          theme: AppTheme.lightTheme, home: const AdminScreen(trip: null)),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('Step 1 of 3: Route'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    expect(find.text('Back'), findsNothing);

    // Empty origin/destination: stays on step 1 and shows "Required".
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    expect(find.text('Required'), findsWidgets);
    expect(find.bySemanticsLabel('Step 1 of 3: Route'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Colombo');
    await tester.enterText(find.byType(TextFormField).at(1), 'Kandy');
    // Via is required too: it is the third text field on this step.
    await tester.enterText(find.byType(TextFormField).at(2), 'Expressway');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    expect(find.bySemanticsLabel('Step 2 of 3: Schedule'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    // Back keeps what was typed.
    await tester.tap(find.text('Back'));
    await tester.pump();
    expect(find.text('Colombo'), findsOneWidget);
    expect(find.text('Kandy'), findsOneWidget);

    // Forward twice reaches the save step.
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    expect(find.bySemanticsLabel('Step 3 of 3: Fare & bus'), findsOneWidget);
    expect(find.text('SAVE TRIP'), findsOneWidget);
  });
}
