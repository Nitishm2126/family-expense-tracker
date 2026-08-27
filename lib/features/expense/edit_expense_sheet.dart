import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_form_fields.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/expense_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';

/// Bottom sheet used to edit an existing expense in place, tapped from
/// the Expense List screen.
class EditExpenseSheet extends ConsumerStatefulWidget {
  final ExpenseModel expense;
  const EditExpenseSheet({super.key, required this.expense});

  @override
  ConsumerState<EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<EditExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _descriptionController =
      TextEditingController(text: widget.expense.description);
  late final _amountController =
      TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
  late String? _member = widget.expense.member;
  late String? _category = widget.expense.category;
  late String? _paymentMode = widget.expense.paymentMode;
  late DateTime _date = widget.expense.date;
  bool _isSaving = false;

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSaving = true);

    final updated = widget.expense.copyWith(
      member: _member,
      category: _category,
      description: _descriptionController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      paymentMode: _paymentMode,
      date: _date,
    );

    final ok = await ref.read(expenseControllerProvider.notifier).updateExpense(updated);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Expense updated' : 'Failed to update expense')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? AppConstants.expenseCategories;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: math.max(MediaQuery.of(context).viewInsets.bottom, MediaQuery.of(context).padding.bottom) + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Expense', style: AppTextStyles.title(Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 16),
              AppDropdownField(
                label: 'Paid By',
                value: _member,
                items: AppConstants.familyMembers,
                onChanged: (v) => setState(() => _member = v),
              ),
              const SizedBox(height: 14),
              AppDropdownField(
                label: 'Category',
                value: categories.contains(_category) ? _category : (categories.isNotEmpty ? categories.first : null),
                items: categories,
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 14),
              AppTextField(label: 'Description', controller: _descriptionController),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Amount',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.amount,
              ),
              const SizedBox(height: 14),
              AppDropdownField(
                label: 'Payment Mode',
                value: _paymentMode,
                items: AppConstants.paymentModes,
                onChanged: (v) => setState(() => _paymentMode = v),
              ),
              const SizedBox(height: 14),
              AppDateField(label: 'Date', value: _date, onChanged: (d) => setState(() => _date = d)),
              const SizedBox(height: 22),
              PrimaryButton(label: 'Save Changes', isLoading: _isSaving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

