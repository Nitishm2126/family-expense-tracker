import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_model.dart';
import '../../models/income_model.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Builds the "Family Expense Tracker" PDF report: title, date range,
/// a transactions table, category totals, member totals, and a footer.
/// Kept separate from the UI so both "Download" and "Share" actions on
/// the Reports screen can reuse the exact same document.
class PdfReportService {
  static Future<Uint8List> generateReport({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<ExpenseModel> expenses,
    required List<IncomeModel> incomes,
    Map<String, double>? memberBreakdown,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final logoData = await rootBundle.load('assets/images/logo.jpg');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(fontBoldData);


    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
        bold: ttfBold,
      ),
    );

    final totalIncome = incomes.fold<double>(0, (s, i) => s + i.amount);
    final totalExpense = expenses.fold<double>(0, (s, e) => s + e.amount);

    final Map<String, double> categoryTotals = {};
    for (final e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    final Map<String, double> memberTotals = memberBreakdown ?? {
      for (final m in AppConstants.familyMembers) m: 0.0,
    };
    if (memberBreakdown == null) {
      for (final e in expenses) {
        memberTotals[e.member] = (memberTotals[e.member] ?? 0) + e.amount;
      }
    }

    final sortedExpenses = [...expenses]..sort((a, b) => b.date.compareTo(a.date));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Image(logoImage, width: 28, height: 28),
                pw.SizedBox(width: 8),
                pw.Text(
                  AppConstants.appName.toUpperCase(),
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),

            pw.SizedBox(height: 2),
            pw.Text('Expense Report', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 6),
            pw.Text(
              'Report Period: ${Formatters.date(rangeStart)} to ${Formatters.date(rangeEnd)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Generated On: ${Formatters.date(DateTime.now())} ${Formatters.time(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Divider(height: 20),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${AppConstants.appName} · Confidential Family Document',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                    pw.SizedBox(height: 2),
                    pw.Text('Designed and developed by Nitish',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Summary section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _summaryColumn('Total Income', Formatters.currency(totalIncome, withDecimals: true)),
                _summaryColumn('Total Expense', Formatters.currency(totalExpense, withDecimals: true)),
                _summaryColumn(
                  'Balance',
                  Formatters.currency(totalIncome - totalExpense, withDecimals: true),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          pw.Text('Transactions', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.4),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(1.8),
              3: pw.FlexColumnWidth(1.6),
              4: pw.FlexColumnWidth(1.4),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableHeaderCell('Date'),
                  _tableHeaderCell('Member'),
                  _tableHeaderCell('Category'),
                  _tableHeaderCell('Description'),
                  _tableHeaderCell('Amount'),
                ],
              ),
              ...sortedExpenses.map((e) => pw.TableRow(
                    children: [
                      _tableCell(Formatters.dateShort(e.date)),
                      _tableCell(e.member),
                      _tableCell(e.category),
                      _tableCell(e.description.isEmpty ? '-' : e.description),
                      _tableCell(Formatters.currency(e.amount), alignRight: true),
                    ],
                  )),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Text('Category Summary', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: categoryTotals.entries
                .map((e) => pw.TableRow(children: [
                      _tableCell(e.key),
                      _tableCell(Formatters.currency(e.value), alignRight: true),
                    ]))
                .toList(),
          ),
          pw.SizedBox(height: 20),

          pw.Text('Member Summary', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: memberTotals.entries
                .map((e) => pw.TableRow(children: [
                      _tableCell(e.key),
                      _tableCell(Formatters.currency(e.value), alignRight: true),
                    ]))
                .toList(),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _summaryColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _tableCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }
}

