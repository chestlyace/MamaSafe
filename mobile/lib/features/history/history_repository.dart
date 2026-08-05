import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';
import '../assessment/assessment_repository.dart';
import '../patients/patient_repository.dart';

class HistoryItem {
  final int id;
  final String type;
  final String title;
  final String? subtitle;
  final DateTime date;
  final String riskLevel;
  final String route;

  const HistoryItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.date,
    this.riskLevel = 'unknown',
    required this.route,
  });
}

class HistoryRepository {
  final AppDatabase _db;

  HistoryRepository(this._db);

  Future<List<HistoryItem>> getHistory({
    String? search,
    String? riskFilter,
    String? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final items = <HistoryItem>[];

    final patientRows = await _db.select(_db.patients).get();
    final patientNames = {for (final p in patientRows) p.id: p.fullName};

    // Note: The server now scopes assessments and patients by the
    // authenticated user's role/district before returning them, so the local
    // database only contains records the current user is allowed to see.
    final assessments = await (_db.select(_db.assessments)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();
    for (final a in assessments) {
      final patientId = int.tryParse(a.patientRef ?? '');
      final patientName = patientId != null ? patientNames[patientId] : null;
      if (_matchesTypeFilter('assessment', typeFilter) &&
          _matchesFilter(search, '${patientName ?? ''} ${a.patientRef} ${a.id}') &&
          _matchesRiskFilter(a.riskLevel, riskFilter) &&
          _matchesDateFilter(a.createdAt, startDate, endDate)) {
        items.add(HistoryItem(
          id: a.id,
          type: 'assessment',
          title: patientName ?? a.patientRef ?? 'Assessment #${a.id}',
          subtitle: _assessmentSubtitle(a),
          date: a.createdAt,
          riskLevel: a.riskLevel,
          route: '/assessments/${a.id}',
        ));
      }
    }

    final patients = await (_db.select(_db.patients)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();
    for (final p in patients) {
      if (_matchesTypeFilter('patient', typeFilter) &&
          _matchesFilter(search, '${p.fullName} ${p.phone}') &&
          _matchesDateFilter(p.createdAt, startDate, endDate)) {
        items.add(HistoryItem(
          id: p.id,
          type: 'patient',
          title: p.fullName,
          subtitle: p.phone,
          date: p.createdAt,
          route: '/home/patients/${p.id}',
        ));
      }
    }

    final pregnancies = await (_db.select(_db.pregnancies)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();
    for (final pr in pregnancies) {
      if (_matchesTypeFilter('pregnancy', typeFilter) &&
          _matchesFilter(search, '${pr.patientName} ${pr.patientRef}') &&
          _matchesDateFilter(pr.createdAt, startDate, endDate)) {
        items.add(HistoryItem(
          id: pr.id,
          type: 'pregnancy',
          title: pr.patientName,
          subtitle: '${pr.gestationalAgeWeeks ?? 0} weeks',
          date: pr.createdAt,
          riskLevel: pr.riskLevel ?? 'unknown',
          route: '/home/pregnancies/${pr.id}',
        ));
      }
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  static String _assessmentSubtitle(Assessment a) {
    final parts = <String>[
      if (a.age > 0) '${a.age.toStringAsFixed(0)} yrs',
      if (a.systolicBp > 0)
        'BP ${a.systolicBp.toStringAsFixed(0)}/${a.diastolicBp.toStringAsFixed(0)}',
      if (a.bloodSugar > 0) 'BS ${a.bloodSugar.toStringAsFixed(1)} mmol/L',
    ];
    if (parts.isEmpty && a.recommendation != null) return a.recommendation!;
    return parts.join(' · ');
  }

  bool _matchesFilter(String? search, String value) {
    if (search == null || search.isEmpty) return true;
    return value.toLowerCase().contains(search.toLowerCase());
  }

  bool _matchesRiskFilter(String riskLevel, String? filter) {
    if (filter == null || filter == 'all') return true;
    return riskLevel == filter;
  }

  bool _matchesTypeFilter(String type, String? filter) {
    if (filter == null || filter == 'all') return true;
    return type == filter;
  }

  bool _matchesDateFilter(DateTime date, DateTime? start, DateTime? end) {
    if (start != null && date.isBefore(start)) return false;
    if (end != null && date.isAfter(end.add(const Duration(days: 1)))) return false;
    return true;
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return HistoryRepository(db);
});

class HistoryFilterParams {
  final String? search;
  final String? riskFilter;
  final String? typeFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  const HistoryFilterParams({
    this.search,
    this.riskFilter,
    this.typeFilter,
    this.startDate,
    this.endDate,
  });

  HistoryFilterParams copyWith({
    String? search,
    String? riskFilter,
    String? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return HistoryFilterParams(
      search: search ?? this.search,
      riskFilter: riskFilter ?? this.riskFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class HistoryLoadResult {
  final List<HistoryItem> items;
  final bool synced;

  const HistoryLoadResult({required this.items, required this.synced});
}

final historyProvider =
    FutureProvider.family<HistoryLoadResult, HistoryFilterParams>(
        (ref, params) async {
  final assessmentRepo = ref.read(assessmentRepositoryProvider);
  final patientRepo = ref.read(patientRepositoryProvider);

  final results = await Future.wait([
    assessmentRepo.syncFromServer(),
    patientRepo.syncFromServer(),
  ]);

  final repo = ref.watch(historyRepositoryProvider);
  final items = await repo.getHistory(
    search: params.search,
    riskFilter: params.riskFilter,
    typeFilter: params.typeFilter,
    startDate: params.startDate,
    endDate: params.endDate,
  );
  return HistoryLoadResult(
      items: items, synced: results.every((synced) => synced));
});
