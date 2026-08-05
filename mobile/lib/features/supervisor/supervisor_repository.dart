import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class WeekStats {
  final int assessments;
  final int referrals;
  final int deliveries;
  final int newPatients;

  const WeekStats({
    this.assessments = 0,
    this.referrals = 0,
    this.deliveries = 0,
    this.newPatients = 0,
  });

  factory WeekStats.fromJson(Map<String, dynamic> json) => WeekStats(
        assessments: json['assessments'] as int? ?? 0,
        referrals: json['referrals'] as int? ?? 0,
        deliveries: json['deliveries'] as int? ?? 0,
        newPatients: json['new_patients'] as int? ?? 0,
      );
}

class AdminDashboardData {
  final String district;
  final String region;
  final int totalChws;
  final int activeChwsToday;
  final int totalPatients;
  final int totalAssessments;
  final int totalDeliveries;
  final int totalReferrals;
  final double referralCompletionRate;
  final int highRiskActive;
  final int midRiskActive;
  final int lowRiskActive;
  final double pnc1CompletionRate;
  final int phq2PositiveThisMonth;
  final int growthAlertsActive;
  final int pendingEscalations;
  final WeekStats thisWeek;
  final WeekStats lastWeek;

  const AdminDashboardData({
    this.district = '',
    this.region = '',
    this.totalChws = 0,
    this.activeChwsToday = 0,
    this.totalPatients = 0,
    this.totalAssessments = 0,
    this.totalDeliveries = 0,
    this.totalReferrals = 0,
    this.referralCompletionRate = 0,
    this.highRiskActive = 0,
    this.midRiskActive = 0,
    this.lowRiskActive = 0,
    this.pnc1CompletionRate = 0,
    this.phq2PositiveThisMonth = 0,
    this.growthAlertsActive = 0,
    this.pendingEscalations = 0,
    this.thisWeek = const WeekStats(),
    this.lastWeek = const WeekStats(),
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) =>
      AdminDashboardData(
        district: json['district'] as String? ?? '',
        region: json['region'] as String? ?? '',
        totalChws: json['total_chws'] as int? ?? 0,
        activeChwsToday: json['active_chws_today'] as int? ?? 0,
        totalPatients: json['total_patients'] as int? ?? 0,
        totalAssessments: json['total_assessments'] as int? ?? 0,
        totalDeliveries: json['total_deliveries'] as int? ?? 0,
        totalReferrals: json['total_referrals'] as int? ?? 0,
        referralCompletionRate:
            (json['referral_completion_rate'] as num?)?.toDouble() ?? 0,
        highRiskActive: json['high_risk_active'] as int? ?? 0,
        midRiskActive: json['mid_risk_active'] as int? ?? 0,
        lowRiskActive: json['low_risk_active'] as int? ?? 0,
        pnc1CompletionRate:
            (json['pnc1_completion_rate'] as num?)?.toDouble() ?? 0,
        phq2PositiveThisMonth: json['phq2_positive_this_month'] as int? ?? 0,
        growthAlertsActive: json['growth_alerts_active'] as int? ?? 0,
        pendingEscalations: json['pending_escalations'] as int? ?? 0,
        thisWeek: WeekStats.fromJson(
            json['this_week'] as Map<String, dynamic>? ?? const {}),
        lastWeek: WeekStats.fromJson(
            json['last_week'] as Map<String, dynamic>? ?? const {}),
      );
}

class ChwSummary {
  final int id;
  final String fullName;
  final String username;
  final String? facility;
  final String? district;
  final bool isActive;
  final int? daysSinceActive;
  final int patientCount;
  final int assessmentCount;
  final int referralCount;
  final int highRiskCount;
  final double referralCompletionRate;
  final String status;

  const ChwSummary({
    required this.id,
    required this.fullName,
    required this.username,
    this.facility,
    this.district,
    this.isActive = true,
    this.daysSinceActive,
    this.patientCount = 0,
    this.assessmentCount = 0,
    this.referralCount = 0,
    this.highRiskCount = 0,
    this.referralCompletionRate = 0,
    this.status = 'inactive',
  });

