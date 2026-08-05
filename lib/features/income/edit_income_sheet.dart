import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_form_fields.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/income_model.dart';
import '../../providers/income_provider.dart';

class EditIncomeSheet extends ConsumerStatefulWidget {
  final IncomeModel income;
  const EditIncomeSheet({super.key, required this.income});

  @override
  ConsumerState<EditIncomeSheet> createState() => _EditIncomeSheetState();
}

class _EditIncomeSheetState extends ConsumerState<EditIncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _descriptionController =
      TextEditingController(text: widget.income.description);
  late final _amountController =
      TextEditingController(text: widget.income.amount.toStringAsFixed(2));
  late String? _receivedBy = widget.income.receivedBy;
  late String? _source = widget.income.source;
  late DateTime _date = widget.income.date;
  bool _isSaving = false;

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSaving = true);

    final updated = widget.income.copyWith(
      receivedBy: _receivedBy,
      source: _source,
      description: _descriptionController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      date: _date,
    );

    final ok = await ref.read(incomeControllerProvider.notifier).updateIncome(updated);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Income updated' : 'Failed to update income')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Income', style: AppTextStyles.title(Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 16),
              AppDropdownField(
                label: 'Received By',
                value: _receivedBy,
                items: AppConstants.familyMembers,
                onChanged: (v) => setState(() => _receivedBy = v),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Amount',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.amount,
              ),
              const SizedBox(height: 14),
              AppDropdownField(
                label: 'Source',
                value: _source,
                items: AppConstants.incomeSources,
                onChanged: (v) => setState(() => _source = v),
              ),
              const SizedBox(height: 14),
              AppDateField(label: 'Date', value: _date, onChanged: (d) => setState(() => _date = d)),
              const SizedBox(height: 14),
              AppTextField(label: 'Description', controller: _descriptionController, maxLines: 2),
              const SizedBox(height: 22),
              PrimaryButton(label: 'Save Changes', isLoading: _isSaving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
