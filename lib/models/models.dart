import 'package:flutter/material.dart';

enum TransactionType { income, expense }

enum RecurrenceInterval { none, daily, weekly, monthly, yearly }

enum AccountType { bank, creditCard }

class AppUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'],
    );
  }
}

class AccountItem {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final double? limit; // Total limit for credit card
  final String creatorId;
  final String? userEmail; // Linked user email address
  final String? colorHex;
  final int orderIndex;
  final List<String> cardLast4;

  AccountItem({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    this.limit,
    required this.creatorId,
    this.userEmail,
    this.colorHex,
    this.orderIndex = 0,
    this.cardLast4 = const [],
  });

  AccountItem copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? initialBalance,
    double? limit,
    String? creatorId,
    String? userEmail,
    String? colorHex,
    int? orderIndex,
    List<String>? cardLast4,
  }) {
    return AccountItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      limit: limit ?? this.limit,
      creatorId: creatorId ?? this.creatorId,
      userEmail: userEmail ?? this.userEmail,
      colorHex: colorHex ?? this.colorHex,
      orderIndex: orderIndex ?? this.orderIndex,
      cardLast4: cardLast4 ?? this.cardLast4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'initialBalance': initialBalance,
      'limit': limit,
      'creatorId': creatorId,
      'userEmail': userEmail,
      'colorHex': colorHex,
      'orderIndex': orderIndex,
      'cardLast4': cardLast4,
    };
  }

  factory AccountItem.fromJson(Map<String, dynamic> json) {
    return AccountItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] == 'creditCard' ? AccountType.creditCard : AccountType.bank,
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      limit: json['limit'] != null ? (json['limit'] as num).toDouble() : null,
      creatorId: json['creatorId'] ?? '',
      userEmail: json['userEmail'],
      colorHex: json['colorHex'],
      orderIndex: json['orderIndex'] ?? 0,
      cardLast4: json['cardLast4'] != null ? List<String>.from(json['cardLast4']) : const [],
    );
  }
}

class CategoryItem {
  final String id;
  final String name;
  final String iconKey; // e.g. 'food', 'rent', mapping to Icons
  final int colorValue; // ARGB hex value
  final TransactionType type; // income, expense

  CategoryItem({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'type': type.name,
    };
  }

  CategoryItem copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? colorValue,
    TransactionType? type,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
    );
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconKey: json['iconKey'] ?? 'other',
      colorValue: json['colorValue'] ?? Colors.grey.value,
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
    );
  }
}

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String categoryId;
  final TransactionType type;
  final String creatorId;
  final String creatorEmail;
  final String creatorName;
  final bool isRecurring;
  final RecurrenceInterval recurrenceInterval;
  final DateTime? nextRecurringDate;
  final DateTime? recurringEndDate;
  final String accountId; // associated bank account or credit card
  final String? toAccountId; // target account for credit card payment transfers
  final bool isTransfer;
  final String? notes;
  final String? budgetId;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.type,
    required this.creatorId,
    required this.creatorEmail,
    required this.creatorName,
    this.isRecurring = false,
    this.recurrenceInterval = RecurrenceInterval.none,
    this.nextRecurringDate,
    this.recurringEndDate,
    required this.accountId,
    this.toAccountId,
    this.isTransfer = false,
    this.notes,
    this.budgetId,
  });

  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? categoryId,
    TransactionType? type,
    String? creatorId,
    String? creatorEmail,
    String? creatorName,
    bool? isRecurring,
    RecurrenceInterval? recurrenceInterval,
    DateTime? nextRecurringDate,
    DateTime? recurringEndDate,
    String? accountId,
    String? toAccountId,
    bool? isTransfer,
    String? notes,
    String? budgetId,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      creatorId: creatorId ?? this.creatorId,
      creatorEmail: creatorEmail ?? this.creatorEmail,
      creatorName: creatorName ?? this.creatorName,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      nextRecurringDate: nextRecurringDate ?? this.nextRecurringDate,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      isTransfer: isTransfer ?? this.isTransfer,
      notes: notes ?? this.notes,
      budgetId: budgetId ?? this.budgetId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'type': type.name,
      'creatorId': creatorId,
      'creatorEmail': creatorEmail,
      'creatorName': creatorName,
      'isRecurring': isRecurring,
      'recurrenceInterval': recurrenceInterval.name,
      'nextRecurringDate': nextRecurringDate?.toIso8601String(),
      'recurringEndDate': recurringEndDate?.toIso8601String(),
      'accountId': accountId,
      'toAccountId': toAccountId,
      'isTransfer': isTransfer,
      'notes': notes,
      'budgetId': budgetId,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      categoryId: json['categoryId'] ?? '',
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      creatorId: json['creatorId'] ?? '',
      creatorEmail: json['creatorEmail'] ?? '',
      creatorName: json['creatorName'] ?? '',
      isRecurring: json['isRecurring'] ?? false,
      recurrenceInterval: RecurrenceInterval.values.firstWhere(
        (e) => e.name == (json['recurrenceInterval'] ?? 'none'),
        orElse: () => RecurrenceInterval.none,
      ),
      nextRecurringDate: json['nextRecurringDate'] != null
          ? DateTime.tryParse(json['nextRecurringDate'])
          : null,
      recurringEndDate: json['recurringEndDate'] != null
          ? DateTime.tryParse(json['recurringEndDate'])
          : null,
      accountId: json['accountId'] ?? 'default_bank',
      toAccountId: json['toAccountId'],
      isTransfer: json['isTransfer'] ?? false,
      notes: json['notes'],
      budgetId: json['budgetId'],
    );
  }
}

