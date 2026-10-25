import 'package:buslink/views/layout/app_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'the footer is as tall as its text, even when offered a lot of room',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CustomScrollView(slivers: [
      const SliverToBoxAdapter(child: SizedBox(height: 300)),
      const SliverFillRemaining(
          hasScrollBody: false,
          child: Align(alignment: Alignment.bottomCenter, child: AppFooter())),
    ]))));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AppFooter)).height, lessThan(260));
    // and it sits at the bottom of the window
    expect(tester.getBottomLeft(find.byType(AppFooter)).dy, 1000);
  });
}
