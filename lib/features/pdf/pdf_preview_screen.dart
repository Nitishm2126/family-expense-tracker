import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../models/expense_model.dart';
import '../../models/income_model.dart';
import 'pdf_report_service.dart';

/// Renders the generated PDF using the `printing` package's built-in
/// preview widget, which already provides zoom, page navigation, a
/// print button, and a share button — so no custom viewer UI is needed.
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;

    final DateTimeRange range = extra?['range'] as DateTimeRange? ??
        DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now());
    final List<ExpenseModel> expenses = (extra?['expenses'] as List?)?.cast<ExpenseModel>() ?? [];
    final List<IncomeModel> incomes = (extra?['incomes'] as List?)?.cast<IncomeModel>() ?? [];

    Future<Uint8List> build(PdfPageFormat format) => PdfReportService.generateReport(
          rangeStart: range.start,
          rangeEnd: range.end,
          expenses: expenses,
          incomes: incomes,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Report')),
      body: PdfPreview(
        build: build,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: 'family_expense_report.pdf',
      ),
    );
  }
}
