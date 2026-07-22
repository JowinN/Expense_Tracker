import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/theme.dart';

class AccountSelectorField extends StatelessWidget {
  final String label;
  final AccountItem? selectedAccount;
  final List<AccountItem> availableAccounts;
  final AppState appState;
  final ValueChanged<AccountItem?> onAccountSelected;
  final VoidCallback? onAddAccountPressed;
  final String? placeholder;
  final bool isError;
  final String? errorText;
  final bool allowAllOption;
  final String allOptionLabel;

  const AccountSelectorField({
    super.key,
    required this.label,
    required this.selectedAccount,
    required this.availableAccounts,
    required this.appState,
    required this.onAccountSelected,
    this.onAddAccountPressed,
    this.placeholder = "Select Account",
    this.isError = false,
    this.errorText,
    this.allowAllOption = false,
    this.allOptionLabel = "All Accounts",
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    String valueSubtitle = "";
    if (selectedAccount != null) {
      final balance = appState.getAccountBalance(selectedAccount!);
      if (selectedAccount!.type == AccountType.creditCard) {
        final avail = (selectedAccount!.limit ?? 0.0) - balance;
        valueSubtitle = "${formatter.format(avail)} Available";
      } else {
        valueSubtitle = formatter.format(balance);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            showAccountSelectorBottomSheet(
              context: context,
              title: label,
              selectedAccount: selectedAccount,
              availableAccounts: availableAccounts,
              appState: appState,
              onAccountSelected: onAccountSelected,
              onAddAccountPressed: onAddAccountPressed,
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
                if (selectedAccount != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selectedAccount!.type == AccountType.creditCard
                          ? AppTheme.secondary.withOpacity(0.15)
                          : AppTheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selectedAccount!.type == AccountType.creditCard
                          ? Icons.credit_card_rounded
                          : Icons.account_balance_rounded,
                      color: selectedAccount!.type == AccountType.creditCard
                          ? AppTheme.secondary
                          : AppTheme.primary,
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
                          selectedAccount!.name,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selectedAccount!.type == AccountType.creditCard
                          ? AppTheme.incomeColor
                          : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
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
                          placeholder ?? "Select Account",
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

void showAccountSelectorBottomSheet({
  required BuildContext context,
  required String title,
  required AccountItem? selectedAccount,
  required List<AccountItem> availableAccounts,
  required AppState appState,
  required ValueChanged<AccountItem?> onAccountSelected,
  VoidCallback? onAddAccountPressed,
  bool allowAllOption = false,
  String allOptionLabel = "All Accounts",
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
      return AccountSelectorModalContent(
        title: title,
        selectedAccount: selectedAccount,
        availableAccounts: availableAccounts,
        appState: appState,
        onAccountSelected: onAccountSelected,
        onAddAccountPressed: onAddAccountPressed,
        allowAllOption: allowAllOption,
        allOptionLabel: allOptionLabel,
        isDark: isDark,
        formatter: formatter,
      );
    },
  );
}

class AccountSelectorModalContent extends StatefulWidget {
  final String title;
  final AccountItem? selectedAccount;
  final List<AccountItem> availableAccounts;
  final AppState appState;
  final ValueChanged<AccountItem?> onAccountSelected;
  final VoidCallback? onAddAccountPressed;
  final bool allowAllOption;
  final String allOptionLabel;
  final bool isDark;
  final NumberFormat formatter;

  const AccountSelectorModalContent({
    super.key,
    required this.title,
    required this.selectedAccount,
    required this.availableAccounts,
    required this.appState,
    required this.onAccountSelected,
    this.onAddAccountPressed,
    required this.allowAllOption,
    required this.allOptionLabel,
    required this.isDark,
    required this.formatter,
  });

  @override
  State<AccountSelectorModalContent> createState() => _AccountSelectorModalContentState();
}

class _AccountSelectorModalContentState extends State<AccountSelectorModalContent> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredAccounts = widget.availableAccounts.where((acc) {
      if (_searchQuery.trim().isEmpty) return true;
      return acc.name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
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

          // Header Row
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

          // Search Bar (if total available accounts > 5)
          if (widget.availableAccounts.length > 5) ...[
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search accounts...",
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

          // Account List or Empty State
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.allowAllOption) ...[
                    _buildAccountTile(
                      context,
                      account: null,
                      isAllOption: true,
                      isSelected: widget.selectedAccount == null,
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (filteredAccounts.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 48,
                            color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No accounts available for this user.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              if (widget.onAddAccountPressed != null) {
                                widget.onAddAccountPressed!();
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("Add Account"),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredAccounts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final account = filteredAccounts[index];
                        final isSelected = widget.selectedAccount?.id == account.id;
                        return _buildAccountTile(
                          context,
                          account: account,
                          isSelected: isSelected,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context, {
    required AccountItem? account,
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
            widget.onAccountSelected(null);
            Navigator.pop(context);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.apps_rounded, color: AppTheme.primary, size: 22),
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

    final balance = widget.appState.getAccountBalance(account!);
    final isCc = account.type == AccountType.creditCard;

    String subtitleValue = "";
    if (isCc) {
      final avail = (account.limit ?? 0.0) - balance;
      subtitleValue = "${widget.formatter.format(avail)} Available";
    } else {
      subtitleValue = widget.formatter.format(balance);
    }

    final iconColor = isCc ? AppTheme.secondary : AppTheme.primary;

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
          widget.onAccountSelected(account);
          Navigator.pop(context);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCc ? Icons.credit_card_rounded : Icons.account_balance_rounded,
            color: iconColor,
            size: 22,
          ),
        ),
        title: Text(
          account.name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  subtitleValue,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCc
                        ? AppTheme.incomeColor
                        : (widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                  ),
                ),
                Text(
                  isCc ? "Credit Card" : "Bank Account",
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}
