import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

abstract class DatabaseService {
  Future<List<CategoryItem>> getCategories();
  Future<void> addCategory(CategoryItem category);
  Future<void> updateCategory(CategoryItem category); // Added category update support
  Future<void> deleteCategory(String id);

  Future<List<AccountItem>> getAccounts();
  Future<void> addAccount(AccountItem account);
  Future<void> updateAccount(AccountItem account);
  Future<void> deleteAccount(String id);

  Stream<List<TransactionItem>> streamTransactions();
  Future<void> addTransaction(TransactionItem transaction);
  Future<void> updateTransaction(TransactionItem transaction);
  Future<void> deleteTransaction(String id);

  bool get isMock;
}

class FirestoreDatabaseService implements DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  bool get isMock => false;

  @override
  Future<List<CategoryItem>> getCategories() async {
    final snapshot = await _db.collection('categories').get();
    if (snapshot.docs.isEmpty) {
      final defaults = _getDefaultCategories();
      final batch = _db.batch();
      for (var cat in defaults) {
        final docRef = _db.collection('categories').doc(cat.id);
        batch.set(docRef, cat.toJson());
      }
      await batch.commit();
      return defaults;
    }
    return snapshot.docs.map((doc) => CategoryItem.fromJson(doc.data())).toList();
  }

  @override
  Future<void> addCategory(CategoryItem category) async {
    await _db.collection('categories').doc(category.id).set(category.toJson());
  }

  @override
  Future<void> updateCategory(CategoryItem category) async {
    await _db.collection('categories').doc(category.id).update(category.toJson());
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  @override
  Future<List<AccountItem>> getAccounts() async {
    final snapshot = await _db.collection('accounts').get();
    return snapshot.docs.map((doc) => AccountItem.fromJson(doc.data())).toList();
  }

  @override
  Future<void> addAccount(AccountItem account) async {
    await _db.collection('accounts').doc(account.id).set(account.toJson());
  }

  @override
  Future<void> updateAccount(AccountItem account) async {
    await _db.collection('accounts').doc(account.id).update(account.toJson());
  }

  @override
  Future<void> deleteAccount(String id) async {
    await _db.collection('accounts').doc(id).delete();
  }

  @override
  Stream<List<TransactionItem>> streamTransactions() {
    return _db
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionItem.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<void> addTransaction(TransactionItem transaction) async {
    await _db.collection('transactions').doc(transaction.id).set(transaction.toJson());
  }

  @override
  Future<void> updateTransaction(TransactionItem transaction) async {
    await _db.collection('transactions').doc(transaction.id).update(transaction.toJson());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _db.collection('transactions').doc(id).delete();
  }
}

List<CategoryItem> _getDefaultCategories() {
  return [
    CategoryItem(id: 'salary', name: 'Salary', iconKey: 'salary', colorValue: 0xFF2ECC71, type: TransactionType.income),
    CategoryItem(id: 'investment', name: 'Investments', iconKey: 'investment', colorValue: 0xFF1ABC9C, type: TransactionType.income),
    CategoryItem(id: 'gift', name: 'Gifts & Grants', iconKey: 'gift', colorValue: 0xFF9B59B6, type: TransactionType.income),
    CategoryItem(id: 'food', name: 'Food & Dining', iconKey: 'food', colorValue: 0xFFE67E22, type: TransactionType.expense),
    CategoryItem(id: 'transport', name: 'Transport', iconKey: 'transport', colorValue: 0xFF3498DB, type: TransactionType.expense),
    CategoryItem(id: 'rent', name: 'Rent & Housing', iconKey: 'rent', colorValue: 0xFFE74C3C, type: TransactionType.expense),
    CategoryItem(id: 'utilities', name: 'Bills & Utilities', iconKey: 'utilities', colorValue: 0xFFF1C40F, type: TransactionType.expense),
    CategoryItem(id: 'entertainment', name: 'Entertainment', iconKey: 'entertainment', colorValue: 0xFF9B59B6, type: TransactionType.expense),
    CategoryItem(id: 'health', name: 'Health & Medical', iconKey: 'health', colorValue: 0xFFE74C3C, type: TransactionType.expense),
    CategoryItem(id: 'shopping', name: 'Shopping', iconKey: 'shopping', colorValue: 0xFF95A5A6, type: TransactionType.expense),
    CategoryItem(id: 'education', name: 'Education', iconKey: 'education', colorValue: 0xFF34495E, type: TransactionType.expense),
    CategoryItem(id: 'travel', name: 'Travel', iconKey: 'travel', colorValue: 0xFF1ABC9C, type: TransactionType.expense),
    CategoryItem(id: 'fitness', name: 'Fitness', iconKey: 'fitness', colorValue: 0xFF2ECC71, type: TransactionType.expense),
    CategoryItem(id: 'personal_care', name: 'Personal Care', iconKey: 'personal_care', colorValue: 0xFFE84393, type: TransactionType.expense),
    CategoryItem(id: 'work', name: 'Work', iconKey: 'work', colorValue: 0xFF2D3436, type: TransactionType.expense),
    CategoryItem(id: 'other', name: 'Other', iconKey: 'other', colorValue: 0xFF7F8C8D, type: TransactionType.expense),
  ];
}
