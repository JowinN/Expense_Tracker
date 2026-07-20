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
  final String accountId; // associated bank account or credit card
  final String? toAccountId; // target account for credit card payment transfers
  final bool isTransfer;

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
    required this.accountId,
    this.toAccountId,
    this.isTransfer = false,
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
    String? accountId,
    String? toAccountId,
    bool? isTransfer,
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
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      isTransfer: isTransfer ?? this.isTransfer,
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
      'accountId': accountId,
      'toAccountId': toAccountId,
      'isTransfer': isTransfer,
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
      accountId: json['accountId'] ?? 'default_bank',
      toAccountId: json['toAccountId'],
      isTransfer: json['isTransfer'] ?? false,
    );
  }
}

// Map mapping string keys to Flutter icons
const Map<String, IconData> categoryIcons = {
  // Food & Dining
  'food': Icons.restaurant,
  'fastfood': Icons.fastfood,
  'coffee': Icons.local_cafe,
  'grocery': Icons.local_grocery_store,
  'cake': Icons.cake,
  
  // Transport & Travel
  'transport': Icons.directions_car,
  'bus': Icons.directions_bus,
  'flight': Icons.flight,
  'subway': Icons.directions_subway,
  'taxi': Icons.local_taxi,
  'gas': Icons.local_gas_station,
  'bike': Icons.pedal_bike,
  
  // Housing & Lodging
  'rent': Icons.home,
  'hotel': Icons.hotel,
  'construction': Icons.construction,
  'furniture': Icons.chair,
  
  // Bills & Utilities
  'utilities': Icons.bolt,
  'water': Icons.water_drop,
  'phone': Icons.phone_android,
  'wifi': Icons.wifi,
  'tv': Icons.tv,
  'insurance': Icons.security,
  
  // Entertainment & Leisure
  'entertainment': Icons.movie_filter,
  'game': Icons.sports_esports,
  'music': Icons.music_note,
  'book': Icons.book,
  'sports': Icons.sports_soccer,
  
  // Health & Medical
  'health': Icons.medical_services,
  'medicine': Icons.medication,
  'spa': Icons.spa,
  'hospital': Icons.local_hospital,
  
  // Shopping
  'shopping': Icons.shopping_bag,
  'cart': Icons.shopping_cart,
  'apparel': Icons.checkroom,
  'card': Icons.credit_card,
  'electronics': Icons.devices,
  
  // Education
  'education': Icons.school,
  'science': Icons.science,
  
  // Finance & Work
  'salary': Icons.monetization_on,
  'investment': Icons.trending_up,
  'savings': Icons.savings,
  'work': Icons.work,
  'receipt': Icons.receipt_long,
  'business': Icons.business,
  
  // Family & Care
  'gift': Icons.card_giftcard,
  'pets': Icons.pets,
  'child': Icons.child_care,
  'family': Icons.people,
  
  // Fitness
  'fitness': Icons.fitness_center,
  'run': Icons.directions_run,
  
  // Personal Care
  'personal_care': Icons.face,
  'cleaning': Icons.cleaning_services,
  'salon': Icons.content_cut,
  
  // Miscellaneous
  'other': Icons.more_horiz,
};

class UnrecognizedTransaction {
  final String id;
  final double amount;
  final String? accountLast4;
  final String? toAccountLast4;
  final String rawSms;
  final DateTime date;

  UnrecognizedTransaction({
    required this.id,
    required this.amount,
    this.accountLast4,
    this.toAccountLast4,
    required this.rawSms,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'accountLast4': accountLast4,
      'toAccountLast4': toAccountLast4,
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
      rawSms: json['rawSms'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}