// Extended list of 24 Material-inspired ARGB colors (Dark Mode friendly)
const List<int> appColors = [
  0xFF6366F1, // Indigo
  0xFF8B5CF6, // Violet
  0xFFEC4899, // Pink
  0xFFF43F5E, // Rose
  0xFFEF4444, // Red
  0xFFF97316, // Orange
  0xFFF59E0B, // Amber
  0xFFEAB308, // Yellow
  0xFF84CC16, // Lime
  0xFF10B981, // Emerald
  0xFF06B6D4, // Cyan
  0xFF0EA5E9, // Sky
  0xFF3B82F6, // Blue
  0xFF64748B, // Slate
  0xFFD946EF, // Fuchsia
  0xFFA855F7, // Purple
  0xFF14B8A6, // Teal
  0xFF22C55E, // Green
  0xFFCA8A04, // Dark Yellow
  0xFFB45309, // Amber Dark
  0xFFBE123C, // Crimson
  0xFF4338CA, // Dark Indigo
  0xFF0369A1, // Deep Blue
  0xFF047857, // Deep Emerald
];

// Map mapping string keys to Flutter icons
const Map<String, IconData> categoryIcons = {
  // Income & Salary
  'salary': Icons.monetization_on,
  'investment': Icons.trending_up,
  'savings': Icons.savings,
  'business': Icons.business,
  'gift': Icons.card_giftcard,

  // Food & Dining
  'food': Icons.restaurant,
  'fastfood': Icons.fastfood,
  'coffee': Icons.local_cafe,
  'grocery': Icons.local_grocery_store,
  'cake': Icons.cake,

  // Transport & Travel
  'transport': Icons.directions_car,
  'fuel': Icons.local_gas_station,
  'travel': Icons.flight,
  'bus': Icons.directions_bus,
  'subway': Icons.directions_subway,
  'taxi': Icons.local_taxi,
  'bike': Icons.pedal_bike,

  // Housing & Bills
  'rent': Icons.home,
  'utilities': Icons.bolt,
  'water': Icons.water_drop,
  'internet': Icons.wifi,
  'recharge': Icons.phone_android,
  'tv': Icons.tv,

  // Financial Services
  'emi': Icons.account_balance,
  'loan': Icons.account_balance_wallet,
  'insurance': Icons.security,
  'taxes': Icons.gavel,
  'credit_card': Icons.credit_card,

  // Subscriptions & Entertainment
  'subscriptions': Icons.subscriptions,
  'netflix': Icons.tv,
  'prime': Icons.video_library,
  'spotify': Icons.music_note,
  'entertainment': Icons.movie_filter,
  'game': Icons.sports_esports,

  // Health & Care
  'health': Icons.medical_services,
  'medicine': Icons.medication,
  'pets': Icons.pets,

  // Shopping & Personal
  'shopping': Icons.shopping_bag,
  'cart': Icons.shopping_cart,
  'apparel': Icons.checkroom,
  'electronics': Icons.devices,

  // Education & Work
  'education': Icons.school,
  'work': Icons.work,
  'charity': Icons.volunteer_activism,

  // Miscellaneous
  'other': Icons.more_horiz,
};

enum BudgetPeriod { weekly, monthly, yearly, custom }

class BudgetItem {
  final String id;
  final String name;
  final double amount;
  final String iconKey;
  final int colorValue;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> categoryIds;
  final bool rollover;
  final String creatorId;

  BudgetItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.iconKey,
    required this.colorValue,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.categoryIds,
    this.rollover = false,
    required this.creatorId,
  });

  BudgetItem copyWith({
    String? id,
    String? name,
    double? amount,
    String? iconKey,
    int? colorValue,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    bool? rollover,
    String? creatorId,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryIds: categoryIds ?? this.categoryIds,
      rollover: rollover ?? this.rollover,
      creatorId: creatorId ?? this.creatorId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'categoryIds': categoryIds,
      'rollover': rollover,
      'creatorId': creatorId,
    };
  }

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      iconKey: json['iconKey'] ?? 'other',
      colorValue: json['colorValue'] ?? 0xFF6366F1,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == (json['period'] ?? 'monthly'),
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now().add(const Duration(days: 30)),
      categoryIds: json['categoryIds'] != null ? List<String>.from(json['categoryIds']) : const [],
      rollover: json['rollover'] ?? false,
      creatorId: json['creatorId'] ?? '',
    );
  }
}

