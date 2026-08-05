import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mamasafe/features/supervisor/supervisor_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late SupervisorRepository repo;

  setUp(() {
    dio = MockDio();
    repo = SupervisorRepository(dio);
  });

  group('SupervisorRepository.getDashboard', () {
    test('fetches and parses admin dashboard', () async {
      when(() => dio.get('/api/v1/admin/dashboard')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/admin/dashboard'),
          statusCode: 200,
          data: const {
            'total_chws': 10,
            'active_chws_today': 4,
            'total_patients': 120,
            'total_assessments': 300,
            'total_deliveries': 25,
            'total_referrals': 40,
            'referral_completion_rate': 55.5,
            'high_risk_active': 8,
            'mid_risk_active': 15,
            'low_risk_active': 97,
            'pnc1_completion_rate': 80.0,
            'phq2_positive_this_month': 3,
            'growth_alerts_active': 6,
            'pending_escalations': 2,
            'this_week': {'assessments': 10, 'referrals': 3, 'deliveries': 1, 'new_patients': 4},
            'last_week': {'assessments': 8, 'referrals': 1, 'deliveries': 2, 'new_patients': 2},
          },
        ),
      );

      final data = await repo.getDashboard();
      expect(data.totalChws, 10);
      expect(data.highRiskActive, 8);
      expect(data.thisWeek.deliveries, 1);
      verify(() => dio.get('/api/v1/admin/dashboard')).called(1);
    });
  });

  group('ChwSummary.fromJson', () {
    test('parses web shape', () {
      final c = ChwSummary.fromJson(const {
        'id': 1,
        'full_name': 'Moussa Fall',
        'username': 'moussa',
        'facility': 'Centre A',
        'district': 'Dakar',
        'is_active': true,
        'days_since_active': 1,
        'patient_count': 20,
        'assessment_count': 45,
        'referral_count': 6,
        'high_risk_count': 2,
        'referral_completion_rate': 66.7,
        'status': 'active',
      });
      expect(c.id, 1);
      expect(c.fullName, 'Moussa Fall');
      expect(c.isActive, isTrue);
      expect(c.status, 'active');
      expect(c.highRiskCount, 2);
      expect(c.referralCompletionRate, 66.7);
    });
  });

  group('SupervisorRepository.listChws', () {
    test('fetches CHW list', () async {
      when(() => dio.get('/api/v1/admin/chws')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/admin/chws'),
          statusCode: 200,
          data: const [
            {
              'id': 1, 'full_name': 'Moussa Fall', 'username': 'moussa',
              'facility': 'Centre A', 'district': 'Dakar',
              'is_active': true, 'days_since_active': 1,
              'patient_count': 20, 'assessment_count': 45,
              'referral_count': 6, 'high_risk_count': 2,
              'referral_completion_rate': 66.7, 'status': 'active',
            },
          ],
        ),
      );

      final chws = await repo.listChws();
      expect(chws, hasLength(1));
      expect(chws.first.fullName, 'Moussa Fall');
    });
  });

  group('ChwDetailStats.fromJson', () {
    test('parses nested maps', () {
      final s = ChwDetailStats.fromJson(const {
        'chw_id': 1,
        'full_name': 'Moussa Fall',
        'username': 'moussa',
        'facility': 'Centre A',
        'patient_count': 20,
        'assessment_count': 45,
        'referral_count': 6,
        'referral_completion_rate': 66.7,
        'risk_distribution': {'low': 10, 'mid': 8, 'high': 2},
        'anc_completion': {'visit_1': 80.0, 'visit_2': 50.0},
        'pnc_completion': {'pnc_1': 100.0},
        'weekly_activity': [
          {'week': '2026-07-25', 'assessments': 3, 'referrals': 1},
        ],
        'patients': [
          {'id': 2, 'full_name': 'Amina', 'risk_level': 'high risk', 'last_assessment': '2026-07-30'},
        ],
      });
      expect(s.riskDistribution['high'], 2);
      expect(s.ancCompletion['visit_2'], 50.0);
      expect(s.pncCompletion['pnc_1'], 100.0);
      expect(s.weeklyActivity, hasLength(1));
      expect(s.patients, hasLength(1));
      expect(s.patients.first.fullName, 'Amina');
    });
  });

  group('SupervisorRepository.getChwStats', () {
    test('fetches by id', () async {
      when(() => dio.get('/api/v1/admin/chws/1/stats')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/admin/chws/1/stats'),
          statusCode: 200,
          data: const {
            'chw_id': 1, 'full_name': 'Moussa Fall', 'username': 'moussa',
            'facility': 'Centre A',
            'patient_count': 20, 'assessment_count': 45, 'referral_count': 6,
            'referral_completion_rate': 66.7,
            'risk_distribution': {'low': 10, 'mid': 8, 'high': 2},
            'anc_completion': {}, 'pnc_completion': {},
            'weekly_activity': [], 'patients': [],
          },
        ),
      );

      final stats = await repo.getChwStats(1);
      expect(stats.fullName, 'Moussa Fall');
      verify(() => dio.get('/api/v1/admin/chws/1/stats')).called(1);
    });
  });

  group('SupervisorRepository.createChw', () {
    test('posts payload', () async {
      when(() => dio.post(
        '/api/v1/admin/users',
        data: any(named: 'data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/admin/users'),
        statusCode: 201,
        data: const {'message': 'CHW account created', 'user_id': 9, 'username': 'newchw', 'temporary_password': 'pw'},
      ));

      final userId = await repo.createChw('newchw', 'pw', 'New Chw', 'Centre B');
      expect(userId, 9);
      verify(() => dio.post(
        '/api/v1/admin/users',
        data: {'username': 'newchw', 'password': 'pw', 'full_name': 'New Chw', 'facility': 'Centre B'},
      )).called(1);
    });
  });

  group('SupervisorRepository.deactivateUser / activateUser', () {
    test('deactivate', () async {
      when(() => dio.patch('/api/v1/admin/users/9/deactivate')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/admin/users/9/deactivate'),
          statusCode: 200,
          data: const {'message': 'User newchw deactivated'},
        ),
      );
      await repo.deactivateUser(9);
      verify(() => dio.patch('/api/v1/admin/users/9/deactivate')).called(1);
    });

    test('activate', () async {
      when(() => dio.patch('/api/v1/admin/users/9/activate')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/admin/users/9/activate'),
          statusCode: 200,
          data: const {'message': 'User newchw activated'},
        ),
      );
      await repo.activateUser(9);
      verify(() => dio.patch('/api/v1/admin/users/9/activate')).called(1);
    });
  });

  group('HighRiskPatient.fromJson', () {
    test('parses web shape', () {
      final p = HighRiskPatient.fromJson(const {
        'patient_id': 3,
        'full_name': 'Fatou Ndiaye',
        'age': 28,
        'facility': 'Centre A',
        'chw_name': 'Moussa Fall',
        'chw_id': 1,
        'risk_level': 'high risk',
        'confidence': 0.95,
        'last_assessment_date': '2026-07-25',
        'days_since_assessment': 7,
        'flagged': true,
        'systolic_bp': 180.0,
        'blood_sugar': 12.0,
        'referral_made': false,
      });
      expect(p.patientId, 3);
      expect(p.fullName, 'Fatou Ndiaye');
      expect(p.confidence, 0.95);
      expect(p.flagged, isTrue);
      expect(p.referralMade, isFalse);
    });
  });

  group('SupervisorRepository.getHighRiskPatients', () {
    test('uses days_since_assessment param', () async {
      when(() => dio.get(
        '/api/v1/admin/high-risk-patients',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/admin/high-risk-patients'),
        statusCode: 200,
        data: const [],
      ));

      final list = await repo.getHighRiskPatients(daysSince: 7);
      expect(list, isEmpty);
      verify(() => dio.get(
        '/api/v1/admin/high-risk-patients',
        queryParameters: {'days_since_assessment': 7},
      )).called(1);
    });
  });

  group('ReferralAnalytics.fromJson', () {
    test('parses nested breakdowns', () {
      final a = ReferralAnalytics.fromJson(const {
        'total_referrals': 10,
        'sent': 3,
        'received': 2,
        'patient_arrived': 5,
        'completion_rate': 50.0,
        'avg_hours_to_receipt': 2.5,
        'avg_hours_to_arrival': null,
        'high_risk_referrals': 4,
        'by_facility': [
          {'facility_name': 'Hopital A', 'total': 6, 'arrived': 3, 'completion_rate': 50.0},
        ],
        'by_chw': [
          {'chw_name': 'Moussa Fall', 'total': 10, 'arrived': 5, 'completion_rate': 50.0},
        ],
      });
      expect(a.totalReferrals, 10);
      expect(a.completionRate, 50.0);
      expect(a.avgHoursToReceipt, 2.5);
      expect(a.avgHoursToArrival, isNull);
      expect(a.byFacility, hasLength(1));
      expect(a.byFacility.first.facilityName, 'Hopital A');
      expect(a.byChw.first.chwName, 'Moussa Fall');
    });
  });

  group('SupervisorRepository.getReferralAnalytics', () {
    test('fetches analytics', () async {
      when(() => dio.get('/api/v1/admin/referral-analytics')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/admin/referral-analytics'),
          statusCode: 200,
          data: const {
            'total_referrals': 10, 'sent': 3, 'received': 2,
            'patient_arrived': 5, 'completion_rate': 50.0,
            'avg_hours_to_receipt': 2.5, 'avg_hours_to_arrival': null,
            'high_risk_referrals': 4, 'by_facility': [], 'by_chw': [],
          },
        ),
      );

      final a = await repo.getReferralAnalytics();
      expect(a.totalReferrals, 10);
      verify(() => dio.get('/api/v1/admin/referral-analytics')).called(1);
    });
  });

  group('MonthlyReport.fromJson', () {
    test('parses full payload', () {
      final r = MonthlyReport.fromJson(const {
        'district': 'Dakar', 'region': 'Dakar',
        'year': 2026, 'month': 8,
        'reporting_period': 'August 2026',
        'total_chws': 10, 'active_chws': 4,
        'total_patients_registered': 120, 'new_patients_this_month': 5,
        'total_assessments': 40, 'high_risk_detected': 6,
        'mid_risk_detected': 10, 'low_risk_detected': 24,
        'total_referrals': 8, 'referral_completion_rate': 62.5,
        'total_deliveries': 3, 'live_births': 3, 'stillbirths': 0,
        'pnc1_completion_rate': 100.0, 'pnc2_completion_rate': 66.7,
        'pnc3_completion_rate': 33.3,
        'phq2_screens_performed': 4, 'phq2_positive_count': 1,
        'growth_alerts_generated': 2,
        'exclusive_breastfeeding_rate': 80.0,
        'generated_at': '2026-08-01T00:00:00',
      });
      expect(r.reportingPeriod, 'August 2026');
      expect(r.newPatientsThisMonth, 5);
      expect(r.liveBirths, 3);
      expect(r.pnc1CompletionRate, 100.0);
    });
  });

  group('SupervisorRepository.getMonthlyReport', () {
    test('sends year and month params', () async {
      when(() => dio.get(
        '/api/v1/admin/report/monthly',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/admin/report/monthly'),
        statusCode: 200,
        data: const {'reporting_period': 'August 2026'},
      ));

      final report = await repo.getMonthlyReport(2026, 8);
      expect(report.reportingPeriod, 'August 2026');
      verify(() => dio.get(
        '/api/v1/admin/report/monthly',
        queryParameters: {'year': 2026, 'month': 8},
      )).called(1);
    });
  });

  group('WeekStats.fromJson', () {
    test('parses and defaults', () {
      final w = WeekStats.fromJson(const {'assessments': 5, 'referrals': 2});
      expect(w.assessments, 5);
      expect(w.referrals, 2);
      expect(w.deliveries, 0);
      expect(w.newPatients, 0);
    });
  });

  group('AdminDashboardData.fromJson', () {
    test('parses full payload', () {
      final d = AdminDashboardData.fromJson(const {
        'district': 'Dakar', 'region': 'Dakar',
        'total_chws': 10, 'active_chws_today': 4,
        'total_patients': 120, 'total_assessments': 300,
        'total_deliveries': 25, 'total_referrals': 40,
        'referral_completion_rate': 55.5,
        'high_risk_active': 8, 'mid_risk_active': 15, 'low_risk_active': 97,
        'pnc1_completion_rate': 80.0, 'phq2_positive_this_month': 3,
        'growth_alerts_active': 6, 'pending_escalations': 2,
        'this_week': {'assessments': 10, 'referrals': 3, 'deliveries': 1, 'new_patients': 4},
        'last_week': {'assessments': 8, 'referrals': 1, 'deliveries': 2, 'new_patients': 2},
      });
      expect(d.totalChws, 10);
      expect(d.activeChwsToday, 4);
      expect(d.totalPatients, 120);
      expect(d.totalAssessments, 300);
      expect(d.referralCompletionRate, 55.5);
      expect(d.highRiskActive, 8);
      expect(d.pnc1CompletionRate, 80.0);
      expect(d.phq2PositiveThisMonth, 3);
      expect(d.growthAlertsActive, 6);
      expect(d.pendingEscalations, 2);
      expect(d.thisWeek.assessments, 10);
      expect(d.lastWeek.newPatients, 2);
    });

    test('defaults missing numeric fields to zero', () {
      final d = AdminDashboardData.fromJson(const {});
      expect(d.totalChws, 0);
      expect(d.referralCompletionRate, 0.0);
      expect(d.thisWeek.assessments, 0);
      expect(d.lastWeek.assessments, 0);
    });
  });
}
