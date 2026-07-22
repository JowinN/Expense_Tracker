import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/account_selector.dart';

import 'transactions_screen.dart'; // import to reuse AddTransactionSheet
import 'recurring_transactions_screen.dart';
import 'bill_reminders_screen.dart';

enum DueItemType { bill, recurring }

class DashboardDueItem {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final DateTime dueDate;
  final TransactionType type;
  final DueItemType itemType;
  final BillReminderItem? bill;
  final TransactionItem? recurringTx;

  DashboardDueItem.fromBill(BillReminderItem b)
      : id = 'bill_${b.id}',
        title = b.title,
        amount = b.amount,
        categoryId = b.categoryId,
        dueDate = b.dueDate,
        type = TransactionType.expense,
        itemType = DueItemType.bill,
        bill = b,
        recurringTx = null;

  DashboardDueItem.fromRecurring(TransactionItem t)
      : id = 'rec_${t.id}',
        title = t.title,
        amount = t.amount,
        categoryId = t.categoryId,
        dueDate = t.nextRecurringDate!,
        type = t.type,
        itemType = DueItemType.recurring,
        bill = null,
        recurringTx = t;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _touchedIndex = -1;

  final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    // Show disclosure dialog before requesting SMS permission (required by Google Play policy)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestSmsPermissionWithDisclosure();
    });
  }

  Future<void> _requestSmsPermissionWithDisclosure() async {
    // Only show the dialog on Android and only if not already granted
    if (!Platform.isAndroid) return;
    try {
      final alreadyGranted = await const MethodChannel('com.family.spendwise/sms')
          .invokeMethod<bool>('hasPermissions') ?? false;
      if (alreadyGranted || !mounted) return;
    } catch (_) {
      // hasPermissions not implemented — fall through and show dialog anyway
    }

    if (!mounted) return;
    // Use this.context (State property) after mounted check — safe across async gaps
    final confirmed = await showDialog<bool>(
      context: context, // ignore: use_build_context_synchronously
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sms_outlined, color: Colors.orange),
            SizedBox(width: 10),
            Text('SMS Access'),
          ],
        ),
        content: const Text(
          'SpendWise reads incoming bank SMS messages to automatically detect '
          'transactions and show them as pending alerts in your Dashboard.\n\n'
          'Messages are processed entirely on-device and are never uploaded, '
          'stored externally, or shared with any third party.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      const MethodChannel('com.family.spendwise/sms')
          .invokeMethod('requestPermissions')
          .catchError((_) => null);
    }
  }

  void _showTransactionDetailsSheet(BuildContext context, TransactionItem tx, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final cat = appState.categories.firstWhere(
          (c) => c.id == tx.categoryId,
          orElse: () => CategoryItem(
            id: 'other',
            name: 'Other',
            iconKey: 'other',
            colorValue: Colors.grey.value,
            type: TransactionType.expense,
          ),
        );
        final dateStr = DateFormat('EEEE, MMMM dd, yyyy').format(tx.date);

        final acc = appState.accounts.firstWhere(
          (a) => a.id == tx.accountId,
          orElse: () => AccountItem(
            id: 'other',
            name: 'Default Account',
            type: AccountType.bank,
            initialBalance: 0,
            creatorId: '',
          ),
        );

        final toAcc = tx.toAccountId != null
            ? appState.accounts.firstWhere(
                (a) => a.id == tx.toAccountId,
                orElse: () => AccountItem(
                  id: 'other',
                  name: 'Default Card',
                  type: AccountType.creditCard,
                  initialBalance: 0,
                  creatorId: '',
                ),
              )
            : null;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Transaction Details", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Color(cat.colorValue).withAlpha(30),
                  child: Icon(categoryIcons[cat.iconKey] ?? Icons.more_horiz, color: Color(cat.colorValue)),
                ),
                title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(dateStr, style: TextStyle(color: theme.hintColor)),
                trailing: Text(
                  "${tx.type == TransactionType.income ? '+' : '-'}${formatter.format(tx.amount)}",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: tx.type == TransactionType.income ? AppTheme.incomeColor : AppTheme.expenseColor,
                  ),
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Category:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(cat.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Account / Card:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(acc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              if (toAcc != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Paid to Credit Card:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(toAcc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Added By:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text("${tx.creatorName} (${tx.creatorEmail})", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              if (tx.isRecurring) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Recurrence:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(tx.recurrenceInterval.name.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppTheme.expenseColor),
                      ),
                      icon: const Icon(Icons.delete, color: AppTheme.expenseColor),
                      label: const Text("Delete", style: TextStyle(color: AppTheme.expenseColor)),
                      onPressed: () {
                        Navigator.pop(context);
                        appState.deleteTransaction(tx.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Transaction deleted")),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: AppTheme.primary,
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit"),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditTransactionSheet(context, tx);
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _showEditTransactionSheet(BuildContext context, TransactionItem tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(editingTransaction: tx),
    );
  }

  String _selectedDashboardPeriod = 'This Month';
  DateTimeRange? _customPeriodRange;

  DateTimeRange _getPeriodRange() {
    final now = DateTime.now();
    if (_selectedDashboardPeriod == 'Today') {
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return DateTimeRange(start: start, end: end);
    } else if (_selectedDashboardPeriod == 'This Week') {
      final start = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(start.year, start.month, start.day);
      return DateTimeRange(start: startDate, end: now);
    } else if (_selectedDashboardPeriod == 'Last Month') {
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      final lastDay = DateTime(now.year, now.month, 0, 23, 59, 59);
      return DateTimeRange(start: prevMonth, end: lastDay);
    } else if (_selectedDashboardPeriod == 'This Year') {
      return DateTimeRange(start: DateTime(now.year, 1, 1), end: DateTime(now.year, 12, 31, 23, 59, 59));
    } else if (_selectedDashboardPeriod == 'Custom' && _customPeriodRange != null) {
      return _customPeriodRange!;
    }
    // Default: 'This Month'
    return DateTimeRange(start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month + 1, 0, 23, 59, 59));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = appState.categories;
    final periodRange = _getPeriodRange();

    // Period Filtered Transactions
    final periodTxs = appState.transactions.where((t) {
      if (t.isTransfer) return false;
      return t.date.isAfter(periodRange.start.subtract(const Duration(seconds: 1))) &&
             t.date.isBefore(periodRange.end.add(const Duration(seconds: 1)));
    }).toList();

    final transactions = periodTxs;

    final now = DateTime.now();
    final threeDaysLimit = DateTime(now.year, now.month, now.day, 23, 59, 59).add(const Duration(days: 3));

    final List<DashboardDueItem> upcomingDueItems = [];

    for (var b in appState.billReminders) {
      if (!b.isPaid && b.dueDate.isBefore(threeDaysLimit)) {
        upcomingDueItems.add(DashboardDueItem.fromBill(b));
      }
    }

    for (var t in appState.transactions) {
      if (t.isRecurring && t.nextRecurringDate != null && t.nextRecurringDate!.isBefore(threeDaysLimit)) {
        upcomingDueItems.add(DashboardDueItem.fromRecurring(t));
      }
    }

    upcomingDueItems.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    double periodIncome = 0.0;
    double periodExpense = 0.0;
    double periodSavings = 0.0;
    for (var tx in periodTxs) {
      if (tx.type == TransactionType.income) periodIncome += tx.amount;
      if (tx.type == TransactionType.expense) {
        periodExpense += tx.amount;
        if (appState.savingsCategoryIds.contains(tx.categoryId)) {
          periodSavings += tx.amount;
        }
      }
    }

    double savings = appState.savingsCategoryIds.isNotEmpty
        ? periodSavings
        : (periodIncome - periodExpense);
    double cashFlow = periodIncome - periodExpense;
    double balance = appState.netBalance;

    // Calculate Category Breakdown for Expenses in Period
    final categoryTotals = _calculateCategoryTotals(periodTxs, categories);
    final totalExpenseForChart = categoryTotals.values.fold<double>(0, (sum, val) => sum + val);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withAlpha((0.2 * 255).toInt()),
                    child: Text(
                      appState.currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                        Text(
                          appState.currentUser?.name ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Accounts & Cards horizontal scroll
              _buildAccountCards(context, appState, isDark),

              _buildUnrecognizedTransactionsSection(context, appState, isDark),

              // Main Balance Card (Net Worth) with Timeframe Selector
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha((0.3 * 255).toInt()),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _showAllAccountsNetWorthSheet(context, appState),
                          child: const Row(
                            children: [
                              Text(
                                "Net Worth Balance",
                                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.info_outline_rounded, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),

                        // Embedded Timeframe Selector Dropdown Pill
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.2 * 255).toInt()),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withAlpha((0.35 * 255).toInt())),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedDashboardPeriod,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                          onSelected: (val) async {
                            if (val == 'Custom') {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (range != null) {
                                setState(() {
                                  _selectedDashboardPeriod = 'Custom';
                                  _customPeriodRange = range;
                                });
                              }
                            } else {
                              setState(() {
                                _selectedDashboardPeriod = val;
                              });
                            }
                          },
                          itemBuilder: (ctx) => [
                            'Today',
                            'This Week',
                            'This Month',
                            'Last Month',
                            'This Year',
                            'Custom',
                          ].map((p) => PopupMenuItem(value: p, child: Text(p))).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _showAllAccountsNetWorthSheet(context, appState),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatter.format(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Period Summary Grid Card (Income, Expense, Savings, Cash Flow)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Summary ($_selectedDashboardPeriod)",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.query_stats_rounded, color: AppTheme.primary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildSummaryGridTile(
                              "Total Income",
                              formatter.format(periodIncome),
                              Icons.arrow_downward,
                              AppTheme.incomeColor,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryGridTile(
                              "Total Expense",
                              formatter.format(periodExpense),
                              Icons.arrow_upward,
                              AppTheme.expenseColor,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildSummaryGridTile(
                              "Savings",
                              formatter.format(savings),
                              Icons.savings_outlined,
                              savings >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryGridTile(
                              "Cash Flow",
                              formatter.format(cashFlow),
                              Icons.swap_vert_rounded,
                              cashFlow >= 0 ? AppTheme.primary : AppTheme.warningColor,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Expense Distribution Chart Section
              if (totalExpenseForChart > 0) ...[
                Text(
                  "Expense Distribution",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 4,
                                centerSpaceRadius: 40,
                                sections: _getPieChartSections(categoryTotals, totalExpenseForChart),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: categoryTotals.keys.map((cat) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Color(cat.colorValue),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.name,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Unified Upcoming Due (Next 3 Days) Section (Bill Reminders + Recurring Transactions)
              if (upcomingDueItems.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Upcoming Due",
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withAlpha((0.15 * 255).toInt()),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Next 3 Days",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${upcomingDueItems.length} Due Soon",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 165,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: upcomingDueItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = upcomingDueItems[index];
                      final cat = appState.categories.firstWhere(
                        (c) => c.id == item.categoryId,
                        orElse: () => CategoryItem(
                          id: 'other',
                          name: 'Other',
                          iconKey: 'other',
                          colorValue: Colors.grey.value,
                          type: TransactionType.expense,
                        ),
                      );
                      final isIncome = item.type == TransactionType.income;
                      final isBill = item.itemType == DueItemType.bill;
                      final daysLeft = item.dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;

                      String dueText = "";
                      Color dueColor = theme.hintColor;
                      if (daysLeft < 0) {
                        dueText = "Overdue by ${-daysLeft}d";
                        dueColor = AppTheme.expenseColor;
                      } else if (daysLeft == 0) {
                        dueText = "Due Today";
                        dueColor = Colors.orange;
                      } else {
                        dueText = "Due in $daysLeft day${daysLeft > 1 ? 's' : ''}";
                        dueColor = AppTheme.primary;
                      }

                      return Container(
                        width: 250,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Color(cat.colorValue).withAlpha((0.15 * 255).toInt()),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    categoryIcons[cat.iconKey] ?? (isBill ? Icons.receipt_long_rounded : Icons.repeat),
                                    size: 14,
                                    color: Color(cat.colorValue),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isBill
                                        ? Colors.amber.withAlpha((0.2 * 255).toInt())
                                        : AppTheme.primary.withAlpha((0.2 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isBill ? "BILL" : "RECURRING",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isBill ? Colors.amber[800] : AppTheme.primary,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                                  onSelected: (val) async {
                                    if (val == 'pay_bill') {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => AddTransactionSheet(
                                          prefilledTitle: item.bill!.title,
                                          prefilledAmount: item.bill!.amount,
                                          prefilledType: TransactionType.expense,
                                          prefilledCategoryId: item.bill!.categoryId,
                                          isTitleAndAmountLocked: true,
                                          billToMarkAsPaid: item.bill,
                                        ),
                                      );
                                    } else if (val == 'run_rec') {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => AddTransactionSheet(
                                          prefilledTitle: item.recurringTx!.title,
                                          prefilledAmount: item.recurringTx!.amount,
                                          prefilledType: item.recurringTx!.type,
                                          prefilledCategoryId: item.recurringTx!.categoryId,
                                          prefilledAccountId: item.recurringTx!.accountId,
                                          prefilledBudgetId: item.recurringTx!.budgetId,
                                          isTitleAndAmountLocked: true,
                                        ),
                                      );
                                    } else if (val == 'snooze_1d' && item.recurringTx != null) {
                                      await appState.snoozeRecurringTransaction(
                                        item.recurringTx!,
                                        item.recurringTx!.nextRecurringDate!.add(const Duration(days: 1)),
                                      );
                                    } else if (val == 'snooze_7d' && item.recurringTx != null) {
                                      await appState.snoozeRecurringTransaction(
                                        item.recurringTx!,
                                        item.recurringTx!.nextRecurringDate!.add(const Duration(days: 7)),
                                      );
                                    } else if (val == 'pause_rec' && item.recurringTx != null) {
                                      await appState.updateTransaction(item.recurringTx!.copyWith(nextRecurringDate: null));
                                    }
                                  },
                                  itemBuilder: (ctx) => isBill
                                      ? [
                                          const PopupMenuItem(
                                            value: 'pay_bill',
                                            child: Row(
                                              children: [
                                                Icon(Icons.check_circle_outline, size: 18),
                                                SizedBox(width: 8),
                                                Text("Mark Paid"),
                                              ],
                                            ),
                                          ),
                                        ]
                                      : [
                                          const PopupMenuItem(
                                            value: 'run_rec',
                                            child: Row(
                                              children: [
                                                Icon(Icons.play_arrow_rounded, size: 18),
                                                SizedBox(width: 8),
                                                Text("Run Now"),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'snooze_1d',
                                            child: Row(
                                              children: [
                                                Icon(Icons.snooze_rounded, size: 18),
                                                SizedBox(width: 8),
                                                Text("Snooze 1 Day"),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'snooze_7d',
                                            child: Row(
                                              children: [
                                                Icon(Icons.event_repeat_rounded, size: 18),
                                                SizedBox(width: 8),
                                                Text("Snooze 1 Week"),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'pause_rec',
                                            child: Row(
                                              children: [
                                                Icon(Icons.pause_rounded, size: 18, color: AppTheme.warningColor),
                                                SizedBox(width: 8),
                                                Text("Pause"),
                                              ],
                                            ),
                                          ),
                                        ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${isIncome ? '+' : '-'}${formatter.format(item.amount)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
                                  ),
                                ),
                                Text(
                                  dueText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: dueColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (isBill)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  minimumSize: const Size(double.infinity, 32),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => AddTransactionSheet(
                                      prefilledTitle: item.bill!.title,
                                      prefilledAmount: item.bill!.amount,
                                      prefilledType: TransactionType.expense,
                                      prefilledCategoryId: item.bill!.categoryId,
                                      isTitleAndAmountLocked: true,
                                      billToMarkAsPaid: item.bill,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 14),
                                label: const Text("Mark Paid"),
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        minimumSize: const Size(0, 32),
                                        side: const BorderSide(color: AppTheme.primary),
                                      ),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => AddTransactionSheet(
                                            prefilledTitle: item.recurringTx!.title,
                                            prefilledAmount: item.recurringTx!.amount,
                                            prefilledType: item.recurringTx!.type,
                                            prefilledCategoryId: item.recurringTx!.categoryId,
                                            prefilledAccountId: item.recurringTx!.accountId,
                                            prefilledBudgetId: item.recurringTx!.budgetId,
                                            isTitleAndAmountLocked: true,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.play_arrow_rounded, size: 14),
                                      label: const Text("Run Now", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    style: IconButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(32, 32),
                                    ),
                                    icon: const Icon(Icons.snooze_rounded, size: 18),
                                    tooltip: "Snooze 1 Day",
                                    onPressed: () async {
                                      await appState.snoozeRecurringTransaction(
                                        item.recurringTx!,
                                        item.recurringTx!.nextRecurringDate!.add(const Duration(days: 1)),
                                      );
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Transactions",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (transactions.isNotEmpty)
                    Text(
                      "Latest ${transactions.length > 5 ? 5 : transactions.length}",
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Recent Transactions List
              if (transactions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: theme.hintColor),
                        const SizedBox(height: 16),
                        Text(
                          "No transactions added yet.",
                          style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length > 5 ? 5 : transactions.length,
                  itemBuilder: (context, index) {
                    final item = transactions[index];
                    final cat = categories.firstWhere(
                      (c) => c.id == item.categoryId,
                      orElse: () => CategoryItem(
                        id: 'other',
                        name: 'Other',
                        iconKey: 'other',
                        colorValue: Colors.grey.value,
                        type: TransactionType.expense,
                      ),
                    );

                    final dateStr = DateFormat('dd MMM yyyy').format(item.date);
                    
                    final acc = appState.accounts.firstWhere(
                      (a) => a.id == item.accountId,
                      orElse: () => AccountItem(
                        id: 'other',
                        name: 'Default Account',
                        type: AccountType.bank,
                        initialBalance: 0,
                        creatorId: '',
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showTransactionDetailsSheet(context, item, appState),
                        borderRadius: BorderRadius.circular(20),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(cat.colorValue).withAlpha((0.12 * 255).toInt()),
                            child: Icon(
                              categoryIcons[cat.iconKey] ?? Icons.more_horiz,
                              color: Color(cat.colorValue),
                            ),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(cat.name, style: TextStyle(fontSize: 11, color: theme.hintColor)),
                                  Text("•", style: TextStyle(fontSize: 11, color: theme.hintColor)),
                                  Text(acc.name, style: TextStyle(fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.w600)),
                                  Text("•", style: TextStyle(fontSize: 11, color: theme.hintColor)),
                                  Text(dateStr, style: TextStyle(fontSize: 11, color: theme.hintColor)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person, size: 11, color: AppTheme.primary.withAlpha((0.7 * 255).toInt())),
                                  const SizedBox(width: 4),
                                  Text(
                                    "By: ${item.creatorName}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primary.withAlpha((0.85 * 255).toInt()),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "${item.type == TransactionType.income ? '+' : '-'}${formatter.format(item.amount)}",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: item.type == TransactionType.income
                                    ? AppTheme.incomeColor
                                    : AppTheme.expenseColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUnrecognizedTransactionsSection(BuildContext context, AppState appState, bool isDark) {
    final list = appState.unrecognizedTransactions;
    if (list.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Pending SMS Alerts",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
            ),
            Text(
              "${list.length} New",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (c, i) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = list[index];
              
              // Try to find matching source account
              AccountItem? matchedAccount;
              if (item.accountLast4 != null && item.accountLast4!.isNotEmpty) {
                for (var acc in appState.accounts) {
                  if (acc.cardLast4.contains(item.accountLast4)) {
                    matchedAccount = acc;
                    break;
                  }
                }
              }

              // Try to find matching destination account
              AccountItem? matchedToAccount;
              if (item.toAccountLast4 != null && item.toAccountLast4!.isNotEmpty) {
                for (var acc in appState.accounts) {
                  if (acc.cardLast4.contains(item.toAccountLast4)) {
                    matchedToAccount = acc;
                    break;
                  }
                }
              }

              final isKnownTransfer = matchedAccount != null && matchedToAccount != null;

              final isIncome = item.type == 'income';
              final cardColor = isDark 
                  ? const Color(0xFF1E293B) 
                  : (isIncome ? Colors.green.shade50 : Colors.orange.shade50);
              final borderColor = isIncome 
                  ? Colors.green.withAlpha((0.3 * 255).toInt())
                  : Colors.orange.withAlpha((0.3 * 255).toInt());

              return Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₹${item.amount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark 
                                ? (isIncome ? Colors.green.shade300 : Colors.orange.shade300) 
                                : (isIncome ? Colors.green.shade900 : Colors.orange.shade900),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isKnownTransfer 
                              ? Colors.blue.withAlpha((0.2 * 255).toInt())
                              : (matchedAccount != null 
                                  ? Colors.green.withAlpha((0.2 * 255).toInt())
                                  : Colors.grey.withAlpha((0.2 * 255).toInt())),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isKnownTransfer) ...[
                                Icon(Icons.swap_horiz, size: 10, color: isDark ? Colors.blue.shade300 : Colors.blue.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  "${matchedAccount.name} ➔ ${matchedToAccount.name}",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  matchedAccount != null ? matchedAccount.name : "Unknown A/c",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: matchedAccount != null ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        item.rawSms,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            appState.deleteUnrecognizedTransaction(item.id);
                          },
                          child: const Text("Discard", style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isIncome ? Colors.green : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (isKnownTransfer) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => AddTransactionSheet(
                                  isTransferMode: true,
                                  prefilledAmount: item.amount,
                                  prefilledAccountId: matchedAccount!.id,
                                  unrecognizedTxIdToDelete: item.id,
                                ),
                              );
                            } else {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => AddTransactionSheet(
                                  prefilledAmount: item.amount,
                                  prefilledAccountId: matchedAccount?.id,
                                  prefilledTitle: isIncome ? "Credit Alert" : "Debit Alert",
                                  prefilledType: isIncome ? TransactionType.income : TransactionType.expense,
                                  unrecognizedTxIdToDelete: item.id,
                                ),
                              );
                            }
                          },
                          child: const Text("Add", style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAccountCards(BuildContext context, AppState appState, bool isDark) {
    final cardFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final accounts = appState.myAccounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Accounts & Cards",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: accounts.length + 1,
            separatorBuilder: (c, i) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == accounts.length) {
                return GestureDetector(
                  onTap: () => _showAddAccountDialog(context, appState),
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface.withAlpha(100) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_card, size: 28, color: AppTheme.primary),
                          SizedBox(height: 8),
                          Text(
                            "Add Account/Card",
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final acc = accounts[index];
              final balance = appState.getAccountBalance(acc);
              final cardColor = acc.colorHex != null 
                  ? Color(int.parse(acc.colorHex!, radix: 16)) 
                  : (acc.type == AccountType.bank ? AppTheme.primary : const Color(0xFF475569));

              return InkWell(
                onTap: () {
                  _showAccountOptionsSheet(context, acc, appState, isDark);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cardColor, cardColor.withAlpha(180)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: cardColor.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              acc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              acc.type == AccountType.bank ? "BANK" : "CARD",
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      const Spacer(),
                      if (acc.type == AccountType.bank) ...[
                        const Text(
                          "Available Balance",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            cardFormatter.format(balance),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "Used Limit",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${cardFormatter.format(balance)} / ${cardFormatter.format(acc.limit ?? 0)}",
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: (acc.limit ?? 0) > 0 ? (balance / acc.limit!) : 0,
                            backgroundColor: Colors.white.withAlpha(50),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 3,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showAddAccountDialog(BuildContext context, AppState appState) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final limitController = TextEditingController();
    final last4Controller = TextEditingController();
    final userEmailController = TextEditingController(text: appState.currentUser?.email ?? '');
    AccountType selectedType = AccountType.bank;
    String selectedCardColor = 'FF1A73E8';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Add Account / Card",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Bank Account")),
                            selected: selectedType == AccountType.bank,
                            onSelected: (val) {
                              if (val) setState(() => selectedType = AccountType.bank);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Credit Card")),
                            selected: selectedType == AccountType.creditCard,
                            onSelected: (val) {
                              if (val) setState(() => selectedType = AccountType.creditCard);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: userEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Linked User Email',
                        hintText: 'e.g. user@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name (e.g. HDFC Savings)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: selectedType == AccountType.bank 
                            ? 'Starting Balance (₹)' 
                            : 'Currently Used Limit (₹)',
                      ),
                    ),
                    if (selectedType == AccountType.creditCard) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: limitController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Total Credit Limit (₹)',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: last4Controller,
                      decoration: const InputDecoration(
                        labelText: 'Last 4 Digits (comma-separated, e.g. 1234, 5678)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Card Theme Color:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _colorBullet(setState, 'FF1A73E8', selectedCardColor, (c) => selectedCardColor = c),
                        _colorBullet(setState, 'FF009688', selectedCardColor, (c) => selectedCardColor = c),
                        _colorBullet(setState, 'FFE65100', selectedCardColor, (c) => selectedCardColor = c),
                        _colorBullet(setState, 'FFD32F2F', selectedCardColor, (c) => selectedCardColor = c),
                        _colorBullet(setState, 'FF5E35B1', selectedCardColor, (c) => selectedCardColor = c),
                        _colorBullet(setState, 'FF37474F', selectedCardColor, (c) => selectedCardColor = c),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;
                        final limit = selectedType == AccountType.creditCard 
                            ? (double.tryParse(limitController.text.trim()) ?? 10000.0) 
                            : null;
                        final last4Text = last4Controller.text.trim();
                        final last4List = last4Text.isNotEmpty
                            ? last4Text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                            : <String>[];

                        if (name.isNotEmpty) {
                          appState.addAccount(
                            name, 
                            selectedType, 
                            balance, 
                            limit: limit, 
                            userEmail: userEmailController.text.trim(),
                            colorHex: selectedCardColor,
                            cardLast4: last4List,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Create Account"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _colorBullet(void Function(void Function()) setState, String colorHex, String selectedColorHex, Function(String) updateSelected) {
    final color = Color(int.parse(colorHex, radix: 16));
    final isSelected = colorHex == selectedColorHex;
    return GestureDetector(
      onTap: () {
        setState(() {
          updateSelected(colorHex);
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected 
              ? Border.all(color: Colors.white, width: 3) 
              : null,
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))] : null,
        ),
      ),
    );
  }

  void _showRecurringBillDetailsSheet(BuildContext context, TransactionItem bill, AppState appState, List<CategoryItem> categories, bool isDark) {
    final theme = Theme.of(context);
    final cat = categories.firstWhere(
      (c) => c.id == bill.categoryId,
      orElse: () => CategoryItem(
        id: 'other',
        name: 'Other',
        iconKey: 'other',
        colorValue: Colors.grey.value,
        type: TransactionType.expense,
      ),
    );

    final daysLeft = bill.nextRecurringDate != null
        ? bill.nextRecurringDate!.difference(DateTime.now()).inDays
        : 0;

    final account = appState.accounts.firstWhere(
      (acc) => acc.id == bill.accountId,
      orElse: () => AccountItem(
        id: 'unknown',
        name: 'Default cash',
        type: AccountType.bank,
        initialBalance: 0,
        creatorId: '',
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Upcoming Bill Payment",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Color(cat.colorValue).withAlpha(30),
                  child: Icon(categoryIcons[cat.iconKey] ?? Icons.more_horiz, color: Color(cat.colorValue)),
                ),
                title: Text(bill.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(
                  daysLeft <= 0 ? "Due today" : "Due in $daysLeft days (${DateFormat('dd MMM yyyy').format(bill.nextRecurringDate!)})",
                  style: TextStyle(color: daysLeft <= 0 ? AppTheme.expenseColor : theme.hintColor),
                ),
                trailing: Text(
                  formatter.format(bill.amount),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.expenseColor),
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Payment Method / Account:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(account.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.snooze),
                      label: const Text("Snooze / Postpone"),
                      onPressed: () async {
                        Navigator.pop(context);
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: bill.nextRecurringDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          await appState.snoozeRecurringTransaction(bill, picked);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Snoozed bill '${bill.title}' until ${DateFormat('dd MMM').format(picked)}"),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.incomeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Mark Paid"),
                      onPressed: () async {
                        Navigator.pop(context);
                        await appState.addTransaction(
                          "${bill.title} (Paid)",
                          bill.amount,
                          DateTime.now(),
                          bill.categoryId,
                          TransactionType.expense,
                          bill.accountId,
                        );
                        final nextDate = appState.calculateNextRecurringDateFromAnchor(
                          bill.nextRecurringDate ?? DateTime.now(),
                          bill.date,
                          bill.recurrenceInterval,
                        );
                        await appState.updateTransaction(bill.copyWith(nextRecurringDate: nextDate));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Recorded payment for '${bill.title}'")),
                          );
                        }
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _showAccountOptionsSheet(BuildContext context, AccountItem acc, AppState appState, bool isDark) {
    final theme = Theme.of(context);
    final balance = appState.getAccountBalance(acc);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    acc.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(height: 24),
              if (acc.type == AccountType.bank) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Available Balance:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(formatter.format(balance), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.incomeColor)),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Credit Limit:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(formatter.format(acc.limit ?? 0), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Currently Used Limit (Balance due):", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(
                      formatter.format(balance),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.expenseColor),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              if (acc.type == AccountType.creditCard) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.payment),
                  label: const Text("Repay Card Bill"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showRepayCreditCardSheet(context, acc, balance, appState);
                  },
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text("Edit Account/Card"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showEditAccountDialog(context, acc, appState);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: AppTheme.expenseColor),
                label: const Text("Delete Account/Card", style: TextStyle(color: AppTheme.expenseColor)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.expenseColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
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
                    await appState.deleteAccount(acc.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditAccountDialog(BuildContext context, AccountItem acc, AppState appState) {
    final nameController = TextEditingController(text: acc.name);
    final balanceController = TextEditingController(text: acc.initialBalance.toString());
    final limitController = TextEditingController(text: acc.limit?.toString() ?? '');
    final last4Controller = TextEditingController(text: acc.cardLast4.join(', '));
    final userEmailController = TextEditingController(text: acc.userEmail ?? appState.currentUser?.email ?? '');
    AccountType selectedType = acc.type;
    String selectedCardColor = acc.colorHex ?? 'FF1A73E8';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Edit Account / Card",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Bank Account")),
                            selected: selectedType == AccountType.bank,
                            onSelected: (val) {
                              if (val) setState(() => selectedType = AccountType.bank);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Credit Card")),
                            selected: selectedType == AccountType.creditCard,
                            onSelected: (val) {
                              if (val) setState(() => selectedType = AccountType.creditCard);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: userEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Linked User Email',
                        hintText: 'e.g. user@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name (e.g. HDFC Savings)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: selectedType == AccountType.bank 
                            ? 'Starting Balance (₹)' 
                            : 'Currently Used Limit (₹)',
                      ),
                    ),
                    if (selectedType == AccountType.creditCard) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: limitController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Total Credit Limit (₹)',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: last4Controller,
                      decoration: const InputDecoration(
                        labelText: 'Last 4 Digits (comma-separated, e.g. 1234, 5678)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Card Theme Color:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _colorBullet(setState, 'FF1A73E8', selectedCardColor, (c) => selectedCardColor = c),
                        _colorBullet(setState, 'FF009688', selectedCardColor, (c) => selectedCardColor = c),
                        _colorBullet(setState, 'FFE65100', selectedCardColor, (c) => selectedCardColor = c),
                        _colorBullet(setState, 'FFD32F2F', selectedCardColor, (c) => selectedCardColor = c),
                        _colorBullet(setState, 'FF5E35B1', selectedCardColor, (c) => selectedCardColor = c),
                        _colorBullet(setState, 'FF37474F', selectedCardColor, (c) => selectedCardColor = c),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;
                        final limit = selectedType == AccountType.creditCard 
                            ? (double.tryParse(limitController.text.trim()) ?? 10000.0) 
                            : null;
                        final last4Text = last4Controller.text.trim();
                        final last4List = last4Text.isNotEmpty
                            ? last4Text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                            : <String>[];

                        if (name.isNotEmpty) {
                          final updatedAccount = acc.copyWith(
                            name: name,
                            type: selectedType,
                            initialBalance: balance,
                            limit: limit,
                            userEmail: userEmailController.text.trim(),
                            colorHex: selectedCardColor,
                            cardLast4: last4List,
                          );
                          await appState.updateAccount(updatedAccount);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRepayCreditCardSheet(BuildContext context, AccountItem cc, double usedLimit, AppState appState) {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: usedLimit.toString());
    String? selectedBankId;

    final banks = appState.accounts.where((a) => a.type == AccountType.bank).toList();
    if (banks.isNotEmpty) {
      selectedBankId = banks.first.id;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Repay Bill - ${cc.name}",
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                amountController.text = usedLimit.toString();
                              });
                            },
                            child: const Text("Repay Full (Close)"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                amountController.text = '';
                              });
                            },
                            child: const Text("Custom Amount"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Repayment Amount (₹)",
                        hintText: "Enter amount",
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Amount is required";
                        final numVal = double.tryParse(val.trim());
                        if (numVal == null || numVal <= 0) return "Please enter a valid positive number";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AccountSelectorField(
                      label: "Pay From Account",
                      selectedAccount: banks.any((b) => b.id == selectedBankId)
                          ? banks.firstWhere((b) => b.id == selectedBankId)
                          : (banks.isNotEmpty ? banks.first : null),
                      availableAccounts: banks,
                      appState: appState,
                      onAccountSelected: (acc) {
                        setState(() => selectedBankId = acc?.id);
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: banks.isEmpty
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final amount = double.parse(amountController.text.trim());
                              final bankId = selectedBankId!;

                              await appState.addTransaction(
                                "Repaid ${cc.name} Bill",
                                amount,
                                DateTime.now(),
                                'credit_card_payment',
                                TransactionType.expense,
                                bankId,
                                toAccountId: cc.id,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Successfully repaid ${formatter.format(amount)} to ${cc.name}"),
                                  ),
                                );
                              }
                            },
                      child: const Text("Confirm Repayment"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildSummaryGridTile(
    String label,
    String amount,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }

  Map<CategoryItem, double> _calculateCategoryTotals(
      List<TransactionItem> list, List<CategoryItem> cats) {
    final Map<CategoryItem, double> totals = {};
    for (var t in list) {
      if (t.type == TransactionType.expense) {
        final cat = cats.firstWhere(
          (c) => c.id == t.categoryId,
          orElse: () => CategoryItem(
            id: 'other',
            name: 'Other',
            iconKey: 'other',
            colorValue: Colors.grey.value,
            type: TransactionType.expense,
          ),
        );
        totals[cat] = (totals[cat] ?? 0.0) + t.amount;
      }
    }
    return totals;
  }

  List<PieChartSectionData> _getPieChartSections(
      Map<CategoryItem, double> totals, double totalSum) {
    int index = 0;
    return totals.entries.map((entry) {
      final cat = entry.key;
      final value = entry.value;
      final isTouched = index == _touchedIndex;
      index++;

      final double fontSize = isTouched ? 16.0 : 12.0;
      final double radius = isTouched ? 55.0 : 45.0;
      final pct = (value / totalSum * 100).toStringAsFixed(0);

      return PieChartSectionData(
        color: Color(cat.colorValue),
        value: value,
        title: isTouched ? "₹${value.toStringAsFixed(0)}" : "$pct%",
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black38, blurRadius: 2)],
        ),
      );
    }).toList();
  }

  void _showAllAccountsNetWorthSheet(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final netFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final cardFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "All Accounts & Net Worth",
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Total Net Worth: ${netFormatter.format(appState.netBalance)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: appState.accounts.isEmpty
                    ? Center(
                        child: Text(
                          "No accounts created yet.",
                          style: TextStyle(color: theme.hintColor),
                        ),
                      )
                    : ListView.separated(
                        itemCount: appState.accounts.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final acc = appState.accounts[index];
                          final balance = appState.getAccountBalance(acc);
                          final isCc = acc.type == AccountType.creditCard;
                          final displayBalance = isCc ? ((acc.limit ?? 0.0) - balance) : balance;
                          final cardColor = acc.colorHex != null
                              ? Color(int.parse(acc.colorHex!, radix: 16))
                              : (isCc ? const Color(0xFF475569) : AppTheme.primary);
                          final ownerEmail = (acc.userEmail != null && acc.userEmail!.isNotEmpty) 
                              ? acc.userEmail! 
                              : (appState.currentUser?.email ?? 'Unspecified');

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: cardColor.withAlpha(40),
                                  child: Icon(
                                    isCc ? Icons.credit_card : Icons.account_balance,
                                    color: cardColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              acc.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isCc ? Colors.purple : Colors.blue).withAlpha(40),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isCc ? "CARD" : "BANK",
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isCc ? Colors.purple : Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Linked User: $ownerEmail",
                                        style: TextStyle(fontSize: 11, color: theme.hintColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isCc
                                            ? "Avail Limit: ${cardFormatter.format(displayBalance)}"
                                            : "Balance: ${cardFormatter.format(displayBalance)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showEditAccountDialog(context, acc, appState);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
