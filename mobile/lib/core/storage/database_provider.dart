import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
