import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  List<String> _selectedCategoryIds = [];
  String _selectedTypeFilter = 'all'; // all, income, expense
  DateTimeRange? _selectedDateRange;

  Future<void> _pickDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (pickedRange != null) {
      setState(() => _selectedDateRange = pickedRange);
    }
  }

  final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
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

    final filteredTransactions = appState.transactions.where((t) {
      if (t.isTransfer) return false;
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesType = _selectedTypeFilter == 'all' ||
          (_selectedTypeFilter == 'income' && t.type == TransactionType.income) ||
          (_selectedTypeFilter == 'expense' && t.type == TransactionType.expense);
          
      final matchesCategory = _selectedCategoryIds.isEmpty || _selectedCategoryIds.contains(t.categoryId);

      final matchesDate = _selectedDateRange == null ||
          (t.date.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
           t.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
      
      return matchesSearch && matchesType && matchesCategory && matchesDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "Search transactions...",
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(
                        Icons.date_range,
                        color: _selectedDateRange == null ? theme.hintColor : AppTheme.primary,
                      ),
                      tooltip: "Filter Date Range",
                      onPressed: _pickDateRange,
                    ),
                    if (_selectedDateRange != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.expenseColor),
                        tooltip: "Clear Date Range",
                        onPressed: () => setState(() => _selectedDateRange = null),
                      ),
                  ],
                ),
                if (_selectedDateRange != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Date Range: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Type Filter Dropdown
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                child: Row(
                                  children: [
                                    Icon(Icons.list, size: 18, color: AppTheme.primary),
                                    SizedBox(width: 8),
                                    Text('All Types', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              ),
                              DropdownMenuItem(
                                value: 'income', 
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_upward, size: 18, color: AppTheme.incomeColor),
                                    SizedBox(width: 8),
                                    Text('Incomes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              ),
                              DropdownMenuItem(
                                value: 'expense', 
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_downward, size: 18, color: AppTheme.expenseColor),
                                    SizedBox(width: 8),
                                    Text('Expenses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                )
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
                    // Category Filter Dropdown (PopupMenuButton multi-select)
                    Expanded(
                      child: PopupMenuButton<void>(
                        offset: const Offset(0, 56),
                        elevation: 8,
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem<void>(
                              enabled: false,
                              child: StatefulBuilder(
                                builder: (context, setMenuState) {
                                  final presentCategoryIds = appState.transactions.map((t) => t.categoryId).toSet();
                                  final categoriesToShow = appState.categories.where((c) => presentCategoryIds.contains(c.id)).toList();

                                  return Container(
                                    width: 220,
                                    constraints: const BoxConstraints(maxHeight: 300),
                                    child: ListView(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      children: [
                                        CheckboxListTile(
                                          value: _selectedCategoryIds.isEmpty,
                                          title: const Text("All Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          controlAffinity: ListTileControlAffinity.leading,
                                          dense: true,
                                          onChanged: (val) {
                                            if (val == true) {
                                              setMenuState(() {
                                                _selectedCategoryIds.clear();
                                              });
                                              setState(() {
                                                _selectedCategoryIds.clear();
                                              });
                                            }
                                          },
                                        ),
                                        const Divider(height: 1),
                                        ...categoriesToShow.map((c) {
                                          final isSelected = _selectedCategoryIds.contains(c.id);
                                          return CheckboxListTile(
                                            value: isSelected,
                                            title: Text(c.name, style: const TextStyle(fontSize: 13)),
                                            controlAffinity: ListTileControlAffinity.leading,
                                            dense: true,
                                            activeColor: Color(c.colorValue),
                                            onChanged: (val) {
                                              setMenuState(() {
                                                if (val == true) {
                                                  _selectedCategoryIds.add(c.id);
                                                } else {
                                                  _selectedCategoryIds.remove(c.id);
                                                }
                                              });
                                              setState(() {});
                                            },
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ];
                        },
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.category_outlined, size: 18, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedCategoryIds.isEmpty
                                      ? "All Categories"
                                      : _selectedCategoryIds.length == 1
                                          ? appState.categories.firstWhere(
                                              (c) => c.id == _selectedCategoryIds.first,
                                              orElse: () => CategoryItem(
                                                id: '',
                                                name: 'Unknown',
                                                iconKey: '',
                                                colorValue: 0,
                                                type: TransactionType.expense,
                                              ),
                                            ).name
                                          : "${_selectedCategoryIds.length} Categories",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: theme.hintColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: theme.hintColor),
                        const SizedBox(height: 16),
                        Text(
                          "No transactions found.",
                          style: TextStyle(color: theme.hintColor, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredTransactions[index];
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

                      final dateStr = DateFormat('dd MMM yyyy').format(item.date);
                      final acc = appState.accounts.firstWhere(
                        (a) => a.id == item.accountId,
                        orElse: () => AccountItem(
                          id: 'other',
                          name: 'Default Cash/Bank',
                          type: AccountType.bank,
                          initialBalance: 0,
                          creatorId: '',
                        ),
                      );

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
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Confirm Delete"),
                              content: const Text("Are you sure you want to delete this transaction?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete", style: TextStyle(color: AppTheme.expenseColor)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          appState.deleteTransaction(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Transaction deleted")),
                          );
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
                                    backgroundColor: Color(cat.colorValue).withAlpha((0.12 * 255).toInt()),
                                    child: Icon(
                                      categoryIcons[cat.iconKey] ?? Icons.more_horiz,
                                      color: Color(cat.colorValue),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ),
                                            if (item.isRecurring)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary.withAlpha((0.15 * 255).toInt()),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.autorenew, size: 10, color: AppTheme.primary),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      item.recurrenceInterval.name,
                                                      style: const TextStyle(fontSize: 8, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
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
                                            Icon(Icons.person_outline, size: 11, color: AppTheme.primary.withAlpha((0.7 * 255).toInt())),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                "By: ${item.creatorName}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.primary.withAlpha((0.85 * 255).toInt()),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "${item.type == TransactionType.income ? '+' : '-'}${formatter.format(item.amount)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: item.type == TransactionType.income
                                            ? AppTheme.incomeColor
                                            : AppTheme.expenseColor,
                                      ),
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
}

class AddTransactionSheet extends StatefulWidget {
  final TransactionItem? editingTransaction;
  final double? prefilledAmount;
  final String? prefilledAccountId;
  final String? prefilledTitle;
  final String? unrecognizedTxIdToDelete;

  const AddTransactionSheet({
    super.key, 
    this.editingTransaction,
    this.prefilledAmount,
    this.prefilledAccountId,
    this.prefilledTitle,
    this.unrecognizedTxIdToDelete,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  late bool _isRecurring;
  late RecurrenceInterval _recurrenceInterval;
  String? _selectedAccountId;
  String? _selectedToAccountId; // for CC payments

  @override
  void initState() {
    super.initState();
    final tx = widget.editingTransaction;
    _type = tx?.type ?? TransactionType.expense;
    _titleController = TextEditingController(text: tx?.title ?? widget.prefilledTitle ?? '');
    _amountController = TextEditingController(
      text: tx != null 
          ? tx.amount.toString() 
          : (widget.prefilledAmount != null ? widget.prefilledAmount.toString() : ''),
    );
    _selectedCategoryId = tx?.categoryId;
    _selectedDate = tx?.date ?? DateTime.now();
    _isRecurring = tx?.isRecurring ?? false;
    _recurrenceInterval = tx?.recurrenceInterval ?? RecurrenceInterval.none;
    if (_isRecurring && _recurrenceInterval == RecurrenceInterval.none) {
      _recurrenceInterval = RecurrenceInterval.monthly;
    }
    _selectedAccountId = tx?.accountId ?? widget.prefilledAccountId;
    _selectedToAccountId = tx?.toAccountId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  InputDecoration _dropdownDecoration({
    required String labelText,
    required IconData prefixIcon,
    required bool isDark,
    required ThemeData theme,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, color: AppTheme.primary),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppTheme.primary,
          width: 2.0,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text.trim());
    final categoryId = _selectedCategoryId ?? 'other';
    final accountId = _selectedAccountId ?? appState.accounts.first.id;

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
        toAccountId: categoryId == 'credit_card_payment' ? _selectedToAccountId : null,
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
        toAccountId: categoryId == 'credit_card_payment' ? _selectedToAccountId : null,
      );
      if (widget.unrecognizedTxIdToDelete != null) {
        await appState.deleteUnrecognizedTransaction(widget.unrecognizedTxIdToDelete!);
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final typeCategories = appState.categories.where((c) => c.type == _type || c.id == 'other').toList();
    if (_selectedCategoryId == null && typeCategories.isNotEmpty) {
      _selectedCategoryId = typeCategories.first.id;
    } else if (_selectedCategoryId != null && !typeCategories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = typeCategories.first.id;
    }

    if (_selectedAccountId == null && appState.accounts.isNotEmpty) {
      _selectedAccountId = appState.accounts.first.id;
    }

    final creditCards = appState.accounts.where((a) => a.type == AccountType.creditCard).toList();
    if (_selectedToAccountId == null && creditCards.isNotEmpty) {
      _selectedToAccountId = creditCards.first.id;
    }

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
                    widget.editingTransaction == null ? "Add Transaction" : "Edit Transaction",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Expense", style: TextStyle(fontWeight: FontWeight.bold))),
                      selected: _type == TransactionType.expense,
                      onSelected: (val) {
                        if (val) setState(() => _type = TransactionType.expense);
                      },
                      selectedColor: AppTheme.expenseColor.withAlpha((0.2 * 255).toInt()),
                      labelStyle: TextStyle(
                        color: _type == TransactionType.expense ? AppTheme.expenseColor : theme.hintColor,
                      ),
                      checkmarkColor: AppTheme.expenseColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Income / Salary", style: TextStyle(fontWeight: FontWeight.bold))),
                      selected: _type == TransactionType.income,
                      onSelected: (val) {
                        if (val) setState(() => _type = TransactionType.income);
                      },
                      selectedColor: AppTheme.incomeColor.withAlpha((0.2 * 255).toInt()),
                      labelStyle: TextStyle(
                        color: _type == TransactionType.income ? AppTheme.incomeColor : theme.hintColor,
                      ),
                      checkmarkColor: AppTheme.incomeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Transaction Title',
                  hintText: 'e.g. Weekly Groceries, Office Salary',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Title is required";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.00',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Amount is required";
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) return "Please enter a valid positive number";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: _dropdownDecoration(
                    labelText: 'Category',
                    prefixIcon: Icons.category_outlined,
                    isDark: isDark,
                    theme: theme,
                  ),
                  dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  selectedItemBuilder: (BuildContext context) {
                    return typeCategories.map((c) {
                      return Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      );
                    }).toList();
                  },
                  items: typeCategories.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Color(c.colorValue).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                categoryIcons[c.iconKey] ?? Icons.more_horiz,
                                color: Color(c.colorValue),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  validator: (val) => val == null ? "Category is required" : null,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: _dropdownDecoration(
                    labelText: 'Source Account / Card',
                    prefixIcon: Icons.account_balance_wallet_outlined,
                    isDark: isDark,
                    theme: theme,
                  ),
                  dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  selectedItemBuilder: (BuildContext context) {
                    return appState.accounts.map((a) {
                      final balance = appState.getAccountBalance(a);
                      final isCreditCard = a.type == AccountType.creditCard;
                      final double displayBalance = isCreditCard
                          ? ((a.limit ?? 0.0) - balance)
                          : balance;
                      final balanceStr = NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(displayBalance);
                      return Text(
                        isCreditCard 
                            ? "${a.name} (Limit: $balanceStr)"
                            : "${a.name} ($balanceStr)",
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      );
                    }).toList();
                  },
                  items: appState.accounts.map((a) {
                    final balance = appState.getAccountBalance(a);
                    final isCreditCard = a.type == AccountType.creditCard;
                    final double displayBalance = isCreditCard
                        ? ((a.limit ?? 0.0) - balance)
                        : balance;
                    final balanceStr = NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(displayBalance);
                    final color = a.colorHex != null 
                        ? Color(int.parse(a.colorHex!, radix: 16)) 
                        : (isCreditCard ? const Color(0xFF475569) : AppTheme.primary);

                    return DropdownMenuItem(
                      value: a.id,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isCreditCard ? Icons.credit_card : Icons.account_balance,
                                color: color,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                a.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isCreditCard ? "Available: $balanceStr" : balanceStr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCreditCard 
                                    ? AppTheme.incomeColor 
                                    : (balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                  validator: (val) => val == null ? "Account is required" : null,
                ),
              ),
              if (_selectedCategoryId == 'credit_card_payment' && creditCards.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedToAccountId,
                    decoration: _dropdownDecoration(
                      labelText: 'Destination Credit Card',
                      prefixIcon: Icons.credit_card_outlined,
                      isDark: isDark,
                      theme: theme,
                    ),
                    dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    selectedItemBuilder: (BuildContext context) {
                      return creditCards.map((cc) {
                        final balance = appState.getAccountBalance(cc);
                        final displayBalance = (cc.limit ?? 0.0) - balance;
                        final balanceStr = NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(displayBalance);
                        return Text(
                          "${cc.name} (Limit: $balanceStr)",
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        );
                      }).toList();
                    },
                    items: creditCards.map((cc) {
                      final balance = appState.getAccountBalance(cc);
                      final displayBalance = (cc.limit ?? 0.0) - balance;
                      final balanceStr = NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(displayBalance);
                      final color = cc.colorHex != null 
                          ? Color(int.parse(cc.colorHex!, radix: 16)) 
                          : const Color(0xFF475569);

                      return DropdownMenuItem(
                        value: cc.id,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.credit_card,
                                  color: color,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cc.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Available: $balanceStr",
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.incomeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedToAccountId = val),
                    validator: (val) => val == null ? "Destination card is required" : null,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha((0.05 * 255).toInt()) : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Transaction Date", style: TextStyle(fontSize: 12, color: theme.hintColor)),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha((0.03 * 255).toInt()) : AppTheme.lightCard.withAlpha((0.5 * 255).toInt()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.autorenew, color: AppTheme.primary, size: 20),
                            SizedBox(width: 12),
                            Text("Recurring Transaction", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Switch(
                          value: _isRecurring,
                          onChanged: (val) => setState(() => _isRecurring = val),
                          activeColor: AppTheme.primary,
                        ),
                      ],
                    ),
                    if (_isRecurring) ...[
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Repeat Every", style: TextStyle(color: theme.hintColor, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<RecurrenceInterval>(
                                value: _recurrenceInterval,
                                items: const [
                                  DropdownMenuItem(value: RecurrenceInterval.daily, child: Text('Daily')),
                                  DropdownMenuItem(value: RecurrenceInterval.weekly, child: Text('Weekly')),
                                  DropdownMenuItem(value: RecurrenceInterval.monthly, child: Text('Monthly')),
                                  DropdownMenuItem(value: RecurrenceInterval.yearly, child: Text('Yearly')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _recurrenceInterval = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveForm,
                child: const Text("Save Transaction"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
