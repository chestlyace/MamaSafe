import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/core/widgets/app_text_field.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Form(
        child: child,
      ),
    ),
  );
}

void main() {
  group('AppTextField', () {
    testWidgets('renders with hint text', (tester) async {
      await tester.pumpWidget(createTestApp(
        const AppTextField(hint: 'Enter your email'),
      ));

      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(createTestApp(
        const AppTextField(label: 'Email', hint: 'Enter your email'),
      ));

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('shows validation error', (tester) async {
      await tester.pumpWidget(createTestApp(
        const AppTextField(
          label: 'Email',
          errorText: 'Email is required',
        ),
      ));

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('password toggle works', (tester) async {
      await tester.pumpWidget(createTestApp(
        const AppTextField(
          label: 'Password',
          obscureText: true,
        ),
      ));

      // Starts obscured — visibility off icon shown
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Tap the toggle icon
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      // Now visibility icon shown
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('renders with prefix icon', (tester) async {
      await tester.pumpWidget(createTestApp(
        const AppTextField(
          hint: 'Email',
          prefixIcon: Icons.email_outlined,
        ),
      ));

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('text input works', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(createTestApp(
        AppTextField(
          hint: 'Enter text',
          controller: controller,
        ),
      ));

      await tester.enterText(find.byType(TextFormField), 'Hello');
      expect(controller.text, 'Hello');
    });

    testWidgets('clear button appears and clears text', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(createTestApp(
        AppTextField(
          hint: 'Enter text',
          controller: controller,
        ),
      ));

      await tester.enterText(find.byType(TextFormField), 'Hello');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(controller.text, isEmpty);
    });
  });
}
