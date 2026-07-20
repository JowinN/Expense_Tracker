import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/theme.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  void _showAddTransferSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransferSheet(),
    );
  }

  void _showTransferDetailsSheet(BuildContext context, TransactionItem transfer, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final dateStr = DateFormat('EEEE, MMMM dd, yyyy').format(transfer.date);

        final fromAcc = appState.accounts.firstWhere(
          (a) => a.id == transfer.accountId,
          orElse: () => AccountItem(
            id: 'other',
            name: 'Default Source Account',
            type: AccountType.bank,
            initialBalance: 0,
            creatorId: '',
          ),
        );

        final toAcc = transfer.toAccountId != null
            ? appState.accounts.firstWhere(
                (a) => a.id == transfer.toAccountId,
                orElse: () => AccountItem(
                  id: 'other',
                  name: 'Default Destination Account',
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
                  Text("Transfer Details", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                  backgroundColor: AppTheme.primary.withAlpha(30),
                  child: const Icon(Icons.swap_horiz, color: AppTheme.primary),
                ),
                title: Text(transfer.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(dateStr, style: TextStyle(color: theme.hintColor)),
                trailing: Text(
                  formatter.format(transfer.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("From (Source):", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(
                    "${fromAcc.name} (${fromAcc.type == AccountType.bank ? 'Bank' : 'Card'})",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (toAcc != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("To (Destination):", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(
                      "${toAcc.name} (${toAcc.type == AccountType.bank ? 'Bank' : 'Card'})",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Transferred By:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text("${transfer.creatorName} (${transfer.creatorEmail})", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
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
                        appState.deleteTransaction(transfer.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Transfer deleted")),
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
                      icon: const Icon(Icons.check),
                      label: const Text("Close"),
                      onPressed: () => Navigator.pop(context),
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    final transfers = appState.transactions.where((t) => t.isTransfer).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transfers"),
      ),
      body: transfers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 64, color: theme.hintColor),
                  const SizedBox(height: 16),
                  Text(
                    "No transfers tracked yet.",
                    style: TextStyle(color: theme.hintColor, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddTransferSheet(context),
                    child: const Text("Perform Transfer"),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transfers.length,
              separatorBuilder: (c, i) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = transfers[index];
                final dateStr = DateFormat('dd MMM yyyy').format(item.date);
                
                final fromAcc = appState.accounts.firstWhere(
                  (a) => a.id == item.accountId,
                  orElse: () => AccountItem(
                    id: '',
                    name: 'Unknown',
                    type: AccountType.bank,
                    initialBalance: 0,
                    creatorId: '',
                  ),
                );

                final toAcc = appState.accounts.firstWhere(
                  (a) => a.id == item.toAccountId,
                  orElse: () => AccountItem(
                    id: '',
                    name: 'Unknown',
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
                        content: const Text("Are you sure you want to delete this transfer? The balances will adjust back."),
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
                      const SnackBar(content: Text("Transfer deleted")),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => _showTransferDetailsSheet(context, item, appState),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primary.withAlpha((0.12 * 255).toInt()),
                              child: const Icon(Icons.swap_horiz, color: AppTheme.primary),
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
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(fromAcc.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.expenseColor)),
                                      const Icon(Icons.arrow_right_alt, size: 12),
                                      Text(toAcc.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.incomeColor)),
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
                                formatter.format(item.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: AppTheme.primary,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransferSheet(context),
        tooltip: "New Transfer",
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTransferSheet extends StatefulWidget {
  final double? prefilledAmount;
  final String? prefilledFromAccountId;
  final String? prefilledToAccountId;
  final String? unrecognizedTxIdToDelete;

  const AddTransferSheet({
    super.key,
    this.prefilledAmount,
    this.prefilledFromAccountId,
    this.prefilledToAccountId,
    this.unrecognizedTxIdToDelete,
  });

  @override
  State<AddTransferSheet> createState() => _AddTransferSheetState();
}

class _AddTransferSheetState extends State<AddTransferSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  String? _fromAccountId;
  String? _toAccountId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: "Internal Transfer");
    _amountController = TextEditingController(
      text: widget.prefilledAmount != null ? widget.prefilledAmount.toString() : '',
    );
    _selectedDate = DateTime.now();
    _fromAccountId = widget.prefilledFromAccountId;
    _toAccountId = widget.prefilledToAccountId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    final fromAccountId = _fromAccountId!;
    final toAccountId = _toAccountId!;

    await appState.addTransfer(title, amount, _selectedDate, fromAccountId, toAccountId);
    if (widget.unrecognizedTxIdToDelete != null) {
      await appState.deleteUnrecognizedTransaction(widget.unrecognizedTxIdToDelete!);
    }

    if (mounted) Navigator.pop(context);
  }

  InputDecoration _dropdownDecoration({
    required String labelText,
    required IconData prefixIcon,
    required bool isDark,
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final accounts = appState.accounts;

    // Set intelligent default values for dropdowns if null
    if (_fromAccountId == null && accounts.isNotEmpty) {
      _fromAccountId = accounts.first.id;
    }
    // Select a default target account that is different from source
    if (_toAccountId == null && accounts.length > 1) {
      _toAccountId = accounts.firstWhere((a) => a.id != _fromAccountId).id;
    }

    // Filter available target accounts
    final destinationAccounts = accounts.where((a) => a.id != _fromAccountId).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Transfer Funds",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Title Field
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: "Title (e.g. Savings Allocation)",
                  prefixIcon: Icon(Icons.title, color: AppTheme.primary),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Amount (₹)",
                  prefixIcon: Icon(Icons.monetization_on, color: AppTheme.primary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Amount is required";
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) return "Please enter a valid positive amount";
                  
                  // Optional limit validation for source account (e.g. check if source has enough balance)
                  if (_fromAccountId != null) {
                    final sourceAcc = accounts.firstWhere((a) => a.id == _fromAccountId);
                    final sourceBalance = appState.getAccountBalance(sourceAcc);
                    if (sourceAcc.type == AccountType.bank && parsed > sourceBalance) {
                      return "Insufficient balance in ${sourceAcc.name} (${currencyFormatter.format(sourceBalance)})";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Field
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      const Icon(Icons.calendar_today, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Date", style: TextStyle(fontSize: 11, color: theme.hintColor)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Source Account Dropdown
              if (accounts.isEmpty)
                const Text("Add an account first to perform transfers.", style: TextStyle(color: AppTheme.expenseColor))
              else ...[
                DropdownButtonFormField<String>(
                  value: _fromAccountId,
                  decoration: _dropdownDecoration(labelText: "From (Source Account)", prefixIcon: Icons.account_balance, isDark: isDark),
                  dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  selectedItemBuilder: (BuildContext context) {
                    return accounts.map((acc) {
                      final balance = appState.getAccountBalance(acc);
                      final isCreditCard = acc.type == AccountType.creditCard;
                      final double displayBalance = isCreditCard
                          ? ((acc.limit ?? 0.0) - balance)
                          : balance;
                      return Text(
                        isCreditCard
                            ? "${acc.name} (Limit: ${currencyFormatter.format(displayBalance)})"
                            : "${acc.name} (${currencyFormatter.format(displayBalance)})",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }).toList();
                  },
                  items: accounts.map((acc) {
                    final balance = appState.getAccountBalance(acc);
                    final isCreditCard = acc.type == AccountType.creditCard;
                    final double displayBalance = isCreditCard
                        ? ((acc.limit ?? 0.0) - balance)
                        : balance;
                    return DropdownMenuItem(
                      value: acc.id,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              acc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCreditCard ? "Available: ${currencyFormatter.format(displayBalance)}" : currencyFormatter.format(displayBalance),
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
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _fromAccountId = val;
                      // Ensure target doesn't match new source
                      if (_toAccountId == _fromAccountId) {
                        _toAccountId = null;
                      }
                    });
                  },
                  validator: (val) => val == null ? "Source account is required" : null,
                ),
                const SizedBox(height: 16),

                // Destination Account Dropdown
                DropdownButtonFormField<String>(
                  value: _toAccountId,
                  decoration: _dropdownDecoration(labelText: "To (Destination Account)", prefixIcon: Icons.login_outlined, isDark: isDark),
                  dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  selectedItemBuilder: (BuildContext context) {
                    return destinationAccounts.map((acc) {
                      final balance = appState.getAccountBalance(acc);
                      final isCreditCard = acc.type == AccountType.creditCard;
                      final double displayBalance = isCreditCard
                          ? ((acc.limit ?? 0.0) - balance)
                          : balance;
                      return Text(
                        isCreditCard
                            ? "${acc.name} (Limit: ${currencyFormatter.format(displayBalance)})"
                            : "${acc.name} (${currencyFormatter.format(displayBalance)})",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }).toList();
                  },
                  items: destinationAccounts.map((acc) {
                    final balance = appState.getAccountBalance(acc);
                    final isCreditCard = acc.type == AccountType.creditCard;
                    final double displayBalance = isCreditCard
                        ? ((acc.limit ?? 0.0) - balance)
                        : balance;
                    return DropdownMenuItem(
                      value: acc.id,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              acc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCreditCard ? "Available: ${currencyFormatter.format(displayBalance)}" : currencyFormatter.format(displayBalance),
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
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _toAccountId = val),
                  validator: (val) {
                    if (val == null) return "Destination account is required";
                    if (val == _fromAccountId) return "Source and destination cannot be the same";
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 28),

              // Action Buttons
              ElevatedButton(
                onPressed: accounts.length < 2 ? null : _saveForm,
                child: const Text("Confirm Transfer"),
              ),
              if (accounts.length < 2) ...[
                const SizedBox(height: 8),
                const Text(
                  "You must have at least 2 accounts created to perform transfers.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.warningColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
