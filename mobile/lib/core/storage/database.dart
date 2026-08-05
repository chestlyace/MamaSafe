import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Assessments extends Table {
  IntColumn get id => integer()();
  TextColumn get patientRef => text().nullable()();
  RealColumn get age => real()();
  RealColumn get systolicBp => real().named('systolic_bp')();
  RealColumn get diastolicBp => real().named('diastolic_bp')();
  RealColumn get bloodSugar => real().named('blood_sugar')();
  RealColumn get bodyTemp => real().named('body_temp')();
  RealColumn get heartRate => real().named('heart_rate')();
  TextColumn get riskLevel => text().named('risk_level')();
  RealColumn get probHigh => real().named('prob_high')();
  RealColumn get probLow => real().named('prob_low')();
  RealColumn get probMid => real().named('prob_mid')();
  TextColumn get recommendation => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class Patients extends Table {
  IntColumn get id => integer()();
  TextColumn get fullName => text().named('full_name')();
  TextColumn get dateOfBirth => text().named('date_of_birth').nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get facility => text().nullable()();
  TextColumn get bloodGroup => text().named('blood_group').nullable()();
  TextColumn get allergies => text().nullable()();
  TextColumn get emergencyContactName => text().named('emergency_contact_name').nullable()();
  TextColumn get emergencyContactPhone => text().named('emergency_contact_phone').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingOps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text().named('operation_type')();
  TextColumn get endpoint => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
}

class Facilities extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get location => text()();
  TextColumn get district => text()();
  TextColumn get contactPhone => text().named('contact_phone').nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class Referrals extends Table {
  IntColumn get id => integer()();
  IntColumn get assessmentId => integer().named('assessment_id')();
  TextColumn get patientRef => text().named('patient_ref').nullable()();
  IntColumn get patientId => integer().named('patient_id').nullable()();
  TextColumn get referredTo => text().named('referred_to')();
  TextColumn get reason => text()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get complicationType => text().named('complication_type').nullable()();
  TextColumn get chwNotes => text().named('chw_notes').nullable()();
  TextColumn get whatsappStatus => text().named('whatsapp_status').nullable()();
  DateTimeColumn get referralDate => dateTime().named('referral_date')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class Pregnancies extends Table {
  IntColumn get id => integer()();
  TextColumn get patientName => text().named('patient_name')();
  TextColumn get patientRef => text().named('patient_ref').nullable()();
  IntColumn get patientId => integer().named('patient_id').nullable()();
  IntColumn get age => integer()();
  IntColumn get gravida => integer().nullable()();
  IntColumn get parity => integer().nullable()();
  TextColumn get lmp => text().nullable()();
  TextColumn get edd => text().nullable()();
  IntColumn get gestationalAgeWeeks => integer().named('gestational_age_weeks').nullable()();
  TextColumn get status => text()();
  TextColumn get riskLevel => text().named('risk_level').nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class AncVisits extends Table {
  IntColumn get id => integer()();
  IntColumn get pregnancyId => integer().named('pregnancy_id')();
  IntColumn get visitNumber => integer().named('visit_number')();
  DateTimeColumn get date => dateTime()();
  IntColumn get gestationalAgeWeeks => integer().named('gestational_age_weeks').nullable()();
  RealColumn get weight => real().nullable()();
  RealColumn get systolicBp => real().named('systolic_bp').nullable()();
  RealColumn get diastolicBp => real().named('diastolic_bp').nullable()();
  RealColumn get fundalHeight => real().named('fundal_height').nullable()();
  RealColumn get fetalHeartRate => real().named('fetal_heart_rate').nullable()();
  TextColumn get presentation => text().nullable()();
  TextColumn get urinalysis => text().nullable()();
  BoolColumn get oedema => boolean().nullable()();
  BoolColumn get ttVaccine => boolean().named('tt_vaccine').nullable()();
  BoolColumn get malariaProphylaxis => boolean().named('malaria_prophylaxis').nullable()();
  BoolColumn get ironSupplements => boolean().named('iron_supplements').nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get nextVisitDate => dateTime().named('next_visit_date').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class Deliveries extends Table {
  IntColumn get id => integer()();
  IntColumn get patientId => integer().named('patient_id')();
  IntColumn get pregnancyId => integer().named('pregnancy_id')();
  DateTimeColumn get date => dateTime()();
  TextColumn get location => text()();
  TextColumn get deliveredBy => text().named('delivered_by')();
  TextColumn get complications => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class Newborns extends Table {
  IntColumn get id => integer()();
  IntColumn get deliveryId => integer().named('delivery_id')();
  TextColumn get name => text()();
  TextColumn get sex => text().nullable()();
  RealColumn get birthWeight => real().named('birth_weight').nullable()();
  IntColumn get apgarScore => integer().named('apgar_score').nullable()();
  BoolColumn get crying => boolean().nullable()();
  BoolColumn get breastfeeding => boolean().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class PostnatalVisits extends Table {
  IntColumn get id => integer()();
  IntColumn get deliveryId => integer().named('delivery_id')();
  IntColumn get newbornId => integer().named('newborn_id').nullable()();
  DateTimeColumn get visitDate => dateTime().named('visit_date')();
  IntColumn get visitNumber => integer().named('visit_number')();
  TextColumn get motherStatus => text().named('mother_status').nullable()();
  RealColumn get newbornWeight => real().named('newborn_weight').nullable()();
  TextColumn get breastfeedingStatus => text().named('breastfeeding_status').nullable()();
  RealColumn get muac => real().nullable()();
  TextColumn get physicalExam => text().named('physical_exam').nullable()();
  TextColumn get labs => text().nullable()();
  TextColumn get mentalHealthNotes => text().named('mental_health_notes').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class GrowthRecords extends Table {
  IntColumn get id => integer()();
  TextColumn get childName => text().named('child_name')();
  TextColumn get childRef => text().named('child_ref').nullable()();
  IntColumn get patientId => integer().named('patient_id').nullable()();
  IntColumn get newbornId => integer().named('newborn_id').nullable()();
  IntColumn get ageMonths => integer().named('age_months')();
  RealColumn get weight => real()();
  RealColumn get height => real().nullable()();
  RealColumn get headCircumference => real().named('head_circumference').nullable()();
  RealColumn get muac => real().nullable()();
  TextColumn get nutritionalStatus => text().named('nutritional_status').nullable()();
  DateTimeColumn get recordedAt => dateTime().named('recorded_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class MentalHealthScreens extends Table {
  IntColumn get id => integer()();
  IntColumn get patientId => integer().named('patient_id')();
  IntColumn get deliveryId => integer().named('delivery_id').nullable()();
  IntColumn get phq2Score1 => integer().named('phq2_score_1')();
  IntColumn get phq2Score2 => integer().named('phq2_score_2')();
  IntColumn get totalScore => integer().named('total_score')();
  TextColumn get riskLevel => text().named('risk_level')();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class ScheduledVisits extends Table {
  IntColumn get id => integer()();
  IntColumn get pregnancyId => integer().named('pregnancy_id')();
  IntColumn get visitNumber => integer().named('visit_number')();
  DateTimeColumn get scheduledDate => dateTime().named('scheduled_date')();
  TextColumn get status => text()();
  IntColumn get completedVisitId => integer().named('completed_visit_id').nullable()();
  TextColumn get rescheduleReason => text().named('reschedule_reason').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class Approvals extends Table {
  IntColumn get id => integer()();
  TextColumn get entityType => text().named('entity_type')();
  IntColumn get entityId => integer().named('entity_id')();
  TextColumn get action => text()();
  TextColumn get status => text()();
  TextColumn get requestedBy => text().named('requested_by')();
  TextColumn get reviewedBy => text().named('reviewed_by').nullable()();
  TextColumn get comments => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get reviewedAt => dateTime().named('reviewed_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class GrowthAlerts extends Table {
  IntColumn get id => integer()();
  IntColumn get newbornId => integer().named('newborn_id')();
  IntColumn get growthRecordId => integer().named('growth_record_id').nullable()();
  TextColumn get alertType => text().named('alert_type')();
  TextColumn get severity => text()();
  TextColumn get message => text()();
  TextColumn get messageFr => text().named('message_fr').nullable()();
  BoolColumn get resolved => boolean()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get resolvedAt => dateTime().named('resolved_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RiskEscalations extends Table {
  IntColumn get id => integer()();
  IntColumn get patientId => integer().named('patient_id').nullable()();
  TextColumn get patientRef => text().named('patient_ref').nullable()();
  IntColumn get assessmentId => integer().named('assessment_id')();
  TextColumn get riskLevel => text().named('risk_level')();
  RealColumn get confidenceScore => real().named('confidence_score').nullable()();
  TextColumn get message => text()();
  BoolColumn get acknowledged => boolean()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get acknowledgedAt => dateTime().named('acknowledged_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PostnatalScheduledVisits extends Table {
  IntColumn get id => integer()();
  IntColumn get deliveryId => integer().named('delivery_id')();
  IntColumn get visitNumber => integer().named('visit_number')();
  DateTimeColumn get scheduledDate => dateTime().named('scheduled_date')();
  TextColumn get status => text()();
  IntColumn get completedVisitId => integer().named('completed_visit_id').nullable()();
  TextColumn get rescheduleReason => text().named('reschedule_reason').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Assessments,
  Patients,
  PendingOps,
  Facilities,
  Referrals,
  Pregnancies,
  AncVisits,
  Deliveries,
  Newborns,
  PostnatalVisits,
  GrowthRecords,
  MentalHealthScreens,
  ScheduledVisits,
  Approvals,
  GrowthAlerts,
  RiskEscalations,
  PostnatalScheduledVisits,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) await migrator.createTable(facilities);
          if (from < 3) await migrator.createTable(pregnancies);
          if (from < 4) await migrator.createTable(growthRecords);
          if (from < 5) await migrator.createTable(approvals);
          if (from < 6) {
            await migrator.createTable(patients);
            await migrator.createTable(ancVisits);
            await migrator.createTable(deliveries);
            await migrator.createTable(newborns);
            await migrator.createTable(postnatalVisits);
            await migrator.createTable(mentalHealthScreens);
            await migrator.createTable(scheduledVisits);
          }
          if (from < 7) {
            await migrator.addColumn(assessments, assessments.recommendation);
          }
          if (from < 8) {
            await migrator.addColumn(referrals, referrals.patientId);
            await migrator.addColumn(referrals, referrals.complicationType);
            await migrator.addColumn(referrals, referrals.chwNotes);
            await migrator.addColumn(referrals, referrals.whatsappStatus);
          }
          if (from < 9) {
            await migrator.addColumn(pregnancies, pregnancies.patientId);
            await migrator.addColumn(growthRecords, growthRecords.patientId);
            await migrator.addColumn(growthRecords, growthRecords.newbornId);
          }
          if (from < 10) {
            await migrator.createTable(growthAlerts);
            await migrator.createTable(riskEscalations);
          }
          if (from < 11) {
            await migrator.createTable(postnatalScheduledVisits);
          }
          if (from < 12) {
            // No structural changes, just data migration marker
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mamasafe.sqlite'));
    return NativeDatabase(file);
  });
}
