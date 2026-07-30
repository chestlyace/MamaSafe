import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/assessment/screens/assessment_detail_screen.dart';
import '../../features/assessment/screens/assessment_form_screen.dart';
import '../../features/assessment/assessment_repository.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/facilities/screens/facilities_screen.dart';
import '../../features/facilities/screens/facility_form_screen.dart';
import '../../features/referrals/screens/referral_list_screen.dart';
import '../../features/referrals/screens/referral_form_screen.dart';
import '../../features/maternity/screens/maternity_list_screen.dart';
import '../../features/maternity/screens/maternity_form_screen.dart';
import '../../features/growth/screens/growth_list_screen.dart';
import '../../features/growth/screens/growth_form_screen.dart';
import '../../features/growth/screens/growth_chart_screen.dart';
import '../../features/approvals/screens/approval_list_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}

class AssessmentsScreen extends ConsumerWidget {
  const AssessmentsScreen({super.key});

  Color _riskColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return AppColors.accent;
      case 'mid':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assessments')),
      body: assessmentsAsync.when(
        data: (assessments) {
          if (assessments.isEmpty) {
            return const Center(child: Text('No assessments yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: assessments.length,
            itemBuilder: (context, index) {
              final a = assessments[index];
              final riskColor = _riskColor(a.riskLevel);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => context.push('/assessments/${a.id}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.patientRef ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${a.age.toStringAsFixed(0)} years',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          a.riskLevel.toUpperCase(),
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/assessments/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SyncStatusScreen extends StatelessWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Queue')),
      body: const Center(child: Text('Sync queue coming soon')),
    );
  }
}

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Assessments'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), label: 'Profile'),
        ],
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/login/forgot-password';
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (authState.status == AuthStatus.uninitialized) return null;

      if (isSplash) {
        return isAuthenticated ? '/home' : '/login';
      }

      if (!isAuthenticated && !isLoginRoute && !isOnboarding) return '/login';
      if (isAuthenticated && isLoginRoute) return '/home';
      if (isAuthenticated && isOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/login/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
                routes: [
                  GoRoute(path: 'sync', builder: (_, __) => const SyncStatusScreen()),
                  GoRoute(path: 'facilities', builder: (_, __) => const FacilitiesScreen()),
                  GoRoute(path: 'facilities/new', builder: (_, __) => const FacilityFormScreen()),
                  GoRoute(path: 'referrals', builder: (_, __) => const ReferralListScreen()),
                  GoRoute(path: 'referrals/new', builder: (_, __) => const ReferralFormScreen()),
                  GoRoute(path: 'approvals', builder: (_, __) => const ApprovalListScreen()),
                  GoRoute(path: 'pregnancies', builder: (_, __) => const MaternityListScreen()),
                  GoRoute(path: 'pregnancies/new', builder: (_, __) => const MaternityFormScreen()),
                  GoRoute(path: 'growth', builder: (_, __) => const GrowthListScreen()),
                  GoRoute(path: 'growth/new', builder: (_, __) => const GrowthFormScreen()),
                  GoRoute(
                    path: 'growth/:childRef',
                    builder: (_, state) {
                      final childRef = state.pathParameters['childRef']!;
                      return GrowthChartScreen(childRef: childRef);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assessments',
                builder: (_, __) => const AssessmentsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const AssessmentFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return AssessmentDetailScreen(assessmentId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});
