import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_form_fields.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _member = AppConstants.familyMembers.first;
  String? _category;
  String? _paymentMode = AppConstants.paymentModes.first;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSaving = true);

    final success = await ref.read(expenseControllerProvider.notifier).addExpense(
          member: _member!,
          category: _category!,
          description: _descriptionController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          paymentMode: _paymentMode!,
          date: _date,
          time: _time.format(context),
          remarks: _remarksController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save expense. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? AppConstants.expenseCategories;
    if (_category == null && categories.isNotEmpty) {
      _category = categories.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            AppDropdownField(
              label: 'Paid By',
              value: _member,
              items: AppConstants.familyMembers,
              onChanged: (v) => setState(() => _member = v),
              validator: (v) => Validators.required(v, field: 'Member'),
            ),
            const SizedBox(height: 18),
            AppDropdownField(
              label: 'Category',
              value: categories.contains(_category) ? _category : (categories.isNotEmpty ? categories.first : null),
              items: categories,
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => Validators.required(v, field: 'Category'),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Description',
              controller: _descriptionController,
              prefixIcon: Icons.notes_rounded,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Amount',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
              prefixIcon: Icons.currency_rupee_rounded,
            ),
            const SizedBox(height: 18),
            AppDropdownField(
              label: 'Payment Mode',
              value: _paymentMode,
              items: AppConstants.paymentModes,
              onChanged: (v) => setState(() => _paymentMode = v),
              validator: (v) => Validators.required(v, field: 'Payment mode'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppDateField(
                    label: 'Date',
                    value: _date,
                    onChanged: (d) => setState(() => _date = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTimeField(
                    label: 'Time',
                    value: _time,
                    onChanged: (t) => setState(() => _time = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Remarks',
              controller: _remarksController,
              maxLines: 3,
              prefixIcon: Icons.sticky_note_2_outlined,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Save Expense',
              isLoading: _isSaving,
              onPressed: _save,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

