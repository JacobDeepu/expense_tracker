import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/routing/route_names.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/providers/reminder_providers.dart';
import 'features/transactions/logic/transaction_processor_controller.dart';

class ExpenseTrackerApp extends ConsumerStatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  ConsumerState<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends ConsumerState<ExpenseTrackerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for notification taps after widget is built
    final reminderService = ref.read(reminderServiceProvider);

    // Initialize notifications
    reminderService.initializeNotifications();

    reminderService.onTap.listen((payload) {
      if (payload == 'daily_entry') {
        // Navigate to Add Transaction screen
        _router.push(RouteNames.addTransaction);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the transaction processor to listen for notifications
    ref.watch(transactionProcessorProvider).initialize();

    return MaterialApp.router(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
