import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/storage/database_provider.dart';

class DashboardSummaryData {
  final int totalAssessments;
  final int highRiskCount;
  final int midRiskCount;
  final int lowRiskCount;
  final double highRiskPct;
  final double midRiskPct;
  final double lowRiskPct;
  final int totalPatients;
  final int activePregnancies;
  final int pendingReferrals;
  final int upcomingVisits;
  final int recentEscalations;

  const DashboardSummaryData({
    required this.totalAssessments,
    required this.highRiskCount,
    required this.midRiskCount,
    required this.lowRiskCount,
    required this.highRiskPct,
    required this.midRiskPct,
    required this.lowRiskPct,
    required this.totalPatients,
    required this.activePregnancies,
    required this.pendingReferrals,
    required this.upcomingVisits,
    required this.recentEscalations,
  });

  factory DashboardSummaryData.fromJson(Map<String, dynamic> json) =>
      DashboardSummaryData(
        totalAssessments: json['total_assessments'] as int? ?? 0,
        highRiskCount: json['high_risk_count'] as int? ?? 0,
        midRiskCount: json['mid_risk_count'] as int? ?? 0,
        lowRiskCount: json['low_risk_count'] as int? ?? 0,
        highRiskPct: (json['high_risk_pct'] as num?)?.toDouble() ?? 0,
        midRiskPct: (json['mid_risk_pct'] as num?)?.toDouble() ?? 0,
        lowRiskPct: (json['low_risk_pct'] as num?)?.toDouble() ?? 0,
        totalPatients: json['total_patients'] as int? ?? 0,
        activePregnancies: json['active_pregnancies'] as int? ?? 0,
        pendingReferrals: json['pending_referrals'] as int? ?? 0,
        upcomingVisits: json['upcoming_visits'] as int? ?? 0,
        recentEscalations: json['recent_escalations'] as int? ?? 0,
      );
}

class DashboardSummaryRepository {
  final Dio dio;

  DashboardSummaryRepository(this.dio);

  Future<DashboardSummaryData> getSummary() async {
    final response = await dio.get('/api/v1/dashboard/summary');
    return DashboardSummaryData.fromJson(response.data as Map<String, dynamic>);
  }

  static DashboardSummaryData buildLocalSummary({
    required int assessments,
    required int highRisk,
    required int midRisk,
    required int lowRisk,
    required int patients,
    required int activePregnancies,
    required int pendingReferrals,
    required int upcomingVisits,
    required int recentEscalations,
  }) {
    final total = assessments;
    double pct(int count) => total == 0 ? 0 : (count / total * 100);
    return DashboardSummaryData(
      totalAssessments: total,
      highRiskCount: highRisk,
      midRiskCount: midRisk,
      lowRiskCount: lowRisk,
      highRiskPct: double.parse(pct(highRisk).toStringAsFixed(1)),
      midRiskPct: double.parse(pct(midRisk).toStringAsFixed(1)),
      lowRiskPct: double.parse(pct(lowRisk).toStringAsFixed(1)),
      totalPatients: patients,
      activePregnancies: activePregnancies,
      pendingReferrals: pendingReferrals,
      upcomingVisits: upcomingVisits,
      recentEscalations: recentEscalations,
    );
  }
}

final dashboardSummaryRepositoryProvider =
    Provider<DashboardSummaryRepository>((ref) {
  return DashboardSummaryRepository(ref.watch(dioProvider));
});

class EscalationFeedItem {
  final int? patientId;
  final String? patientName;
  final String? from;
  final String? to;
  final String? escalationType;
  final String? date;
  final bool whatsappSent;

  const EscalationFeedItem({
    this.patientId,
    this.patientName,
    this.from,
    this.to,
    this.escalationType,
    this.date,
    this.whatsappSent = false,
  });

  factory EscalationFeedItem.fromJson(Map<String, dynamic> json) =>
      EscalationFeedItem(
        patientId: json['patient_id'] as int?,
        patientName: json['patient_name'] as String?,
        from: json['from'] as String?,
        to: json['to'] as String?,
        escalationType: json['escalation_type'] as String?,
        date: json['date'] as String?,
        whatsappSent: json['whatsapp_sent'] as bool? ?? false,
      );

  factory EscalationFeedItem.fromLocalMessage({
    String? patientRef,
    String? riskLevel,
    String? message,
    DateTime? createdAt,
  }) =>
      EscalationFeedItem(
        patientName: patientRef,
        to: riskLevel,
        escalationType: message,
        date: createdAt?.toIso8601String().split('T').first,
        whatsappSent: false,
      );
}

Future<List<EscalationFeedItem>> _fetchRecentEscalations(
    DashboardSummaryRepository repo) async {
  final response =
      await repo.dio.get('/api/v1/risk-escalations/recent?days=7&limit=10');
  final list = response.data as List<dynamic>;
  return list
      .map((e) => EscalationFeedItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

final recentEscalationsProvider =
    FutureProvider<List<EscalationFeedItem>>((ref) async {
  final repo = ref.watch(dashboardSummaryRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  if (connectivity.currentValue) {
    try {
      return await _fetchRecentEscalations(repo);
    } on DioException {
      // fall through to local
    }
  }

  final db = ref.read(appDatabaseProvider);
  final query = db.select(db.riskEscalations)
    ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ..limit(10);
  final rows = await query.get();
  return rows
      .map((r) => EscalationFeedItem.fromLocalMessage(
            patientRef: r.patientRef,
            riskLevel: r.riskLevel,
            message: r.message,
            createdAt: r.createdAt,
          ))
      .toList();
});

final homeDashboardProvider =
    FutureProvider<DashboardSummaryData>((ref) async {
  final repo = ref.watch(dashboardSummaryRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  if (connectivity.currentValue) {
    try {
      return await repo.getSummary();
    } on DioException {
      // fall through to local
    }
  }

  final db = ref.read(appDatabaseProvider);

  final assessments = await db.select(db.assessments).get();
  final high = assessments
      .where((a) => a.riskLevel == 'high')
      .length;
  final mid = assessments.where((a) => a.riskLevel == 'mid').length;
  final low = assessments.where((a) => a.riskLevel == 'low').length;

  final patients = await db.select(db.patients).get();
  final pregnancies = await db.select(db.pregnancies).get();
  final referrals = await db.select(db.referrals).get();
  final visits = await db.select(db.scheduledVisits).get();
  final escalations = await db.select(db.riskEscalations).get();

  final upcoming = visits
      .where((v) => v.status == 'pending')
      .length;

  return DashboardSummaryRepository.buildLocalSummary(
    assessments: assessments.length,
    highRisk: high,
    midRisk: mid,
    lowRisk: low,
    patients: patients.length,
    activePregnancies: pregnancies.where((p) => p.status == 'active').length,
    pendingReferrals:
        referrals.where((r) => r.status == 'pending').length,
    upcomingVisits: upcoming,
    recentEscalations: escalations.length,
  );
});
