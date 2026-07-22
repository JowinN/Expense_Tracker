import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/theme.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  String _formatPeriodName(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final budgets = appState.budgets;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate aggregated overview metrics
    double totalBudget = 0.0;
    double totalSpent = 0.0;
    for (var b in budgets) {
      double spent = appState.getBudgetSpent(b);
      totalBudget += b.amount;
      totalSpent += spent;
    }
    double remainingTotal = totalBudget - totalSpent;
    double overallUtilization = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Budgets"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart_rounded),
            onPressed: () => _showAddEditBudgetModal(context),
            tooltip: "Add Budget",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Budget Dashboard Summary Card
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
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Budget Overview",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${budgets.length} Active",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Budget",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            _currencyFormatter.format(totalBudget),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Total Spent",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            _currencyFormatter.format(totalSpent),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: overallUtilization,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        totalSpent > totalBudget && totalBudget > 0 ? AppTheme.warningColor : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Remaining: ${_currencyFormatter.format(remainingTotal)}",
                        style: TextStyle(
                          color: remainingTotal < 0 ? const Color(0xFFFFB4AB) : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${(overallUtilization * 100).toStringAsFixed(1)}% Used",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Active Budgets",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddEditBudgetModal(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("New Budget"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Budget Cards List
            if (budgets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 48,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No Budgets Set Yet",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Set monthly or weekly spending limits to track and manage your finances automatically.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditBudgetModal(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Create Budget"),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: budgets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  final spent = appState.getBudgetSpent(budget);
                  final remaining = budget.amount - spent;
                  final percentUsed = budget.amount > 0 ? (spent / budget.amount) : 0.0;
                  final isExceeded = spent > budget.amount;

                  // Calculate days remaining
                  final now = DateTime.now();
                  final daysLeft = budget.endDate.difference(now).inDays;
                  final daysText = daysLeft < 0
                      ? "Expired"
                      : (daysLeft == 0 ? "Expires today" : "$daysLeft days left");

                  final iconData = categoryIcons[budget.iconKey] ?? Icons.pie_chart;
                  final color = Color(budget.colorValue);

                  // Included category names
                  final catNames = budget.categoryIds.isEmpty
                      ? "All Categories"
                      : appState.categories
                          .where((c) => budget.categoryIds.contains(c.id))
                          .map((c) => c.name)
                          .join(", ");

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isExceeded
                            ? AppTheme.expenseColor.withOpacity(0.8)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: isExceeded ? 1.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(iconData, color: color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    budget.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    "${_formatPeriodName(budget.period.name)} • $daysText",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_vert),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showAddEditBudgetModal(context, budget: budget);
                              } else if (val == 'delete') {
                                appState.deleteBudget(budget.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text("Edit Budget")),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text("Delete", style: TextStyle(color: AppTheme.expenseColor)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Spend Details Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Spent: ${_currencyFormatter.format(spent)}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isExceeded ? AppTheme.expenseColor : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                          ),
                          Text(
                            "Budget: ${_currencyFormatter.format(budget.amount)}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Progress Bar & Percentage text
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percentUsed.clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isExceeded ? AppTheme.expenseColor : color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "${(percentUsed * 100).toStringAsFixed(0)}%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isExceeded ? AppTheme.expenseColor : color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Warning Badge if exceeded
                      if (isExceeded)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.expenseColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.expenseColor),
                                SizedBox(width: 4),
                                Text(
                                  "⚠ Budget Exceeded",
                                  style: TextStyle(
                                    color: AppTheme.expenseColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 88),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBudgetModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditBudgetModal(BuildContext context, {BudgetItem? budget}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nameController = TextEditingController(text: budget?.name ?? '');
    final amountController = TextEditingController(text: budget != null ? budget.amount.toStringAsFixed(0) : '');

    String selectedIconKey = budget?.iconKey ?? 'food';
    int selectedColor = budget?.colorValue ?? appColors.first;
    BudgetPeriod selectedPeriod = budget?.period ?? BudgetPeriod.monthly;
    DateTime startDate = budget?.startDate ?? DateTime.now();
    DateTime endDate = budget?.endDate ?? DateTime.now().add(const Duration(days: 30));
    List<String> selectedCategoryIds = budget != null ? List.from(budget.categoryIds) : [];
    bool rollover = budget?.rollover ?? false;

    // Filter expense categories only
    final expenseCategories = appState.categories.where((c) => c.type == TransactionType.expense).toList();

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
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                          budget == null ? "Create New Budget" : "Edit Budget",
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

                    // Budget Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Budget Name",
                        hintText: "e.g. Monthly Grocery Limit",
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Budget Amount
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Budget Amount (₹)",
                        hintText: "e.g. 15000",
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Period Selection
                    InkWell(
                      onTap: () {
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
                                        "Select Budget Period",
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
                                  ...BudgetPeriod.values.map((p) {
                                    final isSelected = selectedPeriod == p;
                                    final formattedName = _formatPeriodName(p.name);
                                    IconData periodIcon;
                                    switch (p) {
                                      case BudgetPeriod.weekly:
                                        periodIcon = Icons.view_week_rounded;
                                        break;
                                      case BudgetPeriod.monthly:
                                        periodIcon = Icons.calendar_month_rounded;
                                        break;
                                      case BudgetPeriod.yearly:
                                        periodIcon = Icons.date_range_rounded;
                                        break;
                                      case BudgetPeriod.custom:
                                        periodIcon = Icons.edit_calendar_rounded;
                                        break;
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
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
                                        onTap: () {
                                          setModalState(() {
                                            selectedPeriod = p;
                                            final now = DateTime.now();
                                            if (p == BudgetPeriod.weekly) {
                                              startDate = now;
                                              endDate = now.add(const Duration(days: 7));
                                            } else if (p == BudgetPeriod.monthly) {
                                              startDate = DateTime(now.year, now.month, 1);
                                              endDate = DateTime(now.year, now.month + 1, 0);
                                            } else if (p == BudgetPeriod.yearly) {
                                              startDate = DateTime(now.year, 1, 1);
                                              endDate = DateTime(now.year, 12, 31);
                                            }
                                          });
                                          Navigator.pop(context);
                                        },
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(periodIcon, color: AppTheme.primary, size: 20),
                                        ),
                                        title: Text(
                                          formattedName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                          ),
                                        ),
                                        trailing: isSelected
                                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22)
                                            : null,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Budget Period",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatPeriodName(selectedPeriod.name),
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

                    if (selectedPeriod == BudgetPeriod.custom) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() => startDate = picked);
                                }
                              },
                              child: Text("Start: ${DateFormat('dd MMM yyyy').format(startDate)}"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() => endDate = picked);
                                }
                              },
                              child: Text("End: ${DateFormat('dd MMM yyyy').format(endDate)}"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Categories Selector Field
                    InkWell(
                      onTap: () {
                        _showMultiCategorySelectorSheet(
                          context: context,
                          expenseCategories: expenseCategories,
                          selectedCategoryIds: selectedCategoryIds,
                          onSelectionChanged: (newIds) {
                            setModalState(() {
                              selectedCategoryIds = newIds;
                            });
                          },
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Include Categories",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedCategoryIds.length == expenseCategories.length
                                        ? "All Categories (${expenseCategories.length})"
                                        : (selectedCategoryIds.isEmpty
                                            ? "None Selected"
                                            : "${selectedCategoryIds.length} Categories Selected"),
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

                    // Rollover Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Carry Remaining Budget Forward (Rollover)"),
                      subtitle: const Text("Unused remaining amount will roll over to the next period"),
                      value: rollover,
                      onChanged: (val) => setModalState(() => rollover = val),
                    ),
                    const SizedBox(height: 16),

                    // Color Picker Row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Select Color", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: appColors.map((colorVal) {
                              final isSelected = selectedColor == colorVal;
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedColor = colorVal),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Color(colorVal),
                                    shape: BoxShape.circle,
                                    boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))] : null,
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                          if (name.isEmpty || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a valid budget name and amount.")),
                            );
                            return;
                          }

                          final newBudget = BudgetItem(
                            id: budget?.id ?? 'budget_${DateTime.now().microsecondsSinceEpoch}',
                            name: name,
                            amount: amount,
                            iconKey: selectedIconKey,
                            colorValue: selectedColor,
                            period: selectedPeriod,
                            startDate: startDate,
                            endDate: endDate,
                            categoryIds: selectedCategoryIds,
                            rollover: rollover,
                            creatorId: appState.currentUser?.id ?? '',
                          );

                          if (budget == null) {
                            await appState.addBudget(newBudget);
                          } else {
                            await appState.updateBudget(newBudget);
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(budget == null ? "Save Budget" : "Update Budget"),
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

  void _showMultiCategorySelectorSheet({
    required BuildContext context,
    required List<CategoryItem> expenseCategories,
    required List<String> selectedCategoryIds,
    required ValueChanged<List<String>> onSelectionChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<String> currentSelected = List<String>.from(selectedCategoryIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isAllSelected = currentSelected.length == expenseCategories.length;

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                        "Include Categories",
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
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${currentSelected.length} of ${expenseCategories.length} selected",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setSheetState(() {
                            if (isAllSelected) {
                              currentSelected.clear();
                            } else {
                              currentSelected = expenseCategories.map((c) => c.id).toList();
                            }
                          });
                        },
                        icon: Icon(isAllSelected ? Icons.deselect_rounded : Icons.select_all_rounded, size: 18),
                        label: Text(
                          isAllSelected ? "Deselect All" : "Select All",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: expenseCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final cat = expenseCategories[index];
                          final isChecked = currentSelected.contains(cat.id);
                          final catColor = Color(cat.colorValue);

                          return Container(
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? AppTheme.primary.withOpacity(0.12)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isChecked
                                    ? AppTheme.primary
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                width: isChecked ? 1.5 : 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isChecked,
                              onChanged: (val) {
                                setSheetState(() {
                                  if (val == true) {
                                    currentSelected.add(cat.id);
                                  } else {
                                    currentSelected.remove(cat.id);
                                  }
                                });
                              },
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              secondary: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  categoryIcons[cat.iconKey] ?? Icons.category_rounded,
                                  color: catColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                              activeColor: AppTheme.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      onSelectionChanged(currentSelected);
                      Navigator.pop(context);
                    },
                    child: const Text("Confirm Selection"),
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
