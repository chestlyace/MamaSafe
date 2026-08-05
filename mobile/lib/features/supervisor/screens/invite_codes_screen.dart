import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../supervisor_repository.dart';

class InviteCodesScreen extends ConsumerStatefulWidget {
  const InviteCodesScreen({super.key});

  @override
  ConsumerState<InviteCodesScreen> createState() => _InviteCodesScreenState();
}

class _InviteCodesScreenState extends ConsumerState<InviteCodesScreen> {
  final _noteController = TextEditingController();
  int _expiresInDays = 14;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatCode(String code) {
    if (code.length == 8) {
      return '${code.substring(0, 4)}-${code.substring(4)}';
    }
    return code;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'used':
        return AppColors.success;
      case 'revoked':
        return AppColors.textSecondary;
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return tr(ref, 'supervisor.pending');
      case 'used':
        return tr(ref, 'supervisor.used');
      case 'revoked':
        return tr(ref, 'supervisor.revoked');
      case 'expired':
        return tr(ref, 'supervisor.expired');
      default:
        return status;
    }
  }

  Future<void> _generateCode() async {
    try {
      await ref.read(inviteCodeActionsProvider.notifier).create(
            note: _noteController.text.isEmpty ? null : _noteController.text,
            expiresInDays: _expiresInDays,
          );
      ref.invalidate(inviteCodesProvider);
      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(ref, 'supervisor.codeGenerated'))),
        );
      }
    } catch (_) {}
  }

  Future<void> _revokeCode(int codeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ref, 'supervisor.revokeConfirmTitle')),
        content: Text(tr(ref, 'supervisor.revokeConfirmMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr(ref, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr(ref, 'supervisor.revokeCode')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(inviteCodeActionsProvider.notifier).revoke(codeId);
      ref.invalidate(inviteCodesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(ref, 'supervisor.codeRevoked'))),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final codesAsync = ref.watch(inviteCodesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'supervisor.inviteCodes')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: tr(ref, 'supervisor.inviteNoteHint'),
                      labelText: tr(ref, 'common.notes'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _expiresInDays,
                    decoration: InputDecoration(
                      labelText: tr(ref, 'supervisor.expiration'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [7, 14, 30].map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(tr(ref, 'supervisor.days', {'count': '$d'})),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _expiresInDays = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _generateCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(tr(ref, 'supervisor.generateCode')),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: codesAsync.when(
              data: (codes) {
                if (codes.isEmpty) {
                  return EmptyState(
                    icon: Icons.vpn_key,
                    title: tr(ref, 'supervisor.noInviteCodes'),
                    subtitle: tr(ref, 'supervisor.noInviteCodesSubtitle'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: codes.length,
                  itemBuilder: (context, i) {
                    final code = codes[i];
                    final color = _statusColor(code.status);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatCode(code.code),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _formatCode(code.code)));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              tr(ref, 'supervisor.copied'))),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusLabel(code.status),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('yyyy-MM-dd')
                                      .format(code.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (code.note != null && code.note!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                code.note!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textBody,
                                ),
                              ),
                            ],
                            if (code.status == 'pending') ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _revokeCode(code.id),
                                  child: Text(tr(ref, 'supervisor.revokeCode')),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                  error: e,
                  onRetry: () => ref.invalidate(inviteCodesProvider)),
            ),
          ),
        ],
      ),
    );
  }
}
