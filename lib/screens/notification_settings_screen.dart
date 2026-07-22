import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/theme.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final settings = appState.notificationSettings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: const Text("Budget Exceeded Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text("Notify immediately when spending exceeds a budget limit", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  secondary: const Icon(Icons.warning_amber_rounded, color: AppTheme.expenseColor),
                  value: settings.budgetExceeded,
                  onChanged: (val) {
                    appState.updateNotificationSettings(settings.copyWith(budgetExceeded: val));
                  },
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: const Text("Upcoming Bill Reminders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text("Remind me before bills become due", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  secondary: const Icon(Icons.alarm_rounded, color: AppTheme.primary),
                  value: settings.upcomingBill,
                  onChanged: (val) {
                    appState.updateNotificationSettings(settings.copyWith(upcomingBill: val));
                  },
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: const Text("Bill Overdue Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text("Alert when a bill due date has passed without payment", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  secondary: const Icon(Icons.error_outline_rounded, color: AppTheme.expenseColor),
                  value: settings.billOverdue,
                  onChanged: (val) {
                    appState.updateNotificationSettings(settings.copyWith(billOverdue: val));
                  },
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: const Text("Upcoming Recurring Reminder", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text("Notify 1 day before a recurring payment is about to execute", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  secondary: const Icon(Icons.event_repeat_rounded, color: AppTheme.primary),
                  value: settings.recurringDueSoon,
                  onChanged: (val) {
                    appState.updateNotificationSettings(settings.copyWith(recurringDueSoon: val));
                  },
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: const Text("Recurring Transaction Executed", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text("Notify when a recurring payment is auto-processed", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  secondary: const Icon(Icons.repeat_rounded, color: AppTheme.incomeColor),
                  value: settings.recurringExecuted,
                  onChanged: (val) {
                    appState.updateNotificationSettings(settings.copyWith(recurringExecuted: val));
                  },
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: const Text("Budget Ending Soon", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text("Notify 3 days before a budget cycle ends", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  secondary: const Icon(Icons.timer_rounded, color: AppTheme.warningColor),
                  value: settings.budgetEndingSoon,
                  onChanged: (val) {
                    appState.updateNotificationSettings(settings.copyWith(budgetEndingSoon: val));
                  },
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: const Text("General Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text("Enable app update announcements and general tips", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  secondary: const Icon(Icons.notifications_active_rounded, color: AppTheme.secondary),
                  value: settings.generalNotifications,
                  onChanged: (val) {
                    appState.updateNotificationSettings(settings.copyWith(generalNotifications: val));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
