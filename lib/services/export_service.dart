import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

class ExportService {
  static final _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
  static final _currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
  static final _currencyFormatterCompact = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

  /// Generates a CSV file of transactions/transfers and opens the system Share sheet.
  static Future<void> exportToCsv({
    required List<TransactionItem> transactions,
    required List<AccountItem> accounts,
    required List<CategoryItem> categories,
  }) async {
    final buffer = StringBuffer();

    // 1. Write metadata headers
    buffer.writeln('SpendWise Financial Export');
    buffer.writeln('Export Date,${_dateFormatter.format(DateTime.now())}');
    buffer.writeln('Total Transactions,${transactions.length}');
    buffer.writeln();

    // 2. Write Accounts Summary Table
    buffer.writeln('--- ACCOUNTS SUMMARY ---');
    buffer.writeln('Account Name,Type,Starting Balance,Limit,Current Balance/Limit');
    
    // We calculate balances directly
    for (var acc in accounts) {
      final isCc = acc.type == AccountType.creditCard;
      double utilized = 0.0;
      for (var tx in transactions) {
        if (tx.accountId == acc.id) {
          if (tx.isTransfer) {
            utilized += (acc.type == AccountType.creditCard ? tx.amount : -tx.amount);
          } else {
            if (tx.type == TransactionType.income) {
              utilized += tx.amount;
            } else {
              utilized += (acc.type == AccountType.creditCard ? tx.amount : -tx.amount);
            }
          }
        }
        if (tx.toAccountId == acc.id && tx.isTransfer) {
          utilized += (acc.type == AccountType.creditCard ? -tx.amount : tx.amount);
        }
        if (tx.categoryId == 'credit_card_payment' && tx.toAccountId == acc.id && acc.type == AccountType.creditCard) {
          utilized -= tx.amount;
        }
      }
      final currentBalance = acc.initialBalance + utilized;
      final displayBalance = isCc ? ((acc.limit ?? 0.0) - currentBalance) : currentBalance;

      buffer.writeln(
        '"${acc.name.replaceAll('"', '""')}",'
        '${acc.type == AccountType.bank ? 'Bank' : 'Credit Card'},'
        '${acc.initialBalance},'
        '${acc.limit ?? ""},'
        '${displayBalance.toStringAsFixed(2)}'
      );
    }
    buffer.writeln();

    // 3. Write Transactions Table
    buffer.writeln('--- TRANSACTION DETAILS ---');
    buffer.writeln('Date,Title,Type,Category,Source Account,Destination Account,Amount,Created By');

    for (var tx in transactions) {
      final dateStr = _dateFormatter.format(tx.date);
      final titleEscaped = tx.title.replaceAll('"', '""');
      final typeStr = tx.isTransfer ? 'Transfer' : tx.type.name.toUpperCase();
      
      final category = categories.firstWhere(
        (c) => c.id == tx.categoryId, 
        orElse: () => CategoryItem(id: 'other', name: 'Other', iconKey: 'other', colorValue: 0, type: TransactionType.expense)
      );
      final account = accounts.firstWhere(
        (a) => a.id == tx.accountId, 
        orElse: () => AccountItem(id: '', name: 'Unknown', type: AccountType.bank, initialBalance: 0, creatorId: '')
      );
      final toAccount = tx.toAccountId != null 
          ? accounts.firstWhere((a) => a.id == tx.toAccountId, orElse: () => AccountItem(id: '', name: 'Unknown', type: AccountType.bank, initialBalance: 0, creatorId: ''))
          : null;

      buffer.writeln(
        '"$dateStr",'
        '"$titleEscaped",'
        '"$typeStr",'
        '"${category.name.replaceAll('"', '""')}",'
        '"${account.name.replaceAll('"', '""')}",'
        '"${toAccount?.name.replaceAll('"', '""') ?? ""}",'
        '${tx.amount.toStringAsFixed(2)},'
        '"${tx.creatorName.replaceAll('"', '""')} (${tx.creatorEmail.replaceAll('"', '""')})"'
      );
    }

    // 4. Save to temporary directory
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/spendwise_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    // 5. Open Share Dialog
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'SpendWise Excel/CSV Export',
    );
  }

  /// Generates a styled PDF report of transactions/transfers and opens the system Share sheet.
  static Future<void> exportToPdf({
    required List<TransactionItem> transactions,
    required List<AccountItem> accounts,
    required List<CategoryItem> categories,
    required double netBalance,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final pdf = pw.Document();

    // Define styles and colors
    final primaryColor = PdfColor.fromInt(0xFF6366F1); // Indigo
    final secondaryColor = PdfColor.fromInt(0xFF8B5CF6); // Violet
    final accentGreen = PdfColor.fromInt(0xFF10B981); // Emerald
    final accentRed = PdfColor.fromInt(0xFFF43F5E); // Rose
    final greyText = PdfColor.fromInt(0xFF64748B); // Slate 500
    final dividerColor = PdfColor.fromInt(0xFFE2E8F0); // Slate 200

    // Build the PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header / Brand Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "SpendWise Financial Report",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Statement date: ${_dateFormatter.format(DateTime.now())}",
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: greyText,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  "SpendWise",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: dividerColor, thickness: 1),
            pw.SizedBox(height: 16),

            // Summary Info cards/blocks
            pw.Row(
              children: [
                _buildPdfSummaryCard(
                  "Net Worth Balance", 
                  _currencyFormatter.format(netBalance), 
                  primaryColor,
                  PdfColor.fromInt(0xFFEEF2FF), // light indigo
                  PdfColor.fromInt(0xFF3730A3), // dark indigo
                ),
                pw.SizedBox(width: 12),
                _buildPdfSummaryCard(
                  "Total Income", 
                  _currencyFormatter.format(totalIncome), 
                  accentGreen,
                  PdfColor.fromInt(0xFFECFDF5), // light emerald
                  PdfColor.fromInt(0xFF065F46), // dark emerald
                ),
                pw.SizedBox(width: 12),
                _buildPdfSummaryCard(
                  "Total Expense", 
                  _currencyFormatter.format(totalExpense), 
                  accentRed,
                  PdfColor.fromInt(0xFFFFF1F2), // light rose
                  PdfColor.fromInt(0xFF9F1239), // dark rose
                ),
              ],
            ),
            pw.SizedBox(height: 28),

            // Accounts Title
            pw.Text(
              "ACCOUNTS SUMMARY",
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: secondaryColor,
              ),
            ),
            pw.SizedBox(height: 8),

            // Accounts Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: dividerColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: primaryColor,
              ),
              cellHeight: 22,
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerCellDecoration: const pw.BoxDecoration(color: PdfColors.indigo600),
              headers: ['Account Name', 'Account Type', 'Initial Balance', 'Credit Limit', 'Available Balance/Limit'],
              data: accounts.map((acc) {
                final isCc = acc.type == AccountType.creditCard;
                double utilized = 0.0;
                for (var tx in transactions) {
                  if (tx.accountId == acc.id) {
                    if (tx.isTransfer) {
                      utilized += (acc.type == AccountType.creditCard ? tx.amount : -tx.amount);
                    } else {
                      if (tx.type == TransactionType.income) {
                        utilized += tx.amount;
                      } else {
                        utilized += (acc.type == AccountType.creditCard ? tx.amount : -tx.amount);
                      }
                    }
                  }
                  if (tx.toAccountId == acc.id && tx.isTransfer) {
                    utilized += (acc.type == AccountType.creditCard ? -tx.amount : tx.amount);
                  }
                  if (tx.categoryId == 'credit_card_payment' && tx.toAccountId == acc.id && acc.type == AccountType.creditCard) {
                    utilized -= tx.amount;
                  }
                }
                final currentBalance = acc.initialBalance + utilized;
                final displayBalance = isCc ? ((acc.limit ?? 0.0) - currentBalance) : currentBalance;

                return [
                  acc.name,
                  acc.type == AccountType.bank ? "Bank" : "Credit Card",
                  _currencyFormatterCompact.format(acc.initialBalance),
                  acc.limit != null ? _currencyFormatterCompact.format(acc.limit) : "-",
                  _currencyFormatter.format(displayBalance),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 28),

            // Transactions Title
            pw.Text(
              "TRANSACTIONS STATEMENT",
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: secondaryColor,
              ),
            ),
            pw.SizedBox(height: 8),

            // Transactions Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: dividerColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: secondaryColor,
              ),
              cellHeight: 22,
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: ['Date', 'Description', 'Type', 'Category', 'Account Details', 'Amount'],
              data: transactions.map((tx) {
                final category = categories.firstWhere(
                  (c) => c.id == tx.categoryId, 
                  orElse: () => CategoryItem(id: 'other', name: 'Other', iconKey: 'other', colorValue: 0, type: TransactionType.expense)
                );
                final account = accounts.firstWhere(
                  (a) => a.id == tx.accountId, 
                  orElse: () => AccountItem(id: '', name: 'Unknown', type: AccountType.bank, initialBalance: 0, creatorId: '')
                );
                final toAccount = tx.toAccountId != null 
                    ? accounts.firstWhere((a) => a.id == tx.toAccountId, orElse: () => AccountItem(id: '', name: 'Unknown', type: AccountType.bank, initialBalance: 0, creatorId: ''))
                    : null;

                final String typeLabel;
                if (tx.isTransfer) {
                  typeLabel = "Transfer";
                } else {
                  typeLabel = tx.type == TransactionType.income ? "Income" : "Expense";
                }

                final String accountDetails;
                if (tx.isTransfer && toAccount != null) {
                  accountDetails = "${account.name} -> ${toAccount.name}";
                } else {
                  accountDetails = account.name;
                }

                final sign = tx.isTransfer 
                    ? "" 
                    : (tx.type == TransactionType.income ? "+" : "-");

                return [
                  _dateFormatter.format(tx.date).substring(0, 10), // Date only to fit
                  tx.title,
                  typeLabel,
                  category.name,
                  accountDetails,
                  "$sign${_currencyFormatter.format(tx.amount)}",
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // Save to temporary directory
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/spendwise_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open Share Dialog
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'SpendWise PDF Statements Report',
    );
  }

  /// Builds a small summary card widget in the PDF file
  static pw.Widget _buildPdfSummaryCard(String label, String value, PdfColor color, PdfColor bgColor, PdfColor textColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          color: bgColor,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                color: textColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
