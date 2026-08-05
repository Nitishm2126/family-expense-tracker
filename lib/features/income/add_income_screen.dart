import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_form_fields.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/income_provider.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String? _receivedBy = AppConstants.familyMembers.first;
  String? _source = AppConstants.incomeSources.first;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSaving = true);

    final success = await ref.read(incomeControllerProvider.notifier).addIncome(
          receivedBy: _receivedBy!,
          source: _source!,
          description: _descriptionController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          date: _date,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income saved successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save income. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Income')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            AppDropdownField(
              label: 'Received By',
              value: _receivedBy,
              items: AppConstants.familyMembers,
              onChanged: (v) => setState(() => _receivedBy = v),
              validator: (v) => Validators.required(v, field: 'Member'),
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
              label: 'Source',
              value: _source,
              items: AppConstants.incomeSources,
              onChanged: (v) => setState(() => _source = v),
              validator: (v) => Validators.required(v, field: 'Source'),
            ),
            const SizedBox(height: 18),
            AppDateField(
              label: 'Date',
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Description',
              controller: _descriptionController,
              maxLines: 3,
              prefixIcon: Icons.notes_rounded,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Save Income',
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