class BillReminderItem {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final DateTime dueDate;
  final String repeat; // 'none', 'weekly', 'monthly', 'yearly'
  final bool notificationEnabled;
  final String accountId;
  final String? notes;
  final bool isPaid;
  final String creatorId;

  BillReminderItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.dueDate,
    this.repeat = 'monthly',
    this.notificationEnabled = true,
    required this.accountId,
    this.notes,
    this.isPaid = false,
    required this.creatorId,
  });

  String get status {
    if (isPaid) return 'Paid';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (due.isBefore(today)) return 'Overdue';
    if (due.isAtSameMomentAs(today)) return 'Upcoming';
    return 'Upcoming';
  }

  BillReminderItem copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    DateTime? dueDate,
    String? repeat,
    bool? notificationEnabled,
    String? accountId,
    String? notes,
    bool? isPaid,
    String? creatorId,
  }) {
    return BillReminderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      dueDate: dueDate ?? this.dueDate,
      repeat: repeat ?? this.repeat,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      accountId: accountId ?? this.accountId,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      creatorId: creatorId ?? this.creatorId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'dueDate': dueDate.toIso8601String(),
      'repeat': repeat,
      'notificationEnabled': notificationEnabled,
      'accountId': accountId,
      'notes': notes,
      'isPaid': isPaid,
      'creatorId': creatorId,
    };
  }

  factory BillReminderItem.fromJson(Map<String, dynamic> json) {
    return BillReminderItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['categoryId'] ?? 'utilities',
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      repeat: json['repeat'] ?? 'monthly',
      notificationEnabled: json['notificationEnabled'] ?? true,
      accountId: json['accountId'] ?? '',
      notes: json['notes'],
      isPaid: json['isPaid'] ?? false,
      creatorId: json['creatorId'] ?? '',
    );
  }
}

class NotificationSettings {
  final bool budgetExceeded;
  final bool upcomingBill;
  final bool recurringExecuted;
  final bool recurringDueSoon;
  final bool billOverdue;
  final bool budgetEndingSoon;
  final bool generalNotifications;

  const NotificationSettings({
    this.budgetExceeded = true,
    this.upcomingBill = true,
    this.recurringExecuted = true,
    this.recurringDueSoon = true,
    this.billOverdue = true,
    this.budgetEndingSoon = true,
    this.generalNotifications = true,
  });

  NotificationSettings copyWith({
    bool? budgetExceeded,
    bool? upcomingBill,
    bool? recurringExecuted,
    bool? recurringDueSoon,
    bool? billOverdue,
    bool? budgetEndingSoon,
    bool? generalNotifications,
  }) {
    return NotificationSettings(
      budgetExceeded: budgetExceeded ?? this.budgetExceeded,
      upcomingBill: upcomingBill ?? this.upcomingBill,
      recurringExecuted: recurringExecuted ?? this.recurringExecuted,
      recurringDueSoon: recurringDueSoon ?? this.recurringDueSoon,
      billOverdue: billOverdue ?? this.billOverdue,
      budgetEndingSoon: budgetEndingSoon ?? this.budgetEndingSoon,
      generalNotifications: generalNotifications ?? this.generalNotifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budgetExceeded': budgetExceeded,
      'upcomingBill': upcomingBill,
      'recurringExecuted': recurringExecuted,
      'recurringDueSoon': recurringDueSoon,
      'billOverdue': billOverdue,
      'budgetEndingSoon': budgetEndingSoon,
      'generalNotifications': generalNotifications,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      budgetExceeded: json['budgetExceeded'] ?? true,
      upcomingBill: json['upcomingBill'] ?? true,
      recurringExecuted: json['recurringExecuted'] ?? true,
      recurringDueSoon: json['recurringDueSoon'] ?? true,
      billOverdue: json['billOverdue'] ?? true,
      budgetEndingSoon: json['budgetEndingSoon'] ?? true,
      generalNotifications: json['generalNotifications'] ?? true,
    );
  }
}

class UnrecognizedTransaction {
  final String id;
  final double amount;
  final String? accountLast4;
  final String? toAccountLast4;
  final String? type;
  final String rawSms;
  final DateTime date;

  UnrecognizedTransaction({
    required this.id,
    required this.amount,
    this.accountLast4,
    this.toAccountLast4,
    this.type,
    required this.rawSms,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'accountLast4': accountLast4,
      'toAccountLast4': toAccountLast4,
      'type': type,
      'rawSms': rawSms,
      'date': date.toIso8601String(),
    };
  }

  factory UnrecognizedTransaction.fromJson(Map<String, dynamic> json) {
    return UnrecognizedTransaction(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      accountLast4: json['accountLast4'],
      toAccountLast4: json['toAccountLast4'],
      type: json['type'],
      rawSms: json['rawSms'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}