  factory ChwSummary.fromJson(Map<String, dynamic> json) => ChwSummary(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        username: json['username'] as String? ?? '',
        facility: json['facility'] as String?,
        district: json['district'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        daysSinceActive: json['days_since_active'] as int?,
        patientCount: json['patient_count'] as int? ?? 0,
        assessmentCount: json['assessment_count'] as int? ?? 0,
        referralCount: json['referral_count'] as int? ?? 0,
        highRiskCount: json['high_risk_count'] as int? ?? 0,
        referralCompletionRate:
            (json['referral_completion_rate'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'inactive',
      );
}

class ChwPatientRow {
  final int id;
  final String fullName;
  final String? riskLevel;
  final String? lastAssessment;

  const ChwPatientRow({
    required this.id,
    required this.fullName,
    this.riskLevel,
    this.lastAssessment,
  });

  factory ChwPatientRow.fromJson(Map<String, dynamic> json) => ChwPatientRow(
        id: json['id'] as int,
        fullName: json['full_name'] as String? ?? '',
        riskLevel: json['risk_level'] as String?,
        lastAssessment: json['last_assessment'] as String?,
      );
}

class ChwActivityWeek {
  final String week;
  final int assessments;
  final int referrals;

  const ChwActivityWeek({
    required this.week,
    this.assessments = 0,
    this.referrals = 0,
  });

  factory ChwActivityWeek.fromJson(Map<String, dynamic> json) =>
      ChwActivityWeek(
        week: json['week'] as String? ?? '',
        assessments: json['assessments'] as int? ?? 0,
        referrals: json['referrals'] as int? ?? 0,
      );
}

class ChwDetailStats {
  final int chwId;
  final String fullName;
  final String username;
  final String? facility;
  final int patientCount;
  final int assessmentCount;
  final int referralCount;
  final double referralCompletionRate;
  final Map<String, int> riskDistribution;
  final Map<String, double> ancCompletion;
  final Map<String, double> pncCompletion;
  final List<ChwActivityWeek> weeklyActivity;
  final List<ChwPatientRow> patients;

  const ChwDetailStats({
    required this.chwId,
    required this.fullName,
    this.username = '',
    this.facility,
    this.patientCount = 0,
    this.assessmentCount = 0,
    this.referralCount = 0,
    this.referralCompletionRate = 0,
    this.riskDistribution = const {},
    this.ancCompletion = const {},
    this.pncCompletion = const {},
    this.weeklyActivity = const [],
    this.patients = const [],
  });

  factory ChwDetailStats.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(String key) {
      final raw = json[key];
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v as int? ?? 0));
      }
      return const {};
    }

    Map<String, double> doubleMap(String key) {
      final raw = json[key];
      if (raw is Map) {
        return raw.map(
            (k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0));
      }
      return const {};
    }

