import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../services/export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExportingPdf = false;
  bool _isExportingCsv = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = appState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User profile header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primary.withAlpha((0.15 * 255).toInt()),
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User Name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'user@example.com',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Preferences Title
            Text(
              "Preferences & Configuration",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Theme Mode Selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text("Theme Mode"),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
                    value: appState.themeMode,
                    dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                    onChanged: (val) {
                      if (val != null) appState.updateThemeMode(val);
                    },
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text("System Default")),
                      DropdownMenuItem(value: ThemeMode.light, child: Text("Light")),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text("Dark")),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Manage Accounts & Cards Header
            Text(
              "Manage Accounts & Cards",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Accounts List Card
            if (appState.myAccounts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "No accounts created yet.",
                    style: TextStyle(color: theme.hintColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text(
                          "Drag items to change order",
                          style: TextStyle(color: theme.hintColor, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                      const Divider(height: 12),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: appState.myAccounts.length,
                        onReorder: (oldIndex, newIndex) async {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final newList = List<AccountItem>.from(appState.myAccounts);
                          final item = newList.removeAt(oldIndex);
                          newList.insert(newIndex, item);
                          await appState.updateAccountsOrder(newList);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Account order updated"),
                                duration: Duration(milliseconds: 800),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context, index) {
                          final acc = appState.myAccounts[index];
                          final isCc = acc.type == AccountType.creditCard;
                          return Container(
                            key: ValueKey(acc.id),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.5),
                                  width: index == appState.accounts.length - 1 ? 0 : 0.5,
                                ),
                              ),
                            ),
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.drag_handle, color: theme.hintColor, size: 20),
                                  const SizedBox(width: 8),
                                  Icon(isCc ? Icons.credit_card : Icons.account_balance),
                                ],
                              ),
                              title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(isCc ? "Credit Card" : "Bank Account", style: TextStyle(color: theme.hintColor, fontSize: 11)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.expenseColor),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Delete Account?"),
                                      content: Text("Are you sure you want to delete '${acc.name}'? Transactions linked to this account will be reset to default bank account."),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text("Delete", style: TextStyle(color: AppTheme.expenseColor)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    appState.deleteAccount(acc.id);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Data & Export Section
            Text(
              "Data & Export",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: AppTheme.expenseColor),
                    title: const Text("Export Financial Report (PDF)"),
                    subtitle: const Text("Includes net worth overview and full transactions details", style: TextStyle(fontSize: 11)),
                    trailing: _isExportingPdf
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.chevron_right),
                    onTap: _isExportingPdf || _isExportingCsv
                        ? null
                        : () async {
                            setState(() => _isExportingPdf = true);
                            try {
                              final double netBalance = appState.accounts.fold(0.0, (sum, acc) {
                                final balance = appState.getAccountBalance(acc);
                                return sum + (acc.type == AccountType.creditCard ? ((acc.limit ?? 0.0) - balance) : balance);
                              });
                              
                              final double totalIncome = appState.transactions
                                  .where((tx) => !tx.isTransfer && tx.type == TransactionType.income)
                                  .fold(0.0, (sum, tx) => sum + tx.amount);

                              final double totalExpense = appState.transactions
                                  .where((tx) => !tx.isTransfer && tx.type == TransactionType.expense)
                                  .fold(0.0, (sum, tx) => sum + tx.amount);

                              await ExportService.exportToPdf(
                                transactions: appState.transactions,
                                accounts: appState.accounts,
                                categories: appState.categories,
                                netBalance: netBalance,
                                totalIncome: totalIncome,
                                totalExpense: totalExpense,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error exporting PDF: $e")),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isExportingPdf = false);
                              }
                            }
                          },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.table_view, color: AppTheme.incomeColor),
                    title: const Text("Export Transaction History (CSV / Excel)"),
                    subtitle: const Text("Table data format for spreadsheets", style: TextStyle(fontSize: 11)),
                    trailing: _isExportingCsv
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.chevron_right),
                    onTap: _isExportingPdf || _isExportingCsv
                        ? null
                        : () async {
                            setState(() => _isExportingCsv = true);
                            try {
                              await ExportService.exportToCsv(
                                transactions: appState.transactions,
                                accounts: appState.accounts,
                                categories: appState.categories,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error exporting CSV: $e")),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isExportingCsv = false);
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App info panel
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text("Version"),
                    trailing: Text("1.0.0", style: TextStyle(color: theme.hintColor)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text("Built With"),
                    trailing: Text("Flutter & Firebase", style: TextStyle(color: theme.hintColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton(
              onPressed: () {
                appState.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.expenseColor,
                foregroundColor: Colors.white,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text("Log Out"),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
