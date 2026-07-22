import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/theme.dart';
import '../widgets/account_selector.dart';
import '../widgets/category_selector.dart';
import 'transactions_screen.dart';

class BillRemindersScreen extends StatefulWidget {
  const BillRemindersScreen({super.key});

  @override
  State<BillRemindersScreen> createState() => _BillRemindersScreenState();
}

class _BillRemindersScreenState extends State<BillRemindersScreen> {
  final _currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  final _dateFormatter = DateFormat('dd MMM yyyy');
  String _selectedStatusFilter = 'All';

  // Preset templates
  final List<Map<String, String>> _billTemplates = [
    {'title': 'Electricity Bill', 'category': 'utilities', 'icon': 'utilities'},
    {'title': 'Water Bill', 'category': 'water', 'icon': 'water'},
    {'title': 'Internet Bill', 'category': 'internet', 'icon': 'internet'},
    {'title': 'Netflix', 'category': 'netflix', 'icon': 'netflix'},
    {'title': 'Prime Video', 'category': 'prime', 'icon': 'prime'},
    {'title': 'Spotify', 'category': 'spotify', 'icon': 'spotify'},
    {'title': 'Insurance Premium', 'category': 'insurance', 'icon': 'insurance'},
    {'title': 'House Rent', 'category': 'rent', 'icon': 'rent'},
    {'title': 'EMI Payment', 'category': 'emi', 'icon': 'emi'},
    {'title': 'Credit Card Bill', 'category': 'credit_card', 'icon': 'credit_card'},
    {'title': 'Gas Bill', 'category': 'fuel', 'icon': 'fuel'},
    {'title': 'Phone Recharge', 'category': 'recharge', 'icon': 'recharge'},
    {'title': 'Other Bill', 'category': 'other', 'icon': 'other'},
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    var bills = appState.billReminders;
    if (_selectedStatusFilter != 'All') {
      bills = bills.where((b) => b.status == _selectedStatusFilter).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill Reminders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded),
            onPressed: () => _showAddEditBillModal(context),
            tooltip: "Add Bill",
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Upcoming', 'Overdue', 'Paid'].map((status) {
                final isSelected = _selectedStatusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    label: Text(status, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedStatusFilter = status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Bill List
          Expanded(
            child: bills.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 56,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No Bill Reminders Found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Set up electricity, rent, subscriptions or EMI reminders.",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditBillModal(context),
                          icon: const Icon(Icons.add),
                          label: const Text("Add Bill Reminder"),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: bills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bill = bills[index];
                      final category = appState.categories.firstWhere(
                        (c) => c.id == bill.categoryId,
                        orElse: () => CategoryItem(
                          id: 'other',
                          name: 'Other',
                          iconKey: 'other',
                          colorValue: Colors.grey.value,
                          type: TransactionType.expense,
                        ),
                      );
                      final iconData = categoryIcons[category.iconKey] ?? Icons.receipt;
                      final status = bill.status;

                      Color statusColor = AppTheme.primary;
                      if (status == 'Paid') statusColor = AppTheme.incomeColor;
                      if (status == 'Overdue') statusColor = AppTheme.expenseColor;
                      if (status == 'Upcoming') statusColor = AppTheme.secondary;

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: status == 'Overdue'
                                ? AppTheme.expenseColor.withOpacity(0.8)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            width: status == 'Overdue' ? 1.5 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(iconData, color: statusColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bill.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Due: ${_dateFormatter.format(bill.dueDate)} • ${bill.repeat.toUpperCase()}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currencyFormatter.format(bill.amount),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (bill.notes != null && bill.notes!.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      "Note: ${bill.notes}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                else
                                  const Spacer(),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (!bill.isPaid)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          minimumSize: const Size(0, 36),
                                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => AddTransactionSheet(
                                              prefilledTitle: bill.title,
                                              prefilledAmount: bill.amount,
                                              prefilledType: TransactionType.expense,
                                              prefilledCategoryId: bill.categoryId,
                                              isTitleAndAmountLocked: true,
                                              billToMarkAsPaid: bill,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.check_circle_outline, size: 16),
                                        label: const Text("Mark Paid"),
                                      ),
                                    const SizedBox(width: 4),
                                    PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showAddEditBillModal(context, bill: bill);
                                        } else if (val == 'delete') {
                                          appState.deleteBillReminder(bill.id);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'edit', child: Text("Edit")),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text("Delete", style: TextStyle(color: AppTheme.expenseColor)),
                                        ),
                                      ],
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBillModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditBillModal(BuildContext context, {BillReminderItem? bill}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleController = TextEditingController(text: bill?.title ?? '');
    final amountController = TextEditingController(text: bill != null ? bill.amount.toStringAsFixed(0) : '');
    final notesController = TextEditingController(text: bill?.notes ?? '');

    String selectedCategoryId = bill?.categoryId ?? (appState.categories.isNotEmpty ? appState.categories.first.id : 'utilities');
    String selectedAccountId = bill?.accountId ?? (appState.myAccounts.isNotEmpty ? appState.myAccounts.first.id : '');
    DateTime dueDate = bill?.dueDate ?? DateTime.now().add(const Duration(days: 5));
    String repeat = bill?.repeat ?? 'monthly';
    bool notificationEnabled = bill?.notificationEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bill == null ? "Add Bill Reminder" : "Edit Bill Reminder",
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

                    // Preset Templates Bar
                    if (bill == null) ...[
                      const Text("Quick Templates:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _billTemplates.map((tmpl) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(tmpl['title']!),
                                onPressed: () {
                                  setModalState(() {
                                    titleController.text = tmpl['title']!;
                                    final matchedCat = appState.categories.firstWhere(
                                      (c) => c.iconKey == tmpl['icon'] || c.id == tmpl['category'],
                                      orElse: () => appState.categories.first,
                                    );
                                    selectedCategoryId = matchedCat.id;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Bill Title", hintText: "e.g. Electricity Bill"),
                    ),
                    const SizedBox(height: 12),

                    // Amount
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Amount (₹)", hintText: "e.g. 2500"),
                    ),
                    const SizedBox(height: 12),

                    // Category Selector
                    CategorySelectorField(
                      label: "Category",
                      selectedCategory: appState.categories.any((c) => c.id == selectedCategoryId)
                          ? appState.categories.firstWhere((c) => c.id == selectedCategoryId)
                          : (appState.categories.isNotEmpty ? appState.categories.first : null),
                      availableCategories: appState.categories,
                      onCategorySelected: (cat) {
                        if (cat != null) setModalState(() => selectedCategoryId = cat.id);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Account Selector
                    AccountSelectorField(
                      label: "Paying Account",
                      selectedAccount: appState.myAccounts.any((a) => a.id == selectedAccountId)
                          ? appState.myAccounts.firstWhere((a) => a.id == selectedAccountId)
                          : (appState.myAccounts.isNotEmpty ? appState.myAccounts.first : null),
                      availableAccounts: appState.myAccounts,
                      appState: appState,
                      onAccountSelected: (acc) {
                        if (acc != null) setModalState(() => selectedAccountId = acc.id);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Due Date Picker & Repeat
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dueDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) setModalState(() => dueDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(_dateFormatter.format(dueDate)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: repeat,
                            decoration: const InputDecoration(labelText: "Repeat"),
                            items: const [
                              DropdownMenuItem(value: 'none', child: Text("One-time")),
                              DropdownMenuItem(value: 'weekly', child: Text("Weekly")),
                              DropdownMenuItem(value: 'monthly', child: Text("Monthly")),
                              DropdownMenuItem(value: 'yearly', child: Text("Yearly")),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => repeat = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: "Notes (Optional)"),
                    ),
                    const SizedBox(height: 12),

                    // Notification toggle
                    SwitchListTile(
                      title: const Text("Remind Me Before Due Date"),
                      value: notificationEnabled,
                      onChanged: (val) => setModalState(() => notificationEnabled = val),
                    ),
                    const SizedBox(height: 16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                          if (title.isEmpty || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a valid bill title and amount.")),
                            );
                            return;
                          }

                          final newBill = BillReminderItem(
                            id: bill?.id ?? 'bill_${DateTime.now().microsecondsSinceEpoch}',
                            title: title,
                            amount: amount,
                            categoryId: selectedCategoryId,
                            dueDate: dueDate,
                            repeat: repeat,
                            notificationEnabled: notificationEnabled,
                            accountId: selectedAccountId,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                            isPaid: bill?.isPaid ?? false,
                            creatorId: appState.currentUser?.id ?? '',
                          );

                          if (bill == null) {
                            await appState.addBillReminder(newBill);
                          } else {
                            await appState.updateBillReminder(newBill);
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(bill == null ? "Save Bill Reminder" : "Update Bill Reminder"),
                      ),
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
}
