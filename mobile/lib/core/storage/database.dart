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

class PendingOps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text().named('operation_type')();
  TextColumn get endpoint => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
}

@DriftDatabase(tables: [Assessments, PendingOps])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mamasafe.sqlite'));
    return NativeDatabase(file);
  });
}
