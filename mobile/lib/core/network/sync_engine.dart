import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/database.dart';
import '../storage/database_provider.dart';
import 'api_client.dart';

class SyncProgress {
  final int total;
  final int completed;
  final int failed;
  final bool isRunning;

  const SyncProgress({
    required this.total,
    required this.completed,
    required this.failed,
    required this.isRunning,
  });
}

class SyncEngine {
  final AppDatabase _db;
  final Dio _dio;
  final StreamController<SyncProgress> _progressController =
      StreamController<SyncProgress>.broadcast();
  DateTime? _lastSyncTime;

  Stream<SyncProgress> get progressStream => _progressController.stream;
  DateTime? get lastSyncTime => _lastSyncTime;

  SyncEngine(this._db, this._dio);

  Future<int> get pendingCount async {
    final result = await _db
        .customSelect('SELECT COUNT(*) AS c FROM pending_ops')
        .getSingle();
    return result.read<int>('c');
  }

  Future<int> syncAll() async {
    final ops = await _db.select(_db.pendingOps).get();
    if (ops.isEmpty) {
      _progressController.add(const SyncProgress(
          total: 0, completed: 0, failed: 0, isRunning: false));
      return 0;
    }

    final total = ops.length;
    int completed = 0;
    int failed = 0;

    _progressController.add(SyncProgress(
        total: total, completed: 0, failed: 0, isRunning: true));

    for (final op in ops) {
      try {
        await _executeOp(op);
        await _db.delete(_db.pendingOps).delete(op);
        completed++;
      } catch (e) {
        failed++;
      }
      _progressController.add(SyncProgress(
        total: total,
        completed: completed,
        failed: failed,
        isRunning: true,
      ));
    }

    _lastSyncTime = DateTime.now();
    _progressController.add(SyncProgress(
      total: total,
      completed: completed,
      failed: failed,
      isRunning: false,
    ));
    return completed;
  }

  Future<void> _executeOp(PendingOp op) async {
    final payload = jsonDecode(op.payload);
    switch (op.operationType.toUpperCase()) {
      case 'POST':
        await _dio.post(op.endpoint, data: payload);
      case 'PUT':
        await _dio.put(op.endpoint, data: payload);
      case 'PATCH':
        await _dio.patch(op.endpoint, data: payload);
      case 'DELETE':
        await _dio.delete(op.endpoint);
      default:
        await _dio.post(op.endpoint, data: payload);
    }
  }

  void dispose() {
    _progressController.close();
  }
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return SyncEngine(db, dio);
});

final syncProgressProvider = StreamProvider<SyncProgress>((ref) {
  return ref.watch(syncEngineProvider).progressStream;
});

final pendingOpsProvider = FutureProvider<List<PendingOp>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.pendingOps).get();
});

class TriggerSync {
  final Ref _ref;
  TriggerSync(this._ref);

  Future<int> call() => _ref.read(syncEngineProvider).syncAll();
}

final triggerSyncProvider = Provider<TriggerSync>((ref) => TriggerSync(ref));
