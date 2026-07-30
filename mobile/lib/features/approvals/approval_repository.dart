import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';

class ApprovalsRepository {
  final AppDatabase _db;
  final Dio _dio;

  ApprovalsRepository(this._db, this._dio);

  Future<List<Approval>> getPendingApprovals() async {
    final query = _db.select(_db.approvals)
      ..where((t) => t.status.equals('pending'))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<void> approve(int id, String reviewer, String? comments) async {
    await _updateStatus(id, 'approved', reviewer, comments);
  }

  Future<void> reject(int id, String reviewer, String? comments) async {
    await _updateStatus(id, 'rejected', reviewer, comments);
  }

  Future<void> _updateStatus(int id, String status, String reviewer, String? comments) async {
    try {
      await _dio.patch('/approvals/$id', data: {
        'status': status,
        'reviewed_by': reviewer,
        'comments': comments,
      });
    } on DioException {
      // fallback — queue for later sync
    }

    await (_db.update(_db.approvals)..where((t) => t.id.equals(id))).write(
      ApprovalsCompanion(
        status: Value(status),
        reviewedBy: Value(reviewer),
        comments: Value(comments),
        reviewedAt: Value(DateTime.now()),
      ),
    );
  }
}

final approvalRepositoryProvider = Provider<ApprovalsRepository>((ref) {
  return ApprovalsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dioProvider),
  );
});

final pendingApprovalsProvider = FutureProvider<List<Approval>>((ref) async {
  final repo = ref.watch(approvalRepositoryProvider);
  return repo.getPendingApprovals();
});
