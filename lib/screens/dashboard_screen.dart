import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/theme.dart';

import 'transactions_screen.dart'; // import to reuse AddTransactionSheet
import 'transfers_screen.dart';

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
    const MethodChannel('com.family.spendwise/sms').invokeMethod('requestPermissions').catchError((_) => null);
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final transactions = appState.transactions.where((t) => !t.isTransfer).toList();
    final categories = appState.categories;

    // Use AppState Dynamic Calculations
    double totalIncome = appState.totalIncome;
    double totalExpense = appState.totalExpense;
    double balance = appState.netBalance;

    // Calculate Category Breakdown for Expenses
    final categoryTotals = _calculateCategoryTotals(transactions, categories);
    final totalExpenseForChart = categoryTotals.values.fold<double>(0, (sum, val) => sum + val);

    // Filter Recurring Transactions
    final recurringTransactions = transactions.where((t) => t.isRecurring).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Stream notifies automatically
        },
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

              // Main Balance Card
              Container(
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Net Worth Balance",
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Total Income", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        formatter.format(totalIncome),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1.5, height: 40, color: Colors.white24),
                        Expanded(
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Total Expense", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        formatter.format(totalExpense),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Expense Distribution Chart Section
              if (totalExpenseForChart > 0) ...[
                Text(
                  "Expense Distribution",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        SizedBox(
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
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
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
                const SizedBox(height: 32),
              ],

              // Recurring Expenses Section
              if (recurringTransactions.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Upcoming Recurring Bills",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${recurringTransactions.length} Active",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 135,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recurringTransactions.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = recurringTransactions[index];
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

                      final daysLeft = item.nextRecurringDate != null
                          ? item.nextRecurringDate!.difference(DateTime.now()).inDays
                          : 0;

                      return InkWell(
                        onTap: () => _showRecurringBillDetailsSheet(context, item, appState, categories, isDark),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 170,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Color(cat.colorValue).withAlpha((0.15 * 255).toInt()),
                                    child: Icon(
                                      categoryIcons[cat.iconKey] ?? Icons.more_horiz,
                                      size: 12,
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
                                ],
                              ),
                              const Spacer(),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  formatter.format(item.amount),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                daysLeft <= 0 ? "Due today" : "Due in $daysLeft days",
                                style: TextStyle(
                                  color: daysLeft <= 0 ? AppTheme.expenseColor : theme.hintColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
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
              const SizedBox(height: 40),
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

              return Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withAlpha((0.3 * 255).toInt()),
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
                            color: isDark ? Colors.orange.shade300 : Colors.orange.shade900,
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
                            backgroundColor: Colors.orange,
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
                                builder: (context) => AddTransferSheet(
                                  prefilledAmount: item.amount,
                                  prefilledFromAccountId: matchedAccount!.id,
                                  prefilledToAccountId: matchedToAccount!.id,
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
                                  prefilledTitle: "Debit Alert",
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
    final accounts = appState.accounts;

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
                    if (banks.isEmpty)
                      const Text(
                        "No bank accounts found! Please add a bank account first.",
                        style: TextStyle(color: AppTheme.expenseColor, fontSize: 13),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedBankId,
                        decoration: const InputDecoration(
                          labelText: "Select Bank Account to Pay From",
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        items: banks.map((b) {
                          final balance = appState.getAccountBalance(b);
                          return DropdownMenuItem(
                            value: b.id,
                            child: Text("${b.name} (${formatter.format(balance)})"),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => selectedBankId = val);
                        },
                        validator: (val) => val == null ? "Bank account is required" : null,
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
}
