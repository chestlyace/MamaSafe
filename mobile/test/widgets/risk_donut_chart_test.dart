import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/features/dashboard/widgets/risk_donut_chart.dart';
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

  Widget wrap(ProviderContainer container, Widget child) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('renders three segments and a center total', (tester) async {
    final container = await createContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(wrap(
      container,
      const RiskDonutChart(
        highRisk: 2,
        midRisk: 5,
        lowRisk: 8,
        totalAssessments: 15,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(RiskDonutChart), findsOneWidget);
  });

  testWidgets('renders empty state when nothing to show', (tester) async {
    final container = await createContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(wrap(
      container,
      const RiskDonutChart(
        highRisk: 0,
        midRisk: 0,
        lowRisk: 0,
        totalAssessments: 0,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No assessments yet'), findsOneWidget);
  });
}
