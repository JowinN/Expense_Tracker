import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/account_selector.dart';
import '../widgets/category_selector.dart';
import '../widgets/budget_selector.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  List<String> _selectedCategoryIds = [];
  String _selectedTypeFilter = 'all'; // all, income, expense, transfer
  DateTimeRange? _selectedDateRange;

  String? _selectedAccountIdFilter;
  String? _selectedUserFilter;
  String? _selectedBudgetIdFilter;
  double? _minAmountFilter;
  double? _maxAmountFilter;

  final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  void _showAddTransactionSheet(BuildContext context, {bool isTransfer = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(isTransferMode: isTransfer),
    );
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
            name: tx.isTransfer ? 'Transfer' : 'Other',
            iconKey: tx.isTransfer ? 'transfer' : 'other',
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
                  name: 'Destination Account',
                  type: AccountType.bank,
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
                  Text(
                    tx.isTransfer ? "Transfer Details" : "Transaction Details",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
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
                  backgroundColor: (tx.isTransfer ? AppTheme.primary : Color(cat.colorValue)).withAlpha(30),
                  child: Icon(
                    tx.isTransfer ? Icons.swap_horiz : (categoryIcons[cat.iconKey] ?? Icons.more_horiz),
                    color: tx.isTransfer ? AppTheme.primary : Color(cat.colorValue),
                  ),
                ),
                title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(dateStr, style: TextStyle(color: theme.hintColor)),
                trailing: Text(
                  "${tx.isTransfer ? '' : (tx.type == TransactionType.income ? '+' : '-')}${formatter.format(tx.amount)}",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: tx.isTransfer
                        ? AppTheme.primary
                        : (tx.type == TransactionType.income ? AppTheme.incomeColor : AppTheme.expenseColor),
                  ),
                ),
              ),
              const Divider(height: 24),
              if (tx.isTransfer) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("From Account:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(acc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("To Account:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(toAcc?.name ?? 'None', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ] else ...[
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
              ],
              if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Notes:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Text(
                        tx.notes!,
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 13, color: theme.hintColor),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Created By:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text("${tx.creatorName} (${tx.creatorEmail})", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.expenseColor),
                      label: const Text("Delete", style: TextStyle(color: AppTheme.expenseColor)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Delete Item?"),
                            content: const Text("Are you sure you want to delete this record?"),
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
                          await appState.deleteTransaction(tx.id);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
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
      builder: (context) => AddTransactionSheet(editingTransaction: tx, isTransferMode: tx.isTransfer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredTransactions = appState.transactions.where((t) {
      // 1. Type Filter (Notice: 'all' intentionally excludes transfers to keep financial reports clean!)
      if (_selectedTypeFilter == 'all') {
        if (t.isTransfer) return false;
      } else if (_selectedTypeFilter == 'income') {
        if (t.isTransfer || t.type != TransactionType.income) return false;
      } else if (_selectedTypeFilter == 'expense') {
        if (t.isTransfer || t.type != TransactionType.expense) return false;
      } else if (_selectedTypeFilter == 'transfer') {
        if (!t.isTransfer) return false;
      }

      // 2. Account Filter
      if (_selectedAccountIdFilter != null) {
        if (t.accountId != _selectedAccountIdFilter && t.toAccountId != _selectedAccountIdFilter) {
          return false;
        }
      }

      // 3. User Filter
      if (_selectedUserFilter != null) {
        if (t.creatorId != _selectedUserFilter && t.creatorEmail != _selectedUserFilter) {
          return false;
        }
      }

      // 4. Category Filter
      if (_selectedCategoryIds.isNotEmpty && !t.isTransfer) {
        if (!_selectedCategoryIds.contains(t.categoryId)) return false;
      }

      // 5. Budget Filter
      if (_selectedBudgetIdFilter != null) {
        if (t.budgetId != _selectedBudgetIdFilter) return false;
      }

      // 6. Amount Range Filter
      if (_minAmountFilter != null && t.amount < _minAmountFilter!) return false;
      if (_maxAmountFilter != null && t.amount > _maxAmountFilter!) return false;

      // 7. Date Range Filter
      if (_selectedDateRange != null) {
        if (t.date.isBefore(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) ||
            t.date.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // 8. Extended Search Matching (Title, Notes, Category, Budget, Account, User)
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final cat = appState.categories.firstWhere((c) => c.id == t.categoryId, orElse: () => CategoryItem(id: '', name: '', iconKey: '', colorValue: 0, type: TransactionType.expense));
        final acc = appState.accounts.firstWhere((a) => a.id == t.accountId, orElse: () => AccountItem(id: '', name: '', type: AccountType.bank, initialBalance: 0, creatorId: ''));
        final toAcc = t.toAccountId != null ? appState.accounts.firstWhere((a) => a.id == t.toAccountId, orElse: () => AccountItem(id: '', name: '', type: AccountType.bank, initialBalance: 0, creatorId: '')) : null;
        final budget = appState.budgets.firstWhere((b) => b.id == t.budgetId, orElse: () => BudgetItem(id: '', name: '', amount: 0, iconKey: '', colorValue: 0, period: BudgetPeriod.monthly, startDate: DateTime.now(), endDate: DateTime.now(), categoryIds: [], creatorId: ''));

        final matchesTitle = t.title.toLowerCase().contains(query);
        final matchesNotes = (t.notes ?? '').toLowerCase().contains(query);
        final matchesCat = cat.name.toLowerCase().contains(query);
        final matchesAcc = acc.name.toLowerCase().contains(query) || (toAcc?.name.toLowerCase().contains(query) ?? false);
        final matchesBudget = budget.name.toLowerCase().contains(query);
        final matchesUser = t.creatorName.toLowerCase().contains(query) || t.creatorEmail.toLowerCase().contains(query);

        if (!matchesTitle && !matchesNotes && !matchesCat && !matchesAcc && !matchesBudget && !matchesUser) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),
      ),
      body: Column(
        children: [
          // Filter Bar Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            child: Column(
              children: [
                // Search Bar + Filter Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "Search title, notes, account, user...",
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: (_selectedAccountIdFilter != null || _selectedUserFilter != null || _selectedBudgetIdFilter != null || _minAmountFilter != null)
                              ? AppTheme.primary
                              : theme.hintColor,
                        ),
                        tooltip: "More Filters",
                        onPressed: () => _showFilterBottomSheet(context, appState),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Primary Filter Controls (Type + Category)
                Row(
                  children: [
                    // Type Filter Dropdown
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTypeFilter,
                            dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            icon: Icon(Icons.arrow_drop_down, color: theme.hintColor),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Types', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                              DropdownMenuItem(
                                value: 'income',
                                child: Text('Income', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.incomeColor)),
                              ),
                              DropdownMenuItem(
                                value: 'expense',
                                child: Text('Expense', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.expenseColor)),
                              ),
                              DropdownMenuItem(
                                value: 'transfer',
                                child: Text('Transfer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedTypeFilter = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Quick Date Preset Chip
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _selectedDateRange == null ? "Date" : "Filtered Date",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _showDatePresetPicker(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transactions & Transfers List
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 56, color: theme.hintColor),
                        const SizedBox(height: 16),
                        Text(
                          "No matching records found.",
                          style: TextStyle(color: theme.hintColor, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredTransactions[index];
                      final cat = appState.categories.firstWhere(
                        (c) => c.id == item.categoryId,
                        orElse: () => CategoryItem(
                          id: 'other',
                          name: item.isTransfer ? 'Transfer' : 'Other',
                          iconKey: item.isTransfer ? 'transfer' : 'other',
                          colorValue: Colors.grey.value,
                          type: TransactionType.expense,
                        ),
                      );

                      final dateStr = DateFormat('dd MMM yyyy').format(item.date);
                      final acc = appState.accounts.firstWhere(
                        (a) => a.id == item.accountId,
                        orElse: () => AccountItem(
                          id: 'other',
                          name: 'Default Bank',
                          type: AccountType.bank,
                          initialBalance: 0,
                          creatorId: '',
                        ),
                      );
                      final toAcc = item.toAccountId != null
                          ? appState.accounts.firstWhere(
                              (a) => a.id == item.toAccountId,
                              orElse: () => AccountItem(
                                id: 'other',
                                name: 'Target Bank',
                                type: AccountType.bank,
                                initialBalance: 0,
                                creatorId: '',
                              ),
                            )
                          : null;

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          decoration: BoxDecoration(
                            color: AppTheme.expenseColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          appState.deleteTransaction(item.id);
                        },
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () => _showTransactionDetailsSheet(context, item, appState),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: (item.isTransfer ? AppTheme.primary : Color(cat.colorValue)).withAlpha((0.15 * 255).toInt()),
                                    child: Icon(
                                      item.isTransfer ? Icons.swap_horiz : (categoryIcons[cat.iconKey] ?? Icons.more_horiz),
                                      color: item.isTransfer ? AppTheme.primary : Color(cat.colorValue),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.isTransfer
                                              ? "${acc.name} ➔ ${toAcc?.name ?? ''} • $dateStr"
                                              : "${cat.name} • ${acc.name} • $dateStr",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, color: theme.hintColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "${item.isTransfer ? '' : (item.type == TransactionType.income ? '+' : '-')}${formatter.format(item.amount)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: item.isTransfer
                                          ? AppTheme.primary
                                          : (item.type == TransactionType.income ? AppTheme.incomeColor : AppTheme.expenseColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDatePresetPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    "Filter by Date",
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
              const SizedBox(height: 12),
              _buildDateTile(context, "Today", Icons.today_rounded, () {
                final now = DateTime.now();
                setState(() => _selectedDateRange = DateTimeRange(start: DateTime(now.year, now.month, now.day), end: DateTime(now.year, now.month, now.day, 23, 59)));
                Navigator.pop(context);
              }),
              const SizedBox(height: 8),
              _buildDateTile(context, "Yesterday", Icons.history_toggle_off_rounded, () {
                final yest = DateTime.now().subtract(const Duration(days: 1));
                setState(() => _selectedDateRange = DateTimeRange(start: DateTime(yest.year, yest.month, yest.day), end: DateTime(yest.year, yest.month, yest.day, 23, 59)));
                Navigator.pop(context);
              }),
              const SizedBox(height: 8),
              _buildDateTile(context, "This Week", Icons.calendar_view_week_rounded, () {
                final now = DateTime.now();
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                setState(() => _selectedDateRange = DateTimeRange(start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day), end: now));
                Navigator.pop(context);
              }),
              const SizedBox(height: 8),
              _buildDateTile(context, "This Month", Icons.calendar_month_rounded, () {
                final now = DateTime.now();
                setState(() => _selectedDateRange = DateTimeRange(start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month + 1, 0)));
                Navigator.pop(context);
              }),
              const SizedBox(height: 8),
              _buildDateTile(context, "This Year", Icons.date_range_rounded, () {
                final now = DateTime.now();
                setState(() => _selectedDateRange = DateTimeRange(start: DateTime(now.year, 1, 1), end: DateTime(now.year, 12, 31)));
                Navigator.pop(context);
              }),
              const SizedBox(height: 8),
              _buildDateTile(context, "Custom Range...", Icons.edit_calendar_rounded, () async {
                Navigator.pop(context);
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: _selectedDateRange,
                );
                if (picked != null) {
                  setState(() => _selectedDateRange = picked);
                }
              }),
              if (_selectedDateRange != null) ...[
                const SizedBox(height: 8),
                _buildDateTile(context, "Clear Date Filter", Icons.filter_alt_off_rounded, () {
                  setState(() => _selectedDateRange = null);
                  Navigator.pop(context);
                }, isClear: true),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateTile(BuildContext context, String title, IconData icon, VoidCallback onTap, {bool isClear = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isClear ? AppTheme.expenseColor : AppTheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isClear ? AppTheme.expenseColor : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setFilterState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("More Filters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Account Filter
                  AccountSelectorField(
                    label: "Filter by Account",
                    selectedAccount: appState.accounts.any((a) => a.id == _selectedAccountIdFilter)
                        ? appState.accounts.firstWhere((a) => a.id == _selectedAccountIdFilter)
                        : null,
                    availableAccounts: appState.myAccounts,
                    appState: appState,
                    allowAllOption: true,
                    allOptionLabel: "All Accounts",
                    placeholder: "All Accounts",
                    onAccountSelected: (acc) {
                      setFilterState(() => _selectedAccountIdFilter = acc?.id);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Budget Filter
                  BudgetSelectorField(
                    label: "Filter by Budget",
                    selectedBudget: appState.budgets.any((b) => b.id == _selectedBudgetIdFilter)
                        ? appState.budgets.firstWhere((b) => b.id == _selectedBudgetIdFilter)
                        : null,
                    availableBudgets: appState.budgets,
                    appState: appState,
                    allowAllOption: true,
                    allOptionLabel: "All Budgets",
                    placeholder: "All Budgets",
                    onBudgetSelected: (b) {
                      setFilterState(() => _selectedBudgetIdFilter = b?.id);
                    },
                  ),
                  const SizedBox(height: 24),

                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text("Apply Filters"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedAccountIdFilter = null;
                                _selectedUserFilter = null;
                                _selectedBudgetIdFilter = null;
                                _minAmountFilter = null;
                                _maxAmountFilter = null;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("Reset"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  final TransactionItem? editingTransaction;
  final bool isTransferMode;
  final double? prefilledAmount;
  final String? prefilledAccountId;
  final String? prefilledTitle;
  final TransactionType? prefilledType;
  final String? prefilledCategoryId;
  final String? prefilledBudgetId;
  final bool isTitleAndAmountLocked;
  final BillReminderItem? billToMarkAsPaid;
  final String? unrecognizedTxIdToDelete;

  const AddTransactionSheet({
    super.key,
    this.editingTransaction,
    this.isTransferMode = false,
    this.prefilledAmount,
    this.prefilledAccountId,
    this.prefilledTitle,
    this.prefilledType,
    this.prefilledCategoryId,
    this.prefilledBudgetId,
    this.isTitleAndAmountLocked = false,
    this.billToMarkAsPaid,
    this.unrecognizedTxIdToDelete,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late bool _isTransfer;
  late TransactionType _type;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  late bool _isRecurring;
  late RecurrenceInterval _recurrenceInterval;
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedBudgetId;

  @override
  void initState() {
    super.initState();
    final tx = widget.editingTransaction;
    _isTransfer = tx?.isTransfer ?? widget.isTransferMode;
    _type = tx?.type ?? widget.prefilledType ?? TransactionType.expense;
    _titleController = TextEditingController(text: tx?.title ?? widget.prefilledTitle ?? '');
    _amountController = TextEditingController(
      text: tx != null
          ? tx.amount.toString()
          : (widget.prefilledAmount != null ? widget.prefilledAmount.toString() : ''),
    );
    _notesController = TextEditingController(text: tx?.notes ?? '');
    _selectedCategoryId = tx?.categoryId ?? widget.prefilledCategoryId;
    _selectedDate = tx?.date ?? DateTime.now();
    _isRecurring = tx?.isRecurring ?? false;
    _recurrenceInterval = tx?.recurrenceInterval ?? RecurrenceInterval.none;
    _selectedAccountId = tx?.accountId ?? widget.prefilledAccountId;
    _selectedToAccountId = tx?.toAccountId;
    _selectedBudgetId = tx?.budgetId ?? widget.prefilledBudgetId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text.trim());

    if (_isTransfer) {
      final fromAccId = _selectedAccountId ?? (appState.myAccounts.isNotEmpty ? appState.myAccounts.first.id : '');
      final toAccId = _selectedToAccountId ?? (appState.accounts.length > 1 ? appState.accounts[1].id : '');
      await appState.addTransfer(title, amount, _selectedDate, fromAccId, toAccId);
    } else {
      final categoryId = _selectedCategoryId ?? (appState.categories.isNotEmpty ? appState.categories.first.id : 'other');
      final accountId = _selectedAccountId ?? (appState.myAccounts.isNotEmpty ? appState.myAccounts.first.id : 'default_bank');

      if (widget.editingTransaction != null) {
        final updated = widget.editingTransaction!.copyWith(
          title: title,
          amount: amount,
          date: _selectedDate,
          categoryId: categoryId,
          type: _type,
          isRecurring: _isRecurring,
          recurrenceInterval: _isRecurring ? _recurrenceInterval : RecurrenceInterval.none,
          accountId: accountId,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          budgetId: _selectedBudgetId,
        );
        await appState.updateTransaction(updated);
      } else {
        await appState.addTransaction(
          title,
          amount,
          _selectedDate,
          categoryId,
          _type,
          accountId,
          isRecurring: _isRecurring,
          recurrenceInterval: _isRecurring ? _recurrenceInterval : RecurrenceInterval.none,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          budgetId: _selectedBudgetId,
        );
        if (widget.billToMarkAsPaid != null) {
          await appState.markBillAsPaid(widget.billToMarkAsPaid!);
        }
        if (widget.unrecognizedTxIdToDelete != null) {
          await appState.deleteUnrecognizedTransaction(widget.unrecognizedTxIdToDelete!);
        }
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.editingTransaction == null ? (_isTransfer ? "New Transfer" : "New Transaction") : "Edit Entry",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Entry Type Toggle (Expense / Income / Transfer)
              Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isTransfer = false;
                          _type = TransactionType.expense;
                          final expenseCats = appState.categories.where((c) => c.type == TransactionType.expense || c.id == 'other').toList();
                          if (expenseCats.isNotEmpty && !expenseCats.any((c) => c.id == _selectedCategoryId)) {
                            _selectedCategoryId = expenseCats.first.id;
                          }
                        }),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: (!_isTransfer && _type == TransactionType.expense)
                                ? (theme.brightness == Brightness.dark ? AppTheme.primary : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: (!_isTransfer && _type == TransactionType.expense)
                                ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                                : null,
                          ),
                          child: Text(
                            "Expense",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: (!_isTransfer && _type == TransactionType.expense)
                                  ? (theme.brightness == Brightness.dark ? Colors.white : AppTheme.expenseColor)
                                  : theme.hintColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isTransfer = false;
                          _type = TransactionType.income;
                          final incomeCats = appState.categories.where((c) => c.type == TransactionType.income || c.id == 'other').toList();
                          if (incomeCats.isNotEmpty && !incomeCats.any((c) => c.id == _selectedCategoryId)) {
                            _selectedCategoryId = incomeCats.first.id;
                          }
                        }),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: (!_isTransfer && _type == TransactionType.income)
                                ? (theme.brightness == Brightness.dark ? AppTheme.primary : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: (!_isTransfer && _type == TransactionType.income)
                                ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                                : null,
                          ),
                          child: Text(
                            "Income",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: (!_isTransfer && _type == TransactionType.income)
                                  ? (theme.brightness == Brightness.dark ? Colors.white : AppTheme.incomeColor)
                                  : theme.hintColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _isTransfer = true; }),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _isTransfer
                                ? (theme.brightness == Brightness.dark ? AppTheme.primary : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isTransfer
                                ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                                : null,
                          ),
                          child: Text(
                            "Transfer",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _isTransfer
                                  ? (theme.brightness == Brightness.dark ? Colors.white : AppTheme.primary)
                                  : theme.hintColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                readOnly: widget.isTitleAndAmountLocked,
                decoration: InputDecoration(
                  labelText: _isTransfer ? 'Transfer Title' : 'Title',
                  hintText: _isTransfer ? 'e.g. Savings Transfer' : 'e.g. Groceries',
                  filled: widget.isTitleAndAmountLocked,
                  fillColor: widget.isTitleAndAmountLocked
                      ? (theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                      : null,
                  suffixIcon: widget.isTitleAndAmountLocked
                      ? const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey)
                      : null,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Title required" : null,
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                readOnly: widget.isTitleAndAmountLocked,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: '0.00',
                  filled: widget.isTitleAndAmountLocked,
                  fillColor: widget.isTitleAndAmountLocked
                      ? (theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                      : null,
                  suffixIcon: widget.isTitleAndAmountLocked
                      ? const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey)
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Amount required";
                  if (double.tryParse(val.trim()) == null) return "Invalid number";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_isTransfer) ...[
                // Source Account (From)
                AccountSelectorField(
                  label: "From Account",
                  selectedAccount: appState.accounts.any((a) => a.id == _selectedAccountId)
                      ? appState.accounts.firstWhere((a) => a.id == _selectedAccountId)
                      : (appState.myAccounts.isNotEmpty ? appState.myAccounts.first : null),
                  availableAccounts: appState.myAccounts,
                  appState: appState,
                  onAccountSelected: (acc) {
                    setState(() {
                      _selectedAccountId = acc?.id;
                      if (_selectedToAccountId == acc?.id) {
                        _selectedToAccountId = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Target Account (To)
                Builder(
                  builder: (context) {
                    final destAccounts = appState.accounts.where((a) => a.id != _selectedAccountId).toList();
                    final selectedDest = destAccounts.any((a) => a.id == _selectedToAccountId)
                        ? destAccounts.firstWhere((a) => a.id == _selectedToAccountId)
                        : (destAccounts.isNotEmpty ? destAccounts.first : null);
                    return AccountSelectorField(
                      label: "To Account",
                      selectedAccount: selectedDest,
                      availableAccounts: destAccounts,
                      appState: appState,
                      onAccountSelected: (acc) {
                        setState(() => _selectedToAccountId = acc?.id);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Category
                Builder(
                  builder: (context) {
                    final availableCats = appState.categories
                        .where((c) => c.type == _type || c.id == 'other')
                        .toList();
                    final selectedCat = availableCats.any((c) => c.id == _selectedCategoryId)
                        ? availableCats.firstWhere((c) => c.id == _selectedCategoryId)
                        : (availableCats.isNotEmpty ? availableCats.first : null);
                    return CategorySelectorField(
                      label: "Category",
                      selectedCategory: selectedCat,
                      availableCategories: availableCats,
                      onCategorySelected: (cat) {
                        setState(() => _selectedCategoryId = cat?.id);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Source Account
                AccountSelectorField(
                  label: _type == TransactionType.expense ? "Expense Account" : "Income Account",
                  selectedAccount: appState.myAccounts.any((a) => a.id == _selectedAccountId)
                      ? appState.myAccounts.firstWhere((a) => a.id == _selectedAccountId)
                      : (appState.myAccounts.isNotEmpty ? appState.myAccounts.first : null),
                  availableAccounts: appState.myAccounts,
                  appState: appState,
                  onAccountSelected: (acc) {
                    setState(() => _selectedAccountId = acc?.id);
                  },
                ),
                const SizedBox(height: 16),
                // Optional Budget Selector
                if (appState.budgets.isNotEmpty) ...[
                  BudgetSelectorField(
                    label: "Link to Budget (Optional)",
                    selectedBudget: appState.budgets.any((b) => b.id == _selectedBudgetId)
                        ? appState.budgets.firstWhere((b) => b.id == _selectedBudgetId)
                        : null,
                    availableBudgets: appState.budgets,
                    appState: appState,
                    allowAllOption: true,
                    allOptionLabel: "None",
                    placeholder: "None",
                    onBudgetSelected: (b) {
                      setState(() => _selectedBudgetId = b?.id);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              // Notes field
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: "Notes (Optional)", hintText: "Add additional notes..."),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveForm,
                child: const Text("Save Entry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
