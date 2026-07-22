import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/theme.dart';
import '../widgets/category_selector.dart';
import '../widgets/account_selector.dart';
import '../widgets/budget_selector.dart';
import 'transactions_screen.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  final _currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final _dateFormatter = DateFormat('dd MMM yyyy');

  String _formatIntervalName(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final recurringTxList = appState.transactions.where((tx) => tx.isRecurring).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recurring Transactions"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecurringModal(context, appState),
        tooltip: "Add Recurring Transaction",
        child: const Icon(Icons.add_rounded),
      ),
      body: recurringTxList.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      size: 64,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Recurring Transactions",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Schedule automated income or expense tracking with flexible recurrence frequencies.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRecurringModal(context, appState),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text("Add Recurring Transaction"),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: recurringTxList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = recurringTxList[index];
                final category = appState.categories.firstWhere(
                  (c) => c.id == tx.categoryId,
                  orElse: () => CategoryItem(
                    id: 'other',
                    name: 'Other',
                    iconKey: 'other',
                    colorValue: Colors.grey.value,
                    type: TransactionType.expense,
                  ),
                );
                final account = appState.accounts.firstWhere(
                  (a) => a.id == tx.accountId,
                  orElse: () => AccountItem(
                    id: 'default_bank',
                    name: 'Bank',
                    type: AccountType.bank,
                    initialBalance: 0,
                    creatorId: '',
                  ),
                );
                final iconData = categoryIcons[category.iconKey] ?? Icons.repeat;
                final isIncome = tx.type == TransactionType.income;
                final isPaused = tx.nextRecurringDate == null;

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Category Icon + Title/Subtitles + Amount & Status Pill
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(category.colorValue).withAlpha((0.15 * 255).toInt()),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              size: 20,
                              color: Color(category.colorValue),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${category.name} • ${account.name} • ${_formatIntervalName(tx.recurrenceInterval.name)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${isIncome ? '+' : '-'}${_currencyFormatter.format(tx.amount)}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPaused
                                      ? AppTheme.warningColor.withAlpha((0.15 * 255).toInt())
                                      : AppTheme.incomeColor.withAlpha((0.15 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isPaused ? "Paused" : "Active",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPaused ? AppTheme.warningColor : AppTheme.incomeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Bottom Row: Date info & Quick action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 13,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tx.nextRecurringDate != null
                                        ? "Next: ${_dateFormatter.format(tx.nextRecurringDate!)}"
                                        : "Next: Paused",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (tx.recurringEndDate != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "Ends: ${_dateFormatter.format(tx.recurringEndDate!)}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              // Run Now
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: const Size(0, 32),
                                  side: const BorderSide(color: AppTheme.primary),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => AddTransactionSheet(
                                      prefilledTitle: tx.title,
                                      prefilledAmount: tx.amount,
                                      prefilledType: tx.type,
                                      prefilledCategoryId: tx.categoryId,
                                      prefilledAccountId: tx.accountId,
                                      prefilledBudgetId: tx.budgetId,
                                      isTitleAndAmountLocked: true,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow_rounded, size: 15),
                                label: const Text("Run Now", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 6),

                              // Pause/Resume Icon Button
                              IconButton(
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(32, 32),
                                ),
                                icon: Icon(
                                  isPaused ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                                  size: 20,
                                  color: isPaused ? AppTheme.incomeColor : AppTheme.warningColor,
                                ),
                                tooltip: isPaused ? "Resume" : "Pause",
                                onPressed: () async {
                                  if (isPaused) {
                                    final next = appState.calculateNextRecurringDateFromAnchor(
                                      DateTime.now(),
                                      tx.date,
                                      tx.recurrenceInterval,
                                    );
                                    await appState.updateTransaction(tx.copyWith(nextRecurringDate: next));
                                  } else {
                                    await appState.updateTransaction(tx.copyWith(nextRecurringDate: null));
                                  }
                                },
                              ),

                              // Delete Icon Button
                              IconButton(
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(32, 32),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.expenseColor, size: 20),
                                tooltip: "Delete",
                                onPressed: () async {
                                  await appState.deleteTransaction(tx.id);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showAddRecurringModal(BuildContext context, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    TransactionType selectedType = TransactionType.expense;
    String selectedCategoryId = appState.categories.isNotEmpty ? appState.categories.first.id : 'other';
    String selectedAccountId = appState.myAccounts.isNotEmpty ? appState.myAccounts.first.id : 'default_bank';
    RecurrenceInterval selectedInterval = RecurrenceInterval.monthly;
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    String? selectedBudgetId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Add Recurring Transaction",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Transaction Type Toggle (Expense / Income)
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Expense", style: TextStyle(fontWeight: FontWeight.bold))),
                            selected: selectedType == TransactionType.expense,
                            selectedColor: AppTheme.expenseColor.withOpacity(0.2),
                            side: BorderSide(
                              color: selectedType == TransactionType.expense ? AppTheme.expenseColor : Colors.transparent,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedType = TransactionType.expense;
                                  final expCats = appState.categories.where((c) => c.type == TransactionType.expense).toList();
                                  if (expCats.isNotEmpty) selectedCategoryId = expCats.first.id;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Income", style: TextStyle(fontWeight: FontWeight.bold))),
                            selected: selectedType == TransactionType.income,
                            selectedColor: AppTheme.incomeColor.withOpacity(0.2),
                            side: BorderSide(
                              color: selectedType == TransactionType.income ? AppTheme.incomeColor : Colors.transparent,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedType = TransactionType.income;
                                  final incCats = appState.categories.where((c) => c.type == TransactionType.income).toList();
                                  if (incCats.isNotEmpty) selectedCategoryId = incCats.first.id;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title Field
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Transaction Title",
                        hintText: "e.g. Netflix Subscription, House Rent, Salary",
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Amount",
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Selector
                    CategorySelectorField(
                      label: "Category",
                      selectedCategory: appState.categories.any((c) => c.id == selectedCategoryId)
                          ? appState.categories.firstWhere((c) => c.id == selectedCategoryId)
                          : null,
                      availableCategories: appState.categories.where((c) => c.type == selectedType || c.id == 'other').toList(),
                      onCategorySelected: (cat) {
                        if (cat != null) setModalState(() => selectedCategoryId = cat.id);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Account Selector
                    AccountSelectorField(
                      label: "Payment Account",
                      selectedAccount: appState.myAccounts.any((a) => a.id == selectedAccountId)
                          ? appState.myAccounts.firstWhere((a) => a.id == selectedAccountId)
                          : (appState.myAccounts.isNotEmpty ? appState.myAccounts.first : null),
                      availableAccounts: appState.myAccounts,
                      appState: appState,
                      onAccountSelected: (acc) {
                        if (acc != null) setModalState(() => selectedAccountId = acc.id);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Recurrence Frequency Field
                    InkWell(
                      onTap: () {
                        _showIntervalSelectorSheet(
                          context: context,
                          selectedInterval: selectedInterval,
                          onIntervalSelected: (interval) => setModalState(() => selectedInterval = interval),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.repeat_rounded, color: AppTheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Recurrence Frequency",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatIntervalName(selectedInterval.name),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Start Date & Optional End Date Row
                    Row(
                      children: [
                        // Start Date Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setModalState(() => startDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text("Start: ${_dateFormatter.format(startDate)}"),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Optional End Date Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? startDate.add(const Duration(days: 30)),
                                firstDate: startDate,
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                            icon: const Icon(Icons.event_busy_rounded, size: 16),
                            label: Text(
                              endDate != null
                                  ? "Ends: ${_dateFormatter.format(endDate!)}"
                                  : "End Date (Optional)",
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (endDate != null) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setModalState(() => endDate = null),
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          label: const Text("Clear End Date"),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Link to Budget (Optional)
                    if (selectedType == TransactionType.expense) ...[
                      BudgetSelectorField(
                        label: "Link to Budget (Optional)",
                        selectedBudget: appState.budgets.any((b) => b.id == selectedBudgetId)
                            ? appState.budgets.firstWhere((b) => b.id == selectedBudgetId)
                            : null,
                        availableBudgets: appState.budgets,
                        appState: appState,
                        allowAllOption: true,
                        allOptionLabel: "None",
                        placeholder: "Select Budget",
                        onBudgetSelected: (b) {
                          setModalState(() => selectedBudgetId = b?.id);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Notes Field (Optional)
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: "Notes (Optional)",
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final amount = double.tryParse(amountController.text.trim());

                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter a transaction title")),
                          );
                          return;
                        }

                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter a valid amount")),
                          );
                          return;
                        }

                        await appState.addTransaction(
                          title,
                          amount,
                          startDate,
                          selectedCategoryId,
                          selectedType,
                          selectedAccountId,
                          isRecurring: true,
                          recurrenceInterval: selectedInterval,
                          recurringEndDate: endDate,
                          notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                          budgetId: selectedBudgetId,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Recurring transaction scheduled successfully!")),
                          );
                        }
                      },
                      child: const Text("Schedule Recurring Transaction"),
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

  void _showIntervalSelectorSheet({
    required BuildContext context,
    required RecurrenceInterval selectedInterval,
    required ValueChanged<RecurrenceInterval> onIntervalSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final intervals = [
      RecurrenceInterval.daily,
      RecurrenceInterval.weekly,
      RecurrenceInterval.monthly,
      RecurrenceInterval.yearly,
    ];

    String formatName(RecurrenceInterval interval) {
      switch (interval) {
        case RecurrenceInterval.daily:
          return "Daily (Every day)";
        case RecurrenceInterval.weekly:
          return "Weekly (Every week)";
        case RecurrenceInterval.monthly:
          return "Monthly (Every month)";
        case RecurrenceInterval.yearly:
          return "Yearly (Every year)";
        default:
          return interval.name;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Select Recurrence Frequency",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...intervals.map((interval) {
                final isSelected = selectedInterval == interval;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withOpacity(0.12)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        formatName(interval),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
                      onTap: () {
                        onIntervalSelected(interval);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
