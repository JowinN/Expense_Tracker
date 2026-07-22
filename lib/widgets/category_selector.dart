import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme.dart';

class CategorySelectorField extends StatelessWidget {
  final String label;
  final CategoryItem? selectedCategory;
  final List<CategoryItem> availableCategories;
  final ValueChanged<CategoryItem?> onCategorySelected;
  final String? placeholder;
  final bool isError;
  final String? errorText;

  const CategorySelectorField({
    super.key,
    required this.label,
    required this.selectedCategory,
    required this.availableCategories,
    required this.onCategorySelected,
    this.placeholder = "Select Category",
    this.isError = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            showCategorySelectorBottomSheet(
              context: context,
              title: label,
              selectedCategory: selectedCategory,
              availableCategories: availableCategories,
              onCategorySelected: onCategorySelected,
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
                if (selectedCategory != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(selectedCategory!.colorValue).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categoryIcons[selectedCategory!.iconKey] ?? Icons.category_rounded,
                      color: Color(selectedCategory!.colorValue),
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
                          selectedCategory!.name,
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
                          placeholder ?? "Select Category",
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

void showCategorySelectorBottomSheet({
  required BuildContext context,
  required String title,
  required CategoryItem? selectedCategory,
  required List<CategoryItem> availableCategories,
  required ValueChanged<CategoryItem?> onCategorySelected,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return CategorySelectorModalContent(
        title: title,
        selectedCategory: selectedCategory,
        availableCategories: availableCategories,
        onCategorySelected: onCategorySelected,
        isDark: isDark,
      );
    },
  );
}

class CategorySelectorModalContent extends StatefulWidget {
  final String title;
  final CategoryItem? selectedCategory;
  final List<CategoryItem> availableCategories;
  final ValueChanged<CategoryItem?> onCategorySelected;
  final bool isDark;

  const CategorySelectorModalContent({
    super.key,
    required this.title,
    required this.selectedCategory,
    required this.availableCategories,
    required this.onCategorySelected,
    required this.isDark,
  });

  @override
  State<CategorySelectorModalContent> createState() => _CategorySelectorModalContentState();
}

class _CategorySelectorModalContentState extends State<CategorySelectorModalContent> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredCategories = widget.availableCategories.where((cat) {
      if (_searchQuery.trim().isEmpty) return true;
      return cat.name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
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

          // Search Bar (if availableCategories > 5)
          if (widget.availableCategories.length > 5) ...[
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search categories...",
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

          // Category List
          Flexible(
            child: SingleChildScrollView(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredCategories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cat = filteredCategories[index];
                  final isSelected = widget.selectedCategory?.id == cat.id;
                  final catColor = Color(cat.colorValue);

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
                        widget.onCategorySelected(cat);
                        Navigator.pop(context);
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          categoryIcons[cat.iconKey] ?? Icons.category_rounded,
                          color: catColor,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        cat.name,
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
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
