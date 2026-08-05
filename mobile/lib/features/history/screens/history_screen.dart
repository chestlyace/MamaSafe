import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../history_repository.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  HistoryFilterParams _params = const HistoryFilterParams();
  GoRouter? _router;
  String _lastPath = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_router == null) {
      final router = GoRouter.of(context);
      _router = router;
      router.routerDelegate.addListener(_onRouteChanged);
    }
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final path = _router!.routerDelegate.currentConfiguration.uri.path;
    if (path == _lastPath) return;
    _lastPath = path;
    // Refresh when the history screen becomes visible again so newly created
    // assessments/patients appear without needing a manual pull-to-refresh.
    if (path == '/history') {
      ref.invalidate(historyProvider(_params));
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() =>
          _params = _params.copyWith(search: value.isEmpty ? null : value));
    });
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() => _params = const HistoryFilterParams());
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider(_params));

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'history.title'))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr(ref, 'history.search'),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.4),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterPanel(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: historyAsync.when(
              data: (result) => _buildResult(result),
              loading: () => _buildGrid(
                  itemCount: 6, itemBuilder: (_, __) => const _ShimmerCard()),
              error: (e, _) => AppErrorWidget(
                error: e,
                onRetry: () => ref.invalidate(historyProvider(_params)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(HistoryLoadResult result) {
    final items = result.items;

    if (items.isEmpty) {
      if (!result.synced) {
        return EmptyState(
          icon: Icons.cloud_off,
          title: tr(ref, 'history.couldNotSync'),
          subtitle: tr(ref, 'history.couldNotSyncSubtitle'),
          actionLabel: tr(ref, 'history.retry'),
          onAction: () => ref.invalidate(historyProvider(_params)),
        );
      }
      final hasActiveFilter = _params.search != null ||
          _params.riskFilter != null ||
          _params.typeFilter != null;
      if (hasActiveFilter) {
        return EmptyState(
          icon: Icons.search_off,
          title: tr(ref, 'history.noResults'),
          subtitle: tr(ref, 'history.noResultsSubtitle'),
        );
      }
      return EmptyState(
        icon: Icons.history,
        title: tr(ref, 'history.empty'),
        subtitle: tr(ref, 'history.emptySubtitle'),
      );
    }

    return Column(
      children: [
        if (!result.synced)
          _OfflineBanner(
            message: tr(ref, 'history.offline'),
            retryLabel: tr(ref, 'history.retry'),
            onRetry: () => ref.invalidate(historyProvider(_params)),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(historyProvider(_params));
              await ref.read(historyProvider(_params).future);
            },
            child: _buildGrid(
              itemCount: items.length,
              itemBuilder: (context, index) => _HistoryCard(item: items[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 150,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  Widget _groupLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _clearAllButton() {
    return InkWell(
      onTap: _clearAllFilters,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          tr(ref, 'history.clearAll'),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    final riskSelected = _params.riskFilter;
    final typeSelected = _params.typeFilter;
    final hasActiveFilters = riskSelected != null || typeSelected != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: _groupLabel(tr(ref, 'history.filters')),
              ),
              if (hasActiveFilters) _clearAllButton(),
            ],
          ),
          const SizedBox(height: 14),
          _groupLabel(tr(ref, 'history.filterRisk')),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: tr(ref, 'history.all'),
                  selected: riskSelected == null,
                  onSelected: () =>
                      setState(() => _params = _params.copyWith(riskFilter: null)),
                ),
                _FilterPill(
                  label: tr(ref, 'risk.high'),
                  accent: AppColors.error,
                  selected: riskSelected == 'high',
                  onSelected: () => setState(() => _params = _params.copyWith(
                      riskFilter: riskSelected == 'high' ? null : 'high')),
                ),
                _FilterPill(
                  label: tr(ref, 'risk.mid'),
                  accent: AppColors.warning,
                  selected: riskSelected == 'mid',
                  onSelected: () => setState(() => _params = _params.copyWith(
                      riskFilter: riskSelected == 'mid' ? null : 'mid')),
                ),
                _FilterPill(
                  label: tr(ref, 'risk.low'),
                  accent: AppColors.success,
                  selected: riskSelected == 'low',
                  onSelected: () => setState(() => _params = _params.copyWith(
                      riskFilter: riskSelected == 'low' ? null : 'low')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _groupLabel(tr(ref, 'history.filterType')),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: tr(ref, 'history.all'),
                  selected: typeSelected == null,
                  onSelected: () =>
                      setState(() => _params = _params.copyWith(typeFilter: null)),
                ),
                _FilterPill(
                  label: tr(ref, 'nav.assessments'),
                  selected: typeSelected == 'assessment',
                  onSelected: () => setState(() => _params = _params.copyWith(
                      typeFilter: typeSelected == 'assessment' ? null : 'assessment')),
                ),
                _FilterPill(
                  label: tr(ref, 'patients.title'),
                  selected: typeSelected == 'patient',
                  onSelected: () => setState(() => _params = _params.copyWith(
                      typeFilter: typeSelected == 'patient' ? null : 'patient')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? accent;
  final VoidCallback onSelected;

  const _FilterPill({
    required this.label,
    required this.selected,
    this.accent,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.6) : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : AppColors.textBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _OfflineBanner({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 16, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12, color: AppColors.textBody),
              ),
            ),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.textBody),
              tooltip: retryLabel,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final HistoryItem item;

  const _HistoryCard({required this.item});

  Color _riskColor() {
    switch (item.riskLevel) {
      case 'high':
        return AppColors.error;
      case 'mid':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _typeTint() {
    switch (item.type) {
      case 'assessment':
        return AppColors.primaryLight;
      case 'patient':
        return AppColors.secondaryLight;
      case 'pregnancy':
        return const Color(0xFFFEF3C7);
      default:
        return AppColors.surfaceAlt;
    }
  }

  Color _typeColor() {
    switch (item.type) {
      case 'assessment':
        return AppColors.primary;
      case 'patient':
        return AppColors.secondary;
      case 'pregnancy':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _typeIcon() {
    switch (item.type) {
      case 'assessment':
        return Icons.fact_check_outlined;
      case 'patient':
        return Icons.person_outline;
      case 'pregnancy':
        return Icons.pregnant_woman;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskColor = _riskColor();
    return AppCard(
      onTap: () => context.push(item.route),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _typeTint(),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(_typeIcon(), size: 17, color: _typeColor()),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.riskLevel.toUpperCase(),
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.subtitle!,
                  style:
                      const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${item.date.day}/${item.date.month}/${item.date.year}',
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(9)),
              ),
              const Spacer(),
              Container(
                width: 48,
                height: 18,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(6)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                height: 14,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 8),
              Container(
                width: 70,
                height: 12,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
