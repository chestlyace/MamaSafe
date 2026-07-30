import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/core/widgets/app_button.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('AppButton', () {
    testWidgets('renders with given label', (tester) async {
      await tester.pumpWidget(createTestApp(
        AppButton.primary('Submit'),
      ));

      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('triggers onPressed when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(createTestApp(
        AppButton.primary(
          'Submit',
          onPressed: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('Submit'));
      expect(tapped, isTrue);
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(createTestApp(
        AppButton.primary(
          'Submit',
          loading: true,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('does not trigger when loading', (tester) async {
      var tapped = false;

      await tester.pumpWidget(createTestApp(
        AppButton.primary(
          'Submit',
          loading: true,
          onPressed: () => tapped = true,
        ),
      ));

      final button = find.byType(InkWell);
      await tester.tap(button);
      expect(tapped, isFalse);
    });

    testWidgets('does not trigger when disabled', (tester) async {
      var tapped = false;

      await tester.pumpWidget(createTestApp(
        AppButton.primary(
          'Submit',
          disabled: true,
          onPressed: () => tapped = true,
        ),
      ));

      final button = find.byType(InkWell);
      await tester.tap(button);
      expect(tapped, isFalse);
    });

    testWidgets('renders secondary variant', (tester) async {
      await tester.pumpWidget(createTestApp(
        AppButton.secondary('Cancel'),
      ));

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders outline variant', (tester) async {
      await tester.pumpWidget(createTestApp(
        AppButton.outline('Skip'),
      ));

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('renders text variant', (tester) async {
      await tester.pumpWidget(createTestApp(
        AppButton.text('Link'),
      ));

      expect(find.text('Link'), findsOneWidget);
    });
  });
}
