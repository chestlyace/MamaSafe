import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/core/widgets/app_card.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('AppCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(createTestApp(
        const AppCard(
          child: Text('Card content'),
        ),
      ));

      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('triggers onTap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(createTestApp(
        AppCard(
          onTap: () => tapped = true,
          child: const Text('Tap me'),
        ),
      ));

      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('renders header when provided', (tester) async {
      await tester.pumpWidget(createTestApp(
        const AppCard(
          header: Text('Header'),
          child: Text('Body'),
        ),
      ));

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('renders footer when provided', (tester) async {
      await tester.pumpWidget(createTestApp(
        const AppCard(
          footer: Text('Footer'),
          child: Text('Body'),
        ),
      ));

      expect(find.text('Footer'), findsOneWidget);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(createTestApp(
        const AppCard(
          padding: EdgeInsets.all(32),
          child: Text('Padded'),
        ),
      ));

      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('does not wrap in GestureDetector when onTap is null',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const AppCard(
          child: Text('No tap'),
        ),
      ));

      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}
