import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = FirebaseAuthService();
  final DatabaseService _databaseService = FirestoreDatabaseService();

  AppUser? _currentUser;
  List<TransactionItem> _transactions = [];
  List<CategoryItem> _categories = [];
  List<AccountItem> _accounts = [];
  List<UnrecognizedTransaction> _unrecognizedTransactions = [];
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = false;
  bool _isLoadingTransactions = false;

  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<List<TransactionItem>>? _transactionSubscription;

  static const _channel = MethodChannel('com.family.spendwise/sms');

  AppState() {
    _initAuthStream();
    _initMethodChannel();
    _loadUnrecognizedTransactions();
    Future.delayed(const Duration(seconds: 1), () => checkPendingTransaction());
  }

  // Getters
  AuthService get authService => _authService;
  DatabaseService get databaseService => _databaseService;
  AppUser? get currentUser => _currentUser;
  List<TransactionItem> get transactions => _transactions;
  List<CategoryItem> get categories => _categories;
  List<AccountItem> get accounts => _accounts;
  List<UnrecognizedTransaction> get unrecognizedTransactions => _unrecognizedTransactions;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isMockMode => false;

  // Theme Settings
  void updateThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void _initAuthStream() {
    _authSubscription?.cancel();
    _authSubscription = _authService.onAuthStateChanged.listen((user) {
      _currentUser = user;
      notifyListeners();
      if (user != null) {
        _loadCategories();
        _loadAccounts();
        _subscribeToTransactions();
      } else {
        _unsubscribeTransactions();
        _transactions = [];
        _accounts = [];
        notifyListeners();
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _databaseService.getCategories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadAccounts() async {
    try {
      _accounts = await _databaseService.getAccounts();
      _accounts.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      notifyListeners();
    } catch (_) {}
  }

  void _subscribeToTransactions() {
    _isLoadingTransactions = true;
    notifyListeners();
    
    _transactionSubscription?.cancel();
    _transactionSubscription = _databaseService.streamTransactions().listen(
      (list) {
        _transactions = list;
        _isLoadingTransactions = false;
        notifyListeners();
        // Check and generate any due recurring transaction instances
        _processRecurringTransactions(list);
      },
      onError: (_) {
        _isLoadingTransactions = false;
        notifyListeners();
      },
    );
  }

  void _unsubscribeTransactions() {
    _transactionSubscription?.cancel();
    _transactionSubscription = null;
  }

  // Dynamic Account Balance Calculations
  double getAccountBalance(AccountItem account) {
    double balance = account.initialBalance;
    for (var tx in _transactions) {
      if (tx.isTransfer) {
        if (tx.accountId == account.id) {
          if (account.type == AccountType.creditCard) {
            balance += tx.amount;
          } else {
            balance -= tx.amount;
          }
        }
        if (tx.toAccountId == account.id) {
          if (account.type == AccountType.creditCard) {
            balance -= tx.amount;
          } else {
            balance += tx.amount;
          }
        }
        continue;
      }
      // 1. Transaction affects this account directly
      if (tx.accountId == account.id) {
        if (tx.type == TransactionType.income) {
          balance += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          if (account.type == AccountType.creditCard) {
            balance += tx.amount; // spent increases credit card used limit
          } else {
            balance -= tx.amount; // spent decreases bank balance
          }
        }
      }
      // 2. Transaction is a credit card payment *to* this credit card from another bank account
      if (tx.categoryId == 'credit_card_payment' && tx.toAccountId == account.id && account.type == AccountType.creditCard) {
        balance -= tx.amount; // credit card payment reduces the used limit
      }
    }
    return balance;
  }

  double get netBalance {
    double totalBank = 0;
    double totalCredit = 0;
    for (var acc in _accounts) {
      double bal = getAccountBalance(acc);
      if (acc.type == AccountType.bank) {
        totalBank += bal;
      } else {
        totalCredit += bal;
      }
    }
    return totalBank - totalCredit;
  }

  double get totalIncome {
    double total = 0;
    for (var tx in _transactions) {
      if (tx.isTransfer) continue;
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      }
    }
    return total;
  }

  double get totalExpense {
    double total = 0;
    for (var tx in _transactions) {
      if (tx.isTransfer) continue;
      if (tx.type == TransactionType.expense) {
        total += tx.amount;
      }
    }
    return total;
  }

  // Recurrency engine
  bool _processingRecurring = false;
  Future<void> _processRecurringTransactions(List<TransactionItem> list) async {
    if (_processingRecurring || _currentUser == null) return;
    _processingRecurring = true;

    final now = DateTime.now();

    try {
      for (var transaction in list) {
        if (transaction.isRecurring && transaction.nextRecurringDate != null) {
          DateTime nextDate = transaction.nextRecurringDate!;
          if (nextDate.isBefore(now)) {
            List<TransactionItem> newInstances = [];
            
            while (nextDate.isBefore(now)) {
              final String newId = 'recur_${transaction.id}_${nextDate.year}_${nextDate.month}_${nextDate.day}';
              
              final newInstance = TransactionItem(
                id: newId,
                title: "${transaction.title} (Recurring)",
                amount: transaction.amount,
                date: nextDate,
                categoryId: transaction.categoryId,
                type: transaction.type,
                creatorId: transaction.creatorId,
                creatorEmail: transaction.creatorEmail,
                creatorName: transaction.creatorName,
                isRecurring: false,
                accountId: transaction.accountId,
              );
              newInstances.add(newInstance);
              
              // Advance recurrence anchored on the original date day
              nextDate = calculateNextRecurringDateFromAnchor(nextDate, transaction.date, transaction.recurrenceInterval);
            }

            for (var instance in newInstances) {
              await _databaseService.addTransaction(instance);
            }

            final updatedTemplate = transaction.copyWith(
              nextRecurringDate: nextDate,
            );
            await _databaseService.updateTransaction(updatedTemplate);
          }
        }
      }
    } catch (_) {
    } finally {
      _processingRecurring = false;
    }
  }

  DateTime calculateNextRecurringDateFromAnchor(DateTime current, DateTime anchor, RecurrenceInterval interval) {
    switch (interval) {
      case RecurrenceInterval.daily:
        return current.add(const Duration(days: 1));
      case RecurrenceInterval.weekly:
        return current.add(const Duration(days: 7));
      case RecurrenceInterval.monthly:
        int year = current.year;
        int month = current.month + 1;
        if (month > 12) {
          month = 1;
          year += 1;
        }
        int day = anchor.day;
        int maxDays = DateUtils.getDaysInMonth(year, month);
        if (day > maxDays) {
          day = maxDays;
        }
        return DateTime(year, month, day, anchor.hour, anchor.minute);
      case RecurrenceInterval.yearly:
        return DateTime(current.year + 1, anchor.month, anchor.day, anchor.hour, anchor.minute);
      case RecurrenceInterval.none:
        return current;
    }
  }

  // Authentication Actions
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.loginWithEmailAndPassword(email, password);
      return true;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String name, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.registerWithEmailAndPassword(email, name, password);
      return true;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Database Actions - Accounts
  Future<void> addAccount(String name, AccountType type, double initialBalance, {double? limit, String? colorHex, List<String> cardLast4 = const []}) async {
    if (_currentUser == null) return;
    final newAccount = AccountItem(
      id: 'acc_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: type,
      initialBalance: initialBalance,
      limit: limit,
      creatorId: _currentUser!.id,
      colorHex: colorHex,
      orderIndex: _accounts.length,
      cardLast4: cardLast4,
    );
    await _databaseService.addAccount(newAccount);
    await _loadAccounts();
  }

  Future<void> updateAccount(AccountItem account) async {
    await _databaseService.updateAccount(account);
    await _loadAccounts();
  }

  Future<void> updateAccountsOrder(List<AccountItem> orderedAccounts) async {
    final futures = <Future<void>>[];
    for (int i = 0; i < orderedAccounts.length; i++) {
      final acc = orderedAccounts[i].copyWith(orderIndex: i);
      futures.add(_databaseService.updateAccount(acc));
    }
    await Future.wait(futures);
    await _loadAccounts();
  }

  Future<void> deleteAccount(String id) async {
    await _databaseService.deleteAccount(id);
    // Relocate transactions linked to deleted account
    for (var tx in _transactions) {
      if (tx.accountId == id) {
        await _databaseService.updateTransaction(tx.copyWith(accountId: 'default_bank'));
      }
      if (tx.toAccountId == id) {
        await _databaseService.updateTransaction(tx.copyWith(toAccountId: null));
      }
    }
    await _loadAccounts();
  }

  // Database Actions - Transactions
  Future<void> addTransaction(
    String title,
    double amount,
    DateTime date,
    String categoryId,
    TransactionType type,
    String accountId, {
    bool isRecurring = false,
    RecurrenceInterval recurrenceInterval = RecurrenceInterval.none,
    String? toAccountId,
  }) async {
    if (_currentUser == null) return;

    DateTime? nextRecDate;
    if (isRecurring && recurrenceInterval != RecurrenceInterval.none) {
      nextRecDate = calculateNextRecurringDateFromAnchor(date, date, recurrenceInterval);
    }

    final newTransaction = TransactionItem(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      amount: amount,
      date: date,
      categoryId: categoryId,
      type: type,
      creatorId: _currentUser!.id,
      creatorEmail: _currentUser!.email,
      creatorName: _currentUser!.name,
      isRecurring: isRecurring,
      recurrenceInterval: recurrenceInterval,
      nextRecurringDate: nextRecDate,
      accountId: accountId,
      toAccountId: toAccountId,
    );

    await _databaseService.addTransaction(newTransaction);
  }

  Future<void> addTransfer(
    String title,
    double amount,
    DateTime date,
    String fromAccountId,
    String toAccountId,
  ) async {
    if (_currentUser == null) return;

    final newTransfer = TransactionItem(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      amount: amount,
      date: date,
      categoryId: 'transfer',
      type: TransactionType.expense,
      creatorId: _currentUser!.id,
      creatorEmail: _currentUser!.email,
      creatorName: _currentUser!.name,
      accountId: fromAccountId,
      toAccountId: toAccountId,
      isTransfer: true,
    );

    await _databaseService.addTransaction(newTransfer);
  }

  Future<void> updateTransaction(TransactionItem transaction) async {
    DateTime? nextRecDate = transaction.nextRecurringDate;
    if (transaction.isRecurring && transaction.recurrenceInterval != RecurrenceInterval.none && nextRecDate == null) {
      nextRecDate = calculateNextRecurringDateFromAnchor(transaction.date, transaction.date, transaction.recurrenceInterval);
    } else if (!transaction.isRecurring) {
      nextRecDate = null;
    }
    final updatedTx = transaction.copyWith(nextRecurringDate: nextRecDate);
    await _databaseService.updateTransaction(updatedTx);
  }

  Future<void> snoozeRecurringTransaction(TransactionItem transaction, DateTime newPushedDate) async {
    final updated = transaction.copyWith(nextRecurringDate: newPushedDate);
    await _databaseService.updateTransaction(updated);
  }

  Future<void> deleteTransaction(String id) async {
    await _databaseService.deleteTransaction(id);
  }

  // Database Actions - Categories
  Future<void> addCategory(String name, String iconKey, int colorValue, TransactionType type) async {
    final newCategory = CategoryItem(
      id: 'cat_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      iconKey: iconKey,
      colorValue: colorValue,
      type: type,
    );

    await _databaseService.addCategory(newCategory);
    await _loadCategories();
  }

  Future<void> updateCategory(CategoryItem category) async {
    await _databaseService.updateCategory(category);
    await _loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _databaseService.deleteCategory(id);
    for (var tx in _transactions) {
      if (tx.categoryId == id) {
        await _databaseService.updateTransaction(tx.copyWith(categoryId: 'other'));
      }
    }
    await _loadCategories();
  }

  void _initMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onTransactionDetected") {
        final map = Map<String, dynamic>.from(call.arguments);
        final tx = UnrecognizedTransaction(
          id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          amount: (map['amount'] as num).toDouble(),
          accountLast4: map['accountLast4'],
          rawSms: map['rawSms'] ?? '',
          date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
        );
        await addUnrecognizedTransaction(tx);
      }
    });
  }

  Future<void> checkPendingTransaction() async {
    try {
      final pending = await _channel.invokeMethod<Map<dynamic, dynamic>>('getPendingTransaction');
      if (pending != null) {
        final map = Map<String, dynamic>.from(pending);
        final tx = UnrecognizedTransaction(
          id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          amount: (map['amount'] as num).toDouble(),
          accountLast4: map['accountLast4'],
          rawSms: map['rawSms'] ?? '',
          date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
        );
        await addUnrecognizedTransaction(tx);
      }
    } catch (_) {}
  }

  Future<void> _loadUnrecognizedTransactions() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/unrecognized_transactions.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final list = jsonDecode(contents) as List<dynamic>;
        _unrecognizedTransactions = list.map((item) => UnrecognizedTransaction.fromJson(item)).toList();
      } else {
        _unrecognizedTransactions = [];
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveUnrecognizedTransactions() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/unrecognized_transactions.json');
      final contents = jsonEncode(_unrecognizedTransactions.map((item) => item.toJson()).toList());
      await file.writeAsString(contents);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteUnrecognizedTransaction(String id) async {
    _unrecognizedTransactions.removeWhere((t) => t.id == id);
    await _saveUnrecognizedTransactions();
  }

  Future<void> addUnrecognizedTransaction(UnrecognizedTransaction tx) async {
    if (_unrecognizedTransactions.any((item) => item.id == tx.id)) return;
    _unrecognizedTransactions.add(tx);
    await _saveUnrecognizedTransactions();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _transactionSubscription?.cancel();
    super.dispose();
  }
}
