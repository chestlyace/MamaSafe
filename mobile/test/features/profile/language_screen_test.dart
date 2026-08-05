import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/features/profile/screens/language_screen.dart';
import 'package:mamasafe/l10n/localization_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> createContainer() async {
    final container = ProviderContainer();
    await container.read(localeProvider.notifier).loadLocale();
    return container;
  }

  Widget createTestApp(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: LanguageScreen(),
      ),
    );
  }

  testWidgets('renders both languages with English selected by default',
      (tester) async {
    final container = await createContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(createTestApp(container));

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Choose your preferred language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);

    final checkIcons = tester
        .widgetList<Icon>(find.byIcon(Icons.check_circle))
        .toList();
    expect(checkIcons, hasLength(1));
  });

  testWidgets('tapping Français switches locale and persists', (tester) async {
    final container = await createContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(createTestApp(container));

    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();

    expect(find.text('Langue'), findsOneWidget);
    expect(find.text('Anglais'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'fr');
  });

  testWidgets('tapping English switches back', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'fr'});
    final container = await createContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(createTestApp(container));

    expect(find.text('Anglais'), findsOneWidget);

    await tester.tap(find.text('Anglais'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'en');
  });
}
