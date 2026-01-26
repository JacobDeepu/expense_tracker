import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  Future<void> _testNudge() async {
    final reminderService = ref.read(reminderServiceProvider);
    final granted = await reminderService.requestPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied! Cannot show notification.'),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceSecondaryLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    final controller = TextEditingController(
      text: currentBudget.toStringAsFixed(0),
    );
    final newBudget = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        title: Text(
          'Monthly Budget',
          style: AppTypography.headingS(textPrimary),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppTypography.bodyL(textPrimary),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: AppTypography.bodyL(textPrimary),
            labelText: 'Amount',
            labelStyle: AppTypography.bodyM(
              isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.bodyM(textPrimary)),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) Navigator.pop(context, val);
            },
            child: Text(
              'Save',
              style: AppTypography.bodyM(
                isDark ? AppColors.signalBlueDark : AppColors.signalBlueLight,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
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

  Future<void> _editReminderTime(
    BuildContext context,
    TimeOfDay? currentTime,
  ) async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: currentTime ?? const TimeOfDay(hour: 21, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.signalBlueDark
                  : AppColors.signalBlueLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!context.mounted) return;

    if (newTime != null) {
      final timeString = newTime.format(context);
      final prefs = ref.read(preferencesServiceProvider);
      final reminderService = ref.read(reminderServiceProvider);

      await prefs.saveReminderTime(newTime);
      await reminderService.scheduleDailyReminder(newTime);

      if (!context.mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reminder set for $timeString')));
    }
  }

  Future<void> _resetOnboarding() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.surfaceSecondaryDark
        : AppColors.surfaceSecondaryLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset App?', style: AppTypography.headingS(textPrimary)),
        content: Text(
          'This will delete ALL transactions, recurring rules, and settings. This action cannot be undone.',
          style: AppTypography.bodyM(
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTypography.bodyM(textPrimary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Reset Everything',
              style: AppTypography.bodyM(
                Colors.red,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await db.delete(db.transactions).go();
      await db.delete(db.recurringRules).go();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final scaffoldBg = isDark
        ? AppColors.surfacePrimaryDark
        : AppColors.surfacePrimaryLight;

    final prefs = ref.watch(preferencesServiceProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scaffoldBg,
        title: Text('Settings', style: AppTypography.headingM(textPrimary)),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary, size: 24),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 16),

          _buildSectionHeader('Finances', textSecondary),
          FutureBuilder<double?>(
            future: prefs.getMonthlyBudget(),
            builder: (context, snapshot) {
              final budget = snapshot.data ?? 0.0;
              return _buildListTile(
                title: 'Monthly Budget',
                subtitle: '₹${budget.toStringAsFixed(0)}',
                icon: LucideIcons.wallet,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
                onTap: () => _editBudget(context, budget),
              );
            },
          ),
          _buildListTile(
            title: 'Recurring Expenses',
            subtitle: 'Manage rent, bills, subscriptions',
            icon: LucideIcons.repeat,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
            onTap: () {
              context.push('/settings/recurring');
            },
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Preferences', textSecondary),
          FutureBuilder<TimeOfDay?>(
            future: prefs.getReminderTime(),
            builder: (context, snapshot) {
              final time = snapshot.data;
              final timeStr = time != null ? time.format(context) : 'Not set';
              return _buildListTile(
                title: 'Daily Reminder',
                subtitle: timeStr,
                icon: LucideIcons.bell,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
                onTap: () => _editReminderTime(context, time),
              );
            },
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Support & Debug', Colors.amber),
          _buildListTile(
            title: 'Test Daily Nudge',
            subtitle: 'Send test notification',
            icon: LucideIcons.bug,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
            onTap: _testNudge,
          ),
          _buildListTile(
            title: 'Reset Onboarding',
            subtitle: 'Wipe all data and restart',
            icon: LucideIcons.trash2,
            textPrimary: Colors.red,
            textSecondary: textSecondary,
            isDark: isDark,
            onTap: _resetOnboarding,
          ),

          const SizedBox(height: 48),
          Center(
            child: Text('v1.0.0', style: AppTypography.caption(textSecondary)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.captionUppercase(
          color,
        ).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                (isDark ? AppColors.signalBlueDark : AppColors.signalBlueLight)
                    .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDark
                ? AppColors.signalBlueDark
                : AppColors.signalBlueLight,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTypography.bodyL(
            textPrimary,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(subtitle, style: AppTypography.bodyM(textSecondary)),
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          color: textSecondary,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }
}
