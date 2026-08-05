import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/features/dashboard/dashboard_repository.dart';

void main() {
  group('DashboardSummaryData.fromJson', () {
    test('parses full payload', () {
      final data = DashboardSummaryData.fromJson(const {
        'total_assessments': 42,
        'high_risk_count': 5,
        'mid_risk_count': 12,
        'low_risk_count': 25,
        'high_risk_pct': 11.9,
        'mid_risk_pct': 28.6,
        'low_risk_pct': 59.5,
        'total_patients': 30,
        'active_pregnancies': 8,
        'pending_referrals': 3,
        'upcoming_visits': 6,
        'recent_escalations': 2,
      });

      expect(data.totalAssessments, 42);
      expect(data.highRiskCount, 5);
      expect(data.midRiskCount, 12);
      expect(data.lowRiskCount, 25);
      expect(data.highRiskPct, 11.9);
      expect(data.totalPatients, 30);
      expect(data.activePregnancies, 8);
      expect(data.pendingReferrals, 3);
      expect(data.upcomingVisits, 6);
      expect(data.recentEscalations, 2);
    });

    test('defaults missing numeric fields to zero', () {
      final data = DashboardSummaryData.fromJson(const {'total_patients': 1});
      expect(data.totalAssessments, 0);
      expect(data.highRiskCount, 0);
      expect(data.midRiskCount, 0);
      expect(data.lowRiskCount, 0);
      expect(data.highRiskPct, 0.0);
    });
  });

  group('buildLocalSummary', () {
    test('aggregates drift rows', () {
      final local = DashboardSummaryRepository.buildLocalSummary(
        assessments: 42,
        highRisk: 5,
        midRisk: 12,
        lowRisk: 25,
        patients: 30,
        activePregnancies: 8,
        pendingReferrals: 3,
        upcomingVisits: 6,
        recentEscalations: 2,
      );

      expect(local.totalAssessments, 42);
      expect(local.highRiskCount, 5);
      expect(local.midRiskCount, 12);
      expect(local.lowRiskCount, 25);
      expect(local.highRiskPct, closeTo(11.9, 0.1));
      expect(local.totalPatients, 30);
    });

    test('avoids division by zero', () {
      final local = DashboardSummaryRepository.buildLocalSummary(
        assessments: 0, highRisk: 0, midRisk: 0, lowRisk: 0,
        patients: 0, activePregnancies: 0, pendingReferrals: 0,
        upcomingVisits: 0, recentEscalations: 0,
      );
      expect(local.highRiskPct, 0.0);
      expect(local.midRiskPct, 0.0);
      expect(local.lowRiskPct, 0.0);
    });
  });

  group('EscalationFeedItem', () {
    test('parses web shape', () {
      final item = EscalationFeedItem.fromJson(const {
        'patient_id': 7,
        'patient_name': 'Amina Diallo',
        'from': 'low risk',
        'to': 'high risk',
        'escalation_type': 'risk_upgrade',
        'date': '2026-08-01',
        'whatsapp_sent': true,
      });
      expect(item.patientId, 7);
      expect(item.patientName, 'Amina Diallo');
      expect(item.from, 'low risk');
      expect(item.to, 'high risk');
      expect(item.whatsappSent, isTrue);
      expect(item.date, '2026-08-01');
    });

    test('fromLocalMessage derives fields from a local message', () {
      final item = EscalationFeedItem.fromLocalMessage(
        patientRef: 'Amina Diallo',
        riskLevel: 'high risk',
        message: 'BP 180/120',
        createdAt: DateTime(2026, 8, 1),
      );
      expect(item.patientName, 'Amina Diallo');
      expect(item.from, isNull);
      expect(item.to, 'high risk');
      expect(item.date, '2026-08-01');
    });
  });
}
