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
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
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

class PendingOps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text().named('operation_type')();
  TextColumn get endpoint => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
}

class Referrals extends Table {
  IntColumn get id => integer()();
  IntColumn get assessmentId => integer().named('assessment_id')();
  TextColumn get patientRef => text().named('patient_ref').nullable()();
  TextColumn get referredTo => text().named('referred_to')();
  TextColumn get reason => text()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get referralDate => dateTime().named('referral_date')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class Pregnancies extends Table {
  IntColumn get id => integer()();
  TextColumn get patientName => text().named('patient_name')();
  TextColumn get patientRef => text().named('patient_ref').nullable()();
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

class GrowthRecords extends Table {
  IntColumn get id => integer()();
  TextColumn get childName => text().named('child_name')();
  TextColumn get childRef => text().named('child_ref').nullable()();
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

@DriftDatabase(tables: [Assessments, PendingOps, Facilities, Referrals, Pregnancies, GrowthRecords, Approvals])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(facilities);
          }
          if (from < 3) {
            await migrator.createTable(pregnancies);
          }
          if (from < 4) {
            await migrator.createTable(growthRecords);
          }
          if (from < 5) {
            await migrator.createTable(approvals);
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
