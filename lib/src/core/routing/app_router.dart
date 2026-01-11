import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/onboarding/presentation/onboarding_flow_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transactions/presentation/add_transaction_sheet.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import 'route_names.dart';

/// GoRouter configuration with first-run detection
class AppRouter {
  static const String _firstRunKey = 'is_first_run';

  static Future<bool> _isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool(_firstRunKey) ?? true;
    return isFirstRun;
  }

  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: RouteNames.dashboard,
      redirect: (context, state) async {
        // Check if this is the first run
        final isFirstRun = await _isFirstRun();

        // If first run and not on onboarding, redirect to onboarding
        if (isFirstRun && state.matchedLocation != RouteNames.onboarding) {
          return RouteNames.onboarding;
        }

        // If not first run and on onboarding, redirect to dashboard
        if (!isFirstRun && state.matchedLocation == RouteNames.onboarding) {
          return RouteNames.dashboard;
        }

        return null; // No redirect needed
      },
      routes: [
        GoRoute(
          path: RouteNames.onboarding,
          name: RouteNames.onboarding,
          builder: (context, state) => const OnboardingFlowScreen(),
        ),
        GoRoute(
          path: RouteNames.dashboard,
          name: RouteNames.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.addTransaction,
          name: RouteNames.addTransaction,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AddTransactionSheet(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.linear;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: RouteNames.transactions,
          name: RouteNames.transactions,
          builder: (context, state) => const TransactionsScreen(),
        ),
        GoRoute(
          path: RouteNames.insights,
          name: RouteNames.insights,
          builder: (context, state) => const InsightsScreen(),
        ),
        GoRoute(
          path: RouteNames.settings,
          name: RouteNames.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }
}
