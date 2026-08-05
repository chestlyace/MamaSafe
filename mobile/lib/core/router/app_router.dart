import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/auth/screens/admin_webview_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/chw_signup_screen.dart';
import '../../features/auth/screens/supervisor_signup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/assessment/screens/assessment_detail_screen.dart';
import '../../features/assessment/screens/assessment_form_screen.dart';
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
import '../../features/profile/screens/language_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../l10n/tr.dart';
import '../../features/patients/screens/patient_list_screen.dart';
import '../../features/patients/screens/patient_detail_screen.dart';
import '../../features/patients/screens/patient_form_screen.dart';
import '../../features/anc/screens/anc_visit_list_screen.dart';
import '../../features/anc/screens/anc_visit_form_screen.dart';
import '../../features/anc/screens/anc_visit_detail_screen.dart';
import '../../features/delivery/screens/delivery_list_screen.dart';
import '../../features/delivery/screens/delivery_form_screen.dart';
import '../../features/delivery/screens/delivery_detail_screen.dart';
import '../../features/delivery/screens/newborn_detail_screen.dart';
import '../../features/delivery/screens/postnatal_visit_form_screen.dart';
import '../../features/delivery/screens/mental_health_form_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';
import '../../features/schedule/screens/schedule_form_screen.dart';
import '../../features/escalations/screens/escalations_screen.dart';
import '../../features/escalations/screens/escalation_detail_screen.dart';
import '../../features/supervisor/screens/supervisor_dashboard_screen.dart';
import '../../features/supervisor/screens/supervisor_facilities_screen.dart';
import '../../features/supervisor/screens/approvals_screen.dart';
import '../../features/supervisor/screens/reports_screen.dart';
import '../../features/supervisor/screens/chw_list_screen.dart';
import '../../features/supervisor/screens/chw_form_screen.dart';
import '../../features/supervisor/screens/chw_detail_screen.dart';
import '../../features/supervisor/screens/high_risk_patients_screen.dart';
import '../../features/supervisor/screens/referral_analytics_screen.dart';
import '../../features/supervisor/screens/invite_codes_screen.dart';
import '../../features/sync/sync_status_screen.dart';
import '../../features/auth/user.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isSupervisor = authState.user?.role == UserRole.supervisor ||
        authState.user?.role == UserRole.admin;
    
    if (isSupervisor) {
      return const SupervisorDashboardScreen();
    }
    return const DashboardScreen();
  }
}

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isSupervisor = authState.user?.role.name == 'supervisor' ||
        authState.user?.role.name == 'admin';

    final navItems = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        label: tr(ref, 'nav.home'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.history_outlined),
        label: tr(ref, 'nav.history'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.calendar_month_outlined),
        label: tr(ref, 'nav.schedule'),
      ),
      if (isSupervisor)
        BottomNavigationBarItem(
          icon: const Icon(Icons.shield_outlined),
          label: tr(ref, 'nav.supervisor'),
        ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outlined),
        label: tr(ref, 'nav.profile'),
      ),
    ];

    final navIndexForBranch = isSupervisor
        ? (int branch) => branch
        : (int branch) {
            if (branch < 3) return branch;
            return branch - 1;
          };

    final branchIndexForNavIndex = isSupervisor
        ? (int navIndex) => navIndex
        : (int navIndex) {
            if (navIndex < 3) return navIndex;
            return navIndex + 1;
          };

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navIndexForBranch(navigationShell.currentIndex),
        onTap: (index) =>
            navigationShell.goBranch(branchIndexForNavIndex(index)),
        items: navItems,
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  String landingForUser(User? user) {
    if (user?.role == UserRole.admin) return '/admin-browser';
    if (user?.role == UserRole.supervisor) return '/supervisor';
    return '/home';
  }

  bool isPublicRoute(String location) {
    return location == '/splash' ||
        location == '/onboarding' ||
        location == '/login' ||
        location == '/login/forgot-password' ||
        location == '/signup' ||
        location == '/chw-signup';
  }

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final landing = landingForUser(authState.user);

      if (authState.status == AuthStatus.uninitialized) return null;

      if (isSplash) {
        return isAuthenticated ? landing : '/login';
      }

      if (!isAuthenticated && !isPublicRoute(state.matchedLocation)) {
        return '/login';
      }

      if (isAuthenticated) {
        if (authState.user?.role == UserRole.admin &&
            state.matchedLocation != '/admin-browser') {
          return '/admin-browser';
        }
        if (isPublicRoute(state.matchedLocation) || isOnboarding) {
          return landing;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/signup', builder: (_, __) => const SupervisorSignupScreen()),
      GoRoute(path: '/chw-signup', builder: (_, __) => const ChwSignupScreen()),
      GoRoute(
          path: '/login/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/admin-browser',
        builder: (_, __) => const AdminWebViewScreen(),
      ),
      GoRoute(path: '/assessments', builder: (_, __) => const HistoryScreen()),
      GoRoute(
          path: '/assessments/new',
          builder: (_, __) => const AssessmentFormScreen()),
      GoRoute(
        path: '/assessments/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AssessmentDetailScreen(assessmentId: id);
        },
      ),
      GoRoute(
        path: '/assessments/:id/edit',
        builder: (_, __) => const AssessmentFormScreen(),
      ),
      GoRoute(
        path: '/facilities/new',
        builder: (_, __) => const FacilityFormScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
                routes: [
                  GoRoute(
                      path: 'sync',
                      builder: (_, __) => const SyncStatusScreen()),
                  GoRoute(
                      path: 'facilities',
                      builder: (_, __) => const FacilitiesScreen()),
                  GoRoute(
                      path: 'facilities/new',
                      builder: (_, __) => const FacilityFormScreen()),
                  GoRoute(
                      path: 'referrals',
                      builder: (_, __) => const ReferralListScreen()),
                  GoRoute(
                      path: 'referrals/new',
                      builder: (_, __) => const ReferralFormScreen()),
                  GoRoute(
                      path: 'approvals',
                      builder: (_, __) => const ApprovalListScreen()),
                  GoRoute(
                      path: 'pregnancies',
                      builder: (_, __) => const MaternityListScreen()),
                  GoRoute(
                      path: 'pregnancies/new',
                      builder: (_, __) => const MaternityFormScreen()),
                  GoRoute(
                      path: 'pregnancies/:pregnancyId/anc',
                      builder: (_, state) {
                        final id =
                            int.parse(state.pathParameters['pregnancyId']!);
                        return AncVisitListScreen(pregnancyId: id);
                      }),
                  GoRoute(
                      path: 'pregnancies/:pregnancyId/anc/new',
                      builder: (_, state) {
                        final id =
                            int.parse(state.pathParameters['pregnancyId']!);
                        return AncVisitFormScreen(pregnancyId: id);
                      }),
                  GoRoute(
                      path: 'pregnancies/:pregnancyId/anc/:ancId',
                      builder: (_, state) {
                        final id = int.parse(state.pathParameters['ancId']!);
                        return AncVisitDetailScreen(visitId: id);
                      }),
                  GoRoute(
                      path: 'growth',
                      builder: (_, __) => const GrowthListScreen()),
                  GoRoute(
                      path: 'growth/new',
                      builder: (_, __) => const GrowthFormScreen()),
                  GoRoute(
                    path: 'growth/:childRef',
                    builder: (_, state) {
                      final childRef = state.pathParameters['childRef']!;
                      return GrowthChartScreen(childRef: childRef);
                    },
                  ),
                  GoRoute(
                      path: 'patients',
                      builder: (_, __) => const PatientListScreen()),
                  GoRoute(
                      path: 'patients/new',
                      builder: (_, __) => const PatientFormScreen()),
                  GoRoute(
                    path: 'patients/:id',
                    builder: (_, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return PatientDetailScreen(patientId: id);
                    },
                  ),
                  GoRoute(
                    path: 'patients/:patientId/deliveries',
                    builder: (_, state) {
                      final id = int.parse(state.pathParameters['patientId']!);
                      final pregnancyId = state.pathParameters['pregnancyId'] !=
                              null
                          ? int.tryParse(state.pathParameters['pregnancyId']!)
                          : null;
                      return DeliveryListScreen(
                          patientId: id, pregnancyId: pregnancyId);
                    },
                  ),
                  GoRoute(
                    path: 'patients/:patientId/deliveries/new',
                    builder: (_, state) {
                      final id = int.parse(state.pathParameters['patientId']!);
                      final pregnancyId = state.pathParameters['pregnancyId'] !=
                              null
                          ? int.tryParse(state.pathParameters['pregnancyId']!)
                          : null;
                      return DeliveryFormScreen(
                          patientId: id, pregnancyId: pregnancyId);
                    },
                  ),
                  GoRoute(
                    path: 'patients/:patientId/deliveries/:deliveryId',
                    builder: (_, state) {
                      final patientId =
                          int.parse(state.pathParameters['patientId']!);
                      final deliveryId =
                          int.parse(state.pathParameters['deliveryId']!);
                      return DeliveryDetailScreen(
                          patientId: patientId, deliveryId: deliveryId);
                    },
                  ),
                  GoRoute(
                    path:
                        'patients/:patientId/deliveries/:deliveryId/newborn/:newbornId',
                    builder: (_, state) {
                      final id = int.parse(state.pathParameters['newbornId']!);
                      return NewbornDetailScreen(newbornId: id);
                    },
                  ),
                  GoRoute(
                    path:
                        'patients/:patientId/deliveries/:deliveryId/postnatal/new',
                    builder: (_, state) {
                      final deliveryId =
                          int.parse(state.pathParameters['deliveryId']!);
                      return PostnatalVisitFormScreen(deliveryId: deliveryId);
                    },
                  ),
                  GoRoute(
                    path:
                        'patients/:patientId/deliveries/:deliveryId/mental-health/new',
                    builder: (_, state) {
                      final patientId =
                          int.parse(state.pathParameters['patientId']!);
                      final deliveryId =
                          int.parse(state.pathParameters['deliveryId']!);
                      return MentalHealthFormScreen(
                          patientId: patientId, deliveryId: deliveryId);
                    },
                  ),
                  GoRoute(
                      path: 'escalations',
                      builder: (_, __) => const EscalationsScreen()),
                  GoRoute(
                    path: 'escalations/:id',
                    builder: (_, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return EscalationDetailScreen(escalationId: id);
                    },
                  ),
                  GoRoute(
                      path: 'supervisor',
                      builder: (_, __) => const SupervisorDashboardScreen()),
                  GoRoute(
                      path: 'supervisor/approvals',
                      builder: (_, __) => const ApprovalsScreen()),
                  GoRoute(
                      path: 'supervisor/reports',
                      builder: (_, __) => const ReportsScreen()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, __) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (_, __) => const ScheduleScreen(),
                routes: [
                  GoRoute(
                      path: 'new',
                      builder: (_, __) => const ScheduleFormScreen()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/supervisor',
                builder: (_, __) => const SupervisorDashboardScreen(),
                routes: [
                  GoRoute(
                      path: 'approvals',
                      builder: (_, __) => const ApprovalsScreen()),
                  GoRoute(
                      path: 'reports',
                      builder: (_, __) => const ReportsScreen()),
                  GoRoute(
                      path: 'chws', builder: (_, __) => const ChwListScreen()),
                  GoRoute(
                      path: 'chws/new',
                      builder: (_, __) => const ChwFormScreen()),
                  GoRoute(
                    path: 'chws/:id',
                    builder: (_, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return ChwDetailScreen(chwId: id);
                    },
                  ),
                  GoRoute(
                      path: 'invites',
                      builder: (_, __) => const InviteCodesScreen()),
                  GoRoute(
                      path: 'facilities',
                      builder: (_, __) =>
                          const SupervisorFacilitiesScreen()),
                  GoRoute(
                      path: 'facilities/new',
                      builder: (_, __) => const FacilityFormScreen()),
                  GoRoute(
                      path: 'high-risk',
                      builder: (_, __) => const HighRiskPatientsScreen()),
                  GoRoute(
                      path: 'referrals',
                      builder: (_, __) => const ReferralAnalyticsScreen()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'language',
                    builder: (_, __) => const LanguageScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (_, __) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'password',
                    builder: (_, __) => const ChangePasswordScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
