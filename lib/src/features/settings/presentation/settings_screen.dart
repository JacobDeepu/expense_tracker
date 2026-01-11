import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/preferences_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../onboarding/providers/reminder_providers.dart';
import '../../../data/local/database_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Debug Function: Test Nudge
  Future<void> _testNudge() async {
    final reminderService = ref.read(reminderServiceProvider);
    
    // Request permission just in case
    final granted = await reminderService.requestPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied! Cannot show notification.')),
        );
      }
      return;
    }
    
    await reminderService.showTestNotification();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent immediate test notification')),
      );
    }
  }

  Future<void> _editBudget(BuildContext context, double currentBudget) async {
    final controller = TextEditingController(text: currentBudget.toStringAsFixed(0));
    final newBudget = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: '₹',
            labelText: 'Amount',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) Navigator.pop(context, val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newBudget != null) {
      await ref.read(preferencesServiceProvider).saveMonthlyBudget(newBudget);
      ref.invalidate(dailyBaseBudgetProvider);
      if (mounted) setState(() {});
    }
  }

  Future<void> _editReminderTime(BuildContext context, TimeOfDay? currentTime) async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: currentTime ?? const TimeOfDay(hour: 21, minute: 0),
    );

    if (newTime != null) {
      final prefs = ref.read(preferencesServiceProvider);
      final reminderService = ref.read(reminderServiceProvider);

      await prefs.saveReminderTime(newTime);
      await reminderService.scheduleDailyReminder(newTime);

      if (!mounted) return;
      
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder set for ${newTime.format(context)}')),
      );
    }
  }

  Future<void> _resetOnboarding() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App?'),
        content: const Text(
          'This will delete ALL transactions, recurring rules, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Wipe DB
      final db = ref.read(databaseProvider);
      await db.delete(db.transactions).go();
      await db.delete(db.recurringRules).go();
      // We keep Categories and Patterns as they are system/seed data usually, 
      // but 'Reset Onboarding' implies fresh start. Seeding happens on creation.
      // Let's just delete user data.

      // 2. Wipe Prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. Cancel Notifications
      final reminderService = ref.read(reminderServiceProvider);
      // We don't have a 'cancel' exposed, but scheduling nothing/overwriting is fine.
      // Or we can just restart.

      if (mounted) {
        // Navigate to Onboarding
        // Use pushReplacement or go to clear stack logic if possible, 
        // but 'go' handles location.
        // We need to force refresh providers?
        // App restart is best, but navigation works.
        context.go('/onboarding'); // Hardcoded route to avoid circular dependency if any
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final prefs = ref.watch(preferencesServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.displayL(textPrimary).copyWith(fontSize: 24)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          
          _buildSectionHeader('Finances', textSecondary),
          FutureBuilder<double?>(
            future: prefs.getMonthlyBudget(),
            builder: (context, snapshot) {
              final budget = snapshot.data ?? 0.0;
              return _buildListTile(
                title: 'Monthly Budget',
                subtitle: '₹${budget.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_outlined,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => _editBudget(context, budget),
              );
            },
          ),
          _buildListTile(
            title: 'Recurring Expenses',
            subtitle: 'Manage rent, bills, subscriptions',
            icon: Icons.refresh_outlined,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () {
               // TODO: Open recurring rules list
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon: Recurring Manager')));
            },
          ),

          const Divider(height: 48),

          _buildSectionHeader('Preferences', textSecondary),
          FutureBuilder<TimeOfDay?>(
            future: prefs.getReminderTime(),
            builder: (context, snapshot) {
              final time = snapshot.data;
              final timeStr = time != null ? time.format(context) : 'Not set';
              return _buildListTile(
                title: 'Daily Reminder',
                subtitle: timeStr,
                icon: Icons.notifications_outlined,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => _editReminderTime(context, time),
              );
            },
          ),

          const Divider(height: 48),

          _buildSectionHeader('Debug Zone', Colors.redAccent),
          _buildListTile(
            title: 'Test Daily Nudge',
            subtitle: 'Schedule notification for +1 min',
            icon: Icons.bug_report_outlined,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: _testNudge,
          ),
          _buildListTile(
            title: 'Reset Onboarding',
            subtitle: 'Wipe all data and restart',
            icon: Icons.delete_forever_outlined,
            textPrimary: Colors.red,
            textSecondary: textSecondary,
            onTap: _resetOnboarding,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.captionUppercase(color),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: textPrimary),
      title: Text(title, style: AppTypography.bodyM(textPrimary)),
      subtitle: Text(subtitle, style: AppTypography.bodyM(textSecondary)),
      trailing: Icon(Icons.chevron_right, color: textSecondary),
      onTap: onTap,
    );
  }
}
