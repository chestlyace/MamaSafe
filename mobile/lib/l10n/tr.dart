import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_en.dart' as generated_en;
import 'app_fr.dart' as generated_fr;
import 'localization_provider.dart';

const Map<String, String> enStrings = {
  ...generated_en.enStrings,
  'onboarding.page4Title': 'Emergency Support',
  'onboarding.page4Subtitle':
      'Get in-app notifications for high risk patients and escalated cases.',
  'referral.patientRef': 'Patient Reference',
};

const Map<String, String> frStrings = {
  ...generated_fr.frStrings,
  'onboarding.page4Title': 'Support d\'urgence',
  'onboarding.page4Subtitle':
      'Recevez des notifications dans l\'application pour les patientes à haut risque et les cas escaladés.',
  'referral.patientRef': 'Référence de la patiente',
};

String tr(WidgetRef ref, String key, [Map<String, String> args = const {}]) {
  final locale = ref.watch(localeProvider);
  final strings = locale == AppLocale.fr ? frStrings : enStrings;
  final value = strings[key] ?? key;
  if (args.isEmpty) return value;
  return args.entries.fold(value, (v, e) => v.replaceAll('{${e.key}}', e.value));
}
