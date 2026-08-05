import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/tr.dart';
import '../../facilities/screens/facilities_screen.dart';
import 'approvals_screen.dart';

class SupervisorFacilitiesScreen extends ConsumerStatefulWidget {
  const SupervisorFacilitiesScreen({super.key});

  @override
  ConsumerState<SupervisorFacilitiesScreen> createState() =>
      _SupervisorFacilitiesScreenState();
}

class _SupervisorFacilitiesScreenState
    extends ConsumerState<SupervisorFacilitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'supervisor.facilities')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: tr(ref, 'supervisor.facilities')),
            Tab(text: tr(ref, 'approval.title')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FacilitiesTabView(),
          ApprovalsBody(darkTabBar: false),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/facilities/new'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
