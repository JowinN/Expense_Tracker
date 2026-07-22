import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCategorySheet(),
    );
  }

  void _showCategoryDetailsSheet(BuildContext context, CategoryItem cat, AppState appState) {
    final theme = Theme.of(context);
    final transactions = appState.transactions.where((t) => t.categoryId == cat.id).toList();
    final double totalAmount = transactions.fold<double>(0, (sum, t) => sum + t.amount);
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

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
                  Text("Category Details", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Color(cat.colorValue).withAlpha(30),
                  child: Icon(categoryIcons[cat.iconKey] ?? Icons.more_horiz, color: Color(cat.colorValue), size: 24),
                ),
                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text("Type: ${cat.type.name.toUpperCase()}", style: TextStyle(color: theme.hintColor, fontSize: 12)),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Transactions:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text("${transactions.length}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cat.type == TransactionType.income ? "Total Income:" : "Total Spent:", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(
                    formatter.format(totalAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cat.type == TransactionType.income ? AppTheme.incomeColor : AppTheme.expenseColor,
                    ),
                  ),
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
                      onPressed: () async {
                        Navigator.pop(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Delete Category?"),
                            content: Text("Are you sure you want to delete '${cat.name}'? Transactions in this category will be reassigned to 'Other'."),
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
                          await appState.deleteCategory(cat.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Deleted category ${cat.name}")),
                            );
                          }
                        }
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
                        _showEditCategorySheet(context, cat);
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

  void _showEditCategorySheet(BuildContext context, CategoryItem cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCategorySheet(editingCategory: cat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final expenses = appState.categories.where((c) => c.type == TransactionType.expense).toList();
    final incomes = appState.categories.where((c) => c.type == TransactionType.income).toList();

    // Summary calculations
    final totalExpenseTx = appState.transactions.where((t) => t.type == TransactionType.expense).length;
    final totalIncomeTx = appState.transactions.where((t) => t.type == TransactionType.income).length;
    final totalExpenseAmount = appState.transactions.where((t) => t.type == TransactionType.expense).fold<double>(0, (sum, t) => sum + t.amount);
    final totalIncomeAmount = appState.transactions.where((t) => t.type == TransactionType.income).fold<double>(0, (sum, t) => sum + t.amount);
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Premium Distribution Cover Summary Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF1E1E2F), const Color(0xFF1A1A24)]
                      : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pie_chart, color: AppTheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        "Category Activity Summary",
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
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
                          const Text("Expenses Outflow", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            formatter.format(totalExpenseAmount),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.expenseColor),
                          ),
                          Text("$totalExpenseTx transactions", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      Container(width: 1.5, height: 40, color: isDark ? Colors.white24 : Colors.black12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Incomes Inflow", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            formatter.format(totalIncomeAmount),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.incomeColor),
                          ),
                          Text("$totalIncomeTx transactions", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // TabBar Cased in modern pill shape
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: isDark ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? AppTheme.primary.withAlpha(60) : Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                dividerColor: Colors.transparent,
                labelColor: isDark ? Colors.white : Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: "Expenses"),
                  Tab(text: "Income"),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CategoryGrid(items: expenses, appState: appState, onTap: (cat) => _showCategoryDetailsSheet(context, cat, appState)),
                _CategoryGrid(items: incomes, appState: appState, onTap: (cat) => _showCategoryDetailsSheet(context, cat, appState)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategorySheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<CategoryItem> items;
  final AppState appState;
  final Function(CategoryItem) onTap;

  const _CategoryGrid({required this.items, required this.appState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text("No categories added yet.", style: TextStyle(color: Colors.grey)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final catColor = Color(item.colorValue);

        final txCount = appState.transactions.where((t) => t.categoryId == item.id).length;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: catColor.withAlpha((0.25 * 255).toInt()),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: catColor.withAlpha((0.04 * 255).toInt()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => onTap(item),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: catColor.withAlpha((0.15 * 255).toInt()),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            categoryIcons[item.iconKey] ?? Icons.more_horiz,
                            color: catColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$txCount tx",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AddCategorySheet extends StatefulWidget {
  final CategoryItem? editingCategory;
  const AddCategorySheet({super.key, this.editingCategory});

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  
  late TransactionType _type;
  late String _selectedIconKey;
  late Color _selectedColor;
  String _iconSearchQuery = '';

  final List<Color> _colors = appColors.map((c) => Color(c)).toList();

  @override
  void initState() {
    super.initState();
    final cat = widget.editingCategory;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _type = cat?.type ?? TransactionType.expense;
    _selectedIconKey = cat?.iconKey ?? 'other';
    _selectedColor = cat != null ? Color(cat.colorValue) : const Color(0xFF3498DB);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final name = _nameController.text.trim();

    if (widget.editingCategory != null) {
      final updated = widget.editingCategory!.copyWith(
        name: name,
        iconKey: _selectedIconKey,
        colorValue: _selectedColor.value,
        type: _type,
      );
      await appState.updateCategory(updated);
    } else {
      await appState.addCategory(
        name,
        _selectedIconKey,
        _selectedColor.value,
        _type,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredIconKeys = categoryIcons.keys
        .where((key) => key.toLowerCase().contains(_iconSearchQuery.toLowerCase()))
        .toList();

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
                    widget.editingCategory == null ? "Create Category" : "Edit Category",
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
                      label: const Center(child: Text("Income", style: TextStyle(fontWeight: FontWeight.bold))),
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
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Dining, Streaming',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Name is required";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text("Select Color:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final color = _colors[index];
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected 
                              ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3) 
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select Icon:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text("${filteredIconKeys.length} icons found", style: TextStyle(color: theme.hintColor, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (val) => setState(() => _iconSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search icons...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredIconKeys.length,
                  itemBuilder: (context, idx) {
                    final iconKey = filteredIconKeys[idx];
                    final iconData = categoryIcons[iconKey] ?? Icons.more_horiz;
                    final isSelected = iconKey == _selectedIconKey;
                    return InkWell(
                      onTap: () => setState(() => _selectedIconKey = iconKey),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? _selectedColor.withAlpha((0.2 * 255).toInt()) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? _selectedColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(iconData, color: isSelected ? _selectedColor : theme.hintColor),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveForm,
                child: const Text("Save Category"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
