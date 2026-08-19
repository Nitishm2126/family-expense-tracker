import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_form_fields.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/member_provider.dart';

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

  String? _memberId;
  String? _memberName;
  String? _categoryId;
  String? _categoryName;
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

    // Validate member selection
    if (_memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a family member.')),
      );
      return;
    }

    // Validate required fields
    final description = _descriptionController.text.trim();
    final amountText = _amountController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description.')),
      );
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await ref.read(expenseControllerProvider.notifier).addExpense(
          memberId: _memberId,
          categoryId: _categoryId,
          member: _memberName ?? 'Unknown',
          category: _categoryName ?? 'Others',
          description: description,
          amount: amount,
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
      // Show the actual error from the provider
      final errorMsg = ref.read(expenseControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Could not save expense. Please try again.'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberState = ref.watch(memberControllerProvider);
    final categories = ref.watch(categoriesProvider).value ?? AppConstants.expenseCategories;
    if (_categoryName == null && categories.isNotEmpty) {
      _categoryName = categories.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Member selector with proper state handling
            _buildMemberSelector(memberState),
            const SizedBox(height: 18),
            AppDropdownField(
              label: 'Category',
              value: categories.contains(_categoryName) ? _categoryName : (categories.isNotEmpty ? categories.first : null),
              items: categories,
              onChanged: (v) => setState(() => _categoryName = v),
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

  Widget _buildMemberSelector(MemberState memberState) {
    switch (memberState.status) {
      case MemberStatus.loading:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading members...'),
            ],
          ),
        );

      case MemberStatus.loaded:
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Paid By',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          value: _memberId,
          items: memberState.members.map((m) {
            return DropdownMenuItem<String>(
              value: m['id'].toString(),
              child: Text(m['name'].toString()),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _memberId = val;
              _memberName = memberState.members
                  .firstWhere((m) => m['id'].toString() == val)['name']
                  .toString();
            });
          },
          validator: (v) => v == null ? 'Please select a member' : null,
        );

      case MemberStatus.empty:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.orange.withValues(alpha: 0.05),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No family members found. Please add members first.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        );

      case MemberStatus.error:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.red.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  memberState.errorMessage ?? 'Failed to load members',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => ref.read(memberControllerProvider.notifier).retry(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
    }
  }
}