    return ChwDetailStats(
      chwId: json['chw_id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      facility: json['facility'] as String?,
      patientCount: json['patient_count'] as int? ?? 0,
      assessmentCount: json['assessment_count'] as int? ?? 0,
      referralCount: json['referral_count'] as int? ?? 0,
      referralCompletionRate:
          (json['referral_completion_rate'] as num?)?.toDouble() ?? 0,
      riskDistribution: intMap('risk_distribution'),
      ancCompletion: doubleMap('anc_completion'),
      pncCompletion: doubleMap('pnc_completion'),
      weeklyActivity: (json['weekly_activity'] as List<dynamic>? ?? [])
          .map((e) => ChwActivityWeek.fromJson(e as Map<String, dynamic>))
          .toList(),
      patients: (json['patients'] as List<dynamic>? ?? [])
          .map((e) => ChwPatientRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HighRiskPatient {
  final int patientId;
  final String fullName;
  final int? age;
  final String? facility;
  final String? chwName;
  final int? chwId;
  final String riskLevel;
  final double confidence;
  final String? lastAssessmentDate;
  final int daysSinceAssessment;
  final bool flagged;
  final double? systolicBp;
  final double? bloodSugar;
  final bool referralMade;

  const HighRiskPatient({
    required this.patientId,
    required this.fullName,
    this.age,
    this.facility,
    this.chwName,
    this.chwId,
    this.riskLevel = 'high risk',
    this.confidence = 0,
    this.lastAssessmentDate,
    this.daysSinceAssessment = 0,
    this.flagged = false,
    this.systolicBp,
    this.bloodSugar,
    this.referralMade = false,
  });

  factory HighRiskPatient.fromJson(Map<String, dynamic> json) =>
      HighRiskPatient(
        patientId: json['patient_id'] as int? ?? 0,
        fullName: json['full_name'] as String? ?? 'Unknown',
        age: json['age'] as int?,
        facility: json['facility'] as String?,
        chwName: json['chw_name'] as String?,
        chwId: json['chw_id'] as int?,
        riskLevel: json['risk_level'] as String? ?? 'high risk',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        lastAssessmentDate: json['last_assessment_date'] as String?,
        daysSinceAssessment: json['days_since_assessment'] as int? ?? 0,
        flagged: json['flagged'] as bool? ?? false,
        systolicBp: (json['systolic_bp'] as num?)?.toDouble(),
        bloodSugar: (json['blood_sugar'] as num?)?.toDouble(),
        referralMade: json['referral_made'] as bool? ?? false,
      );
}

class ReferralFacilityStats {
  final String facilityName;
  final int total;
  final int arrived;
  final double completionRate;

  const ReferralFacilityStats({
    required this.facilityName,
    this.total = 0,
    this.arrived = 0,
    this.completionRate = 0,
  });

  factory ReferralFacilityStats.fromJson(Map<String, dynamic> json) =>
      ReferralFacilityStats(
        facilityName: json['facility_name'] as String? ?? 'Unknown',
        total: json['total'] as int? ?? 0,
        arrived: json['arrived'] as int? ?? 0,
        completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      );
}

class ReferralChwStats {
  final String chwName;
  final int total;
  final int arrived;
  final double completionRate;

  const ReferralChwStats({
    required this.chwName,
    this.total = 0,
    this.arrived = 0,
    this.completionRate = 0,
  });

  factory ReferralChwStats.fromJson(Map<String, dynamic> json) =>
      ReferralChwStats(
        chwName: json['chw_name'] as String? ?? 'Unknown',
        total: json['total'] as int? ?? 0,
        arrived: json['arrived'] as int? ?? 0,
        completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      );
}

class ReferralAnalytics {
  final int totalReferrals;
  final int sent;
  final int received;
  final int patientArrived;
  final double completionRate;
  final double? avgHoursToReceipt;
  final double? avgHoursToArrival;
  final int highRiskReferrals;
  final List<ReferralFacilityStats> byFacility;
  final List<ReferralChwStats> byChw;

  const ReferralAnalytics({
    this.totalReferrals = 0,
    this.sent = 0,
    this.received = 0,
    this.patientArrived = 0,
    this.completionRate = 0,
    this.avgHoursToReceipt,
    this.avgHoursToArrival,
    this.highRiskReferrals = 0,
    this.byFacility = const [],
    this.byChw = const [],
  });

  factory ReferralAnalytics.fromJson(Map<String, dynamic> json) =>
      ReferralAnalytics(
        totalReferrals: json['total_referrals'] as int? ?? 0,
        sent: json['sent'] as int? ?? 0,
        received: json['received'] as int? ?? 0,
        patientArrived: json['patient_arrived'] as int? ?? 0,
        completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
        avgHoursToReceipt: (json['avg_hours_to_receipt'] as num?)?.toDouble(),
        avgHoursToArrival: (json['avg_hours_to_arrival'] as num?)?.toDouble(),
        highRiskReferrals: json['high_risk_referrals'] as int? ?? 0,
        byFacility: (json['by_facility'] as List<dynamic>? ?? [])
            .map((e) =>
                ReferralFacilityStats.fromJson(e as Map<String, dynamic>))
            .toList(),
        byChw: (json['by_chw'] as List<dynamic>? ?? [])
            .map((e) => ReferralChwStats.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MonthlyReport {
  final String district;
  final String region;
  final int year;
  final int month;
  final String reportingPeriod;
  final int totalChws;
  final int activeChws;
  final int totalPatientsRegistered;
  final int newPatientsThisMonth;
  final int totalAssessments;
  final int highRiskDetected;
  final int midRiskDetected;
  final int lowRiskDetected;
  final int totalReferrals;
  final double referralCompletionRate;
  final int totalDeliveries;
  final int liveBirths;
  final int stillbirths;
  final double pnc1CompletionRate;
  final double pnc2CompletionRate;
  final double pnc3CompletionRate;
  final int phq2ScreensPerformed;
  final int phq2PositiveCount;
  final int growthAlertsGenerated;
  final double exclusiveBreastfeedingRate;

  const MonthlyReport({
    this.district = '',
    this.region = '',
    this.year = 0,
    this.month = 0,
    this.reportingPeriod = '',
    this.totalChws = 0,
    this.activeChws = 0,
    this.totalPatientsRegistered = 0,
    this.newPatientsThisMonth = 0,
    this.totalAssessments = 0,
    this.highRiskDetected = 0,
    this.midRiskDetected = 0,
    this.lowRiskDetected = 0,
    this.totalReferrals = 0,
    this.referralCompletionRate = 0,
    this.totalDeliveries = 0,
    this.liveBirths = 0,
    this.stillbirths = 0,
    this.pnc1CompletionRate = 0,
    this.pnc2CompletionRate = 0,
    this.pnc3CompletionRate = 0,
    this.phq2ScreensPerformed = 0,
    this.phq2PositiveCount = 0,
    this.growthAlertsGenerated = 0,
    this.exclusiveBreastfeedingRate = 0,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) => MonthlyReport(
        district: json['district'] as String? ?? '',
        region: json['region'] as String? ?? '',
        year: json['year'] as int? ?? 0,
        month: json['month'] as int? ?? 0,
        reportingPeriod: json['reporting_period'] as String? ?? '',
        totalChws: json['total_chws'] as int? ?? 0,
        activeChws: json['active_chws'] as int? ?? 0,
        totalPatientsRegistered: json['total_patients_registered'] as int? ?? 0,
        newPatientsThisMonth: json['new_patients_this_month'] as int? ?? 0,
        totalAssessments: json['total_assessments'] as int? ?? 0,
        highRiskDetected: json['high_risk_detected'] as int? ?? 0,
        midRiskDetected: json['mid_risk_detected'] as int? ?? 0,
        lowRiskDetected: json['low_risk_detected'] as int? ?? 0,
        totalReferrals: json['total_referrals'] as int? ?? 0,
        referralCompletionRate:
            (json['referral_completion_rate'] as num?)?.toDouble() ?? 0,
        totalDeliveries: json['total_deliveries'] as int? ?? 0,
        liveBirths: json['live_births'] as int? ?? 0,
        stillbirths: json['stillbirths'] as int? ?? 0,
        pnc1CompletionRate:
            (json['pnc1_completion_rate'] as num?)?.toDouble() ?? 0,
        pnc2CompletionRate:
            (json['pnc2_completion_rate'] as num?)?.toDouble() ?? 0,
        pnc3CompletionRate:
            (json['pnc3_completion_rate'] as num?)?.toDouble() ?? 0,
        phq2ScreensPerformed: json['phq2_screens_performed'] as int? ?? 0,
        phq2PositiveCount: json['phq2_positive_count'] as int? ?? 0,
        growthAlertsGenerated: json['growth_alerts_generated'] as int? ?? 0,
        exclusiveBreastfeedingRate:
            (json['exclusive_breastfeeding_rate'] as num?)?.toDouble() ?? 0,
      );
}

class InviteCode {
  final int id;
  final String code;
  final String status;
  final String? note;
  final String? district;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? usedByUsername;

  const InviteCode({
    required this.id,
    required this.code,
    required this.status,
    this.note,
    this.district,
    required this.createdAt,
    this.expiresAt,
    this.usedByUsername,
  });

  factory InviteCode.fromJson(Map<String, dynamic> json) => InviteCode(
        id: json['id'] as int,
        code: json['code'] as String,
        status: json['status'] as String? ?? 'pending',
        note: json['note'] as String?,
        district: json['district'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        usedByUsername: json['used_by_username'] as String?,
      );
}

class SupervisorRepository {
  final Dio _dio;

  SupervisorRepository(this._dio);

  Future<AdminDashboardData> getDashboard() async {
    final response = await _dio.get('/api/v1/admin/dashboard');
    return AdminDashboardData.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<ChwSummary>> listChws() async {
    final response = await _dio.get('/api/v1/admin/chws');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ChwSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChwDetailStats> getChwStats(int chwId) async {
    final response = await _dio.get('/api/v1/admin/chws/$chwId/stats');
    return ChwDetailStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> createChw(
    String username,
    String password,
    String fullName,
    String facility, {
    String? district,
  }) async {
    final response = await _dio.post('/api/v1/admin/users', data: {
      'username': username,
      'password': password,
      'full_name': fullName,
      'facility': facility,
      if (district != null && district.isNotEmpty) 'district': district,
    });
    final body = response.data as Map<String, dynamic>;
    return body['user_id'] as int? ?? 0;
  }

  Future<void> deactivateUser(int userId) async {
    await _dio.patch('/api/v1/admin/users/$userId/deactivate');
  }

  Future<void> activateUser(int userId) async {
    await _dio.patch('/api/v1/admin/users/$userId/activate');
  }

  Future<List<HighRiskPatient>> getHighRiskPatients(
      {int daysSince = 7}) async {
    final response = await _dio.get(
      '/api/v1/admin/high-risk-patients',
      queryParameters: {'days_since_assessment': daysSince},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => HighRiskPatient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReferralAnalytics> getReferralAnalytics() async {
    final response = await _dio.get('/api/v1/admin/referral-analytics');
    return ReferralAnalytics.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MonthlyReport> getMonthlyReport(int year, int month) async {
    final response = await _dio.get(
      '/api/v1/admin/report/monthly',
      queryParameters: {'year': year, 'month': month},
    );
    return MonthlyReport.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<InviteCode>> listInviteCodes() async {
    final response = await _dio.get('/api/v1/admin/invite-codes');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => InviteCode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InviteCode> createInviteCode({String? note, int expiresInDays = 14}) async {
    final response = await _dio.post('/api/v1/admin/invite-codes', data: {
      'note': note,
      'expires_in_days': expiresInDays,
    });
    return InviteCode.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> revokeInviteCode(int codeId) async {
    await _dio.post('/api/v1/admin/invite-codes/$codeId/revoke');
  }
}

final supervisorRepositoryProvider = Provider<SupervisorRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SupervisorRepository(dio);
});

final supervisorDashboardProvider =
    FutureProvider<AdminDashboardData>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getDashboard();
});

final chwsProvider = FutureProvider<List<ChwSummary>>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.listChws();
});

final chwStatsProvider =
    FutureProvider.family<ChwDetailStats, int>((ref, chwId) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getChwStats(chwId);
});

final highRiskPatientsProvider =
    FutureProvider<List<HighRiskPatient>>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getHighRiskPatients();
});

final referralAnalyticsProvider =
    FutureProvider<ReferralAnalytics>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getReferralAnalytics();
});

final monthlyReportProvider =
    FutureProvider.family<MonthlyReport, ({int year, int month})>(
        (ref, args) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getMonthlyReport(args.year, args.month);
});

class CreateChwNotifier extends StateNotifier<AsyncValue<int?>> {
  final SupervisorRepository _repo;
  CreateChwNotifier(this._repo) : super(const AsyncData(null));

  Future<int?> create(
      String username, String password, String fullName, String facility, {String? district}) async {
    state = const AsyncLoading();
    try {
      final id = await _repo.createChw(username, password, fullName, facility, district: district);
      state = AsyncData(id);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createChwProvider =
    StateNotifierProvider<CreateChwNotifier, AsyncValue<int?>>((ref) {
  return CreateChwNotifier(ref.read(supervisorRepositoryProvider));
});

final inviteCodesProvider = FutureProvider<List<InviteCode>>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.listInviteCodes();
});

class InviteCodeActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final SupervisorRepository _repo;
  InviteCodeActionsNotifier(this._repo) : super(const AsyncData(null));

  Future<void> create({String? note, int expiresInDays = 14}) async {
    state = const AsyncLoading();
    try {
      await _repo.createInviteCode(note: note, expiresInDays: expiresInDays);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> revoke(int codeId) async {
    state = const AsyncLoading();
    try {
      await _repo.revokeInviteCode(codeId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final inviteCodeActionsProvider =
    StateNotifierProvider<InviteCodeActionsNotifier, AsyncValue<void>>((ref) {
  return InviteCodeActionsNotifier(ref.read(supervisorRepositoryProvider));
});


