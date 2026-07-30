import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/auth_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home')),
    );
  }
}

class AssessmentsScreen extends StatelessWidget {
  const AssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessments')),
      body: const Center(child: Text('Assessments')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile')),
    );
  }
}

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
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

      if (authState.status == AuthStatus.uninitialized) return null;

      if (isSplash) {
        return isAuthenticated ? '/home' : '/login';
      }

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/login/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => MainShell(child: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/assessments', builder: (_, __) => const AssessmentsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});
