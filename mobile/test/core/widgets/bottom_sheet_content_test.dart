import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/bottom_sheet_content.dart';

/// Mobile Fix #5 (Responsive Layout / Bottom Navigation Overlap) —
/// regression coverage for the shared sheet wrapper: it must apply a
/// [SafeArea] (the OS system inset — Android's gesture/3-button
/// navigation bar, iOS's home indicator — none of which `viewInsets`
/// covers) and a scroll view (so content taller than the available
/// height, e.g. a short device with the keyboard open, scrolls instead
/// of overflowing or pushing its bottom button off-screen).
void main() {
  testWidgets('wraps content in a SafeArea and a scroll view', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BottomSheetContent(child: Text('content'))),
      ),
    );

    expect(find.byType(SafeArea), findsWidgets);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets(
    'a bottom button stays reachable and tappable under a short viewport with a system nav bar inset',
    (tester) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomSheetContent(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Deliberately taller than the 500px viewport so the
                  // button can only be reached by scrolling.
                  const SizedBox(height: 700),
                  ElevatedButton(
                    onPressed: () => tapped = true,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.dragUntilVisible(
        find.text('Save'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bottom padding adds the keyboard inset on top of the fixed gap, independent of the system inset',
    (tester) async {
      // Deliberately not wrapped in a Scaffold: showModalBottomSheet renders
      // its builder's content directly (not inside a Scaffold body), so a
      // Scaffold's own resizeToAvoidBottomInset (which would otherwise
      // consume viewInsets.bottom before this widget ever saw it) is not
      // part of the real usage this is regression-testing.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 20),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: const MaterialApp(
            home: Material(
              child: BottomSheetContent(child: SizedBox(height: 10)),
            ),
          ),
        ),
      );

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final padding = scrollView.padding! as EdgeInsets;

      // 300 (keyboard) + 16 (fixed gap) — the 20px system inset is handled
      // separately by SafeArea, not folded into this padding value.
      expect(padding.bottom, 316);
    },
  );
}
