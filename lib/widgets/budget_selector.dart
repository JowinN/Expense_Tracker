import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/theme.dart';

class BudgetSelectorField extends StatelessWidget {
  final String label;
  final BudgetItem? selectedBudget;
  final List<BudgetItem> availableBudgets;
  final AppState appState;
  final ValueChanged<BudgetItem?> onBudgetSelected;
  final String? placeholder;
  final bool allowAllOption;
  final String allOptionLabel;
  final bool isError;
  final String? errorText;

  const BudgetSelectorField({
    super.key,
    required this.label,
    required this.selectedBudget,
    required this.availableBudgets,
    required this.appState,
    required this.onBudgetSelected,
    this.placeholder = "Select Budget",
    this.allowAllOption = true,
    this.allOptionLabel = "None",
    this.isError = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    String valueSubtitle = "";
    if (selectedBudget != null) {
      final spent = appState.getBudgetSpent(selectedBudget!);
      valueSubtitle = "Spent: ${formatter.format(spent)} / ${formatter.format(selectedBudget!.amount)}";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            showBudgetSelectorBottomSheet(
              context: context,
              title: label,
              selectedBudget: selectedBudget,
              availableBudgets: availableBudgets,
              appState: appState,
              onBudgetSelected: onBudgetSelected,
              allowAllOption: allowAllOption,
              allOptionLabel: allOptionLabel,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isError
                    ? AppTheme.expenseColor
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: isError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (selectedBudget != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(selectedBudget!.colorValue).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categoryIcons[selectedBudget!.iconKey] ?? Icons.pie_chart_rounded,
                      color: Color(selectedBudget!.colorValue),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 2),
                        Text(
                          selectedBudget!.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    valueSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ] else ...[
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
                        const SizedBox(height: 2),
                        Text(
                          placeholder ?? "None",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
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
              ],
            ),
          ),
        ),
        if (isError && errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppTheme.expenseColor, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

void showBudgetSelectorBottomSheet({
  required BuildContext context,
  required String title,
  required BudgetItem? selectedBudget,
  required List<BudgetItem> availableBudgets,
  required AppState appState,
  required ValueChanged<BudgetItem?> onBudgetSelected,
  bool allowAllOption = true,
  String allOptionLabel = "None",
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return BudgetSelectorModalContent(
        title: title,
        selectedBudget: selectedBudget,
        availableBudgets: availableBudgets,
        appState: appState,
        onBudgetSelected: onBudgetSelected,
        allowAllOption: allowAllOption,
        allOptionLabel: allOptionLabel,
        isDark: isDark,
        formatter: formatter,
      );
    },
  );
}

class BudgetSelectorModalContent extends StatefulWidget {
  final String title;
  final BudgetItem? selectedBudget;
  final List<BudgetItem> availableBudgets;
  final AppState appState;
  final ValueChanged<BudgetItem?> onBudgetSelected;
  final bool allowAllOption;
  final String allOptionLabel;
  final bool isDark;
  final NumberFormat formatter;

  const BudgetSelectorModalContent({
    super.key,
    required this.title,
    required this.selectedBudget,
    required this.availableBudgets,
    required this.appState,
    required this.onBudgetSelected,
    required this.allowAllOption,
    required this.allOptionLabel,
    required this.isDark,
    required this.formatter,
  });

  @override
  State<BudgetSelectorModalContent> createState() => _BudgetSelectorModalContentState();
}

class _BudgetSelectorModalContentState extends State<BudgetSelectorModalContent> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredBudgets = widget.availableBudgets.where((b) {
      if (_searchQuery.trim().isEmpty) return true;
      return b.name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
    }).toList();

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
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.availableBudgets.length > 5) ...[
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search budgets...",
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.allowAllOption) ...[
                    _buildBudgetTile(
                      context,
                      budget: null,
                      isAllOption: true,
                      isSelected: widget.selectedBudget == null,
                    ),
                    const SizedBox(height: 8),
                  ],

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredBudgets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final budget = filteredBudgets[index];
                      final isSelected = widget.selectedBudget?.id == budget.id;
                      return _buildBudgetTile(
                        context,
                        budget: budget,
                        isSelected: isSelected,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTile(
    BuildContext context, {
    required BudgetItem? budget,
    bool isAllOption = false,
    required bool isSelected,
  }) {
    if (isAllOption) {
      return Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.12)
              : (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : (widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          onTap: () {
            widget.onBudgetSelected(null);
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
            child: const Icon(Icons.pie_chart_outline_rounded, color: AppTheme.primary, size: 22),
          ),
          title: Text(
            widget.allOptionLabel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22)
              : null,
        ),
      );
    }

    final spent = widget.appState.getBudgetSpent(budget!);
    final color = Color(budget.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primary.withOpacity(0.12)
            : (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.primary
              : (widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: () {
          widget.onBudgetSelected(budget);
          Navigator.pop(context);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            categoryIcons[budget.iconKey] ?? Icons.pie_chart_rounded,
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          budget.name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "Spent: ${widget.formatter.format(spent)} / ${widget.formatter.format(budget.amount)}",
          style: TextStyle(
            fontSize: 11,
            color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22)
            : null,
      ),
    );
  }
}
