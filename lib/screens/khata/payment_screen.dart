import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/confirm_dialog.dart';

/// Khata > Add Payment. Records a payment against the customer's khata;
/// the pending balance is recalculated automatically since it's always
/// derived (never stored) from orders minus payments.
class PaymentScreen extends ConsumerStatefulWidget {
  final int customerId;
  final String customerName;

  const PaymentScreen({super.key, required this.customerId, required this.customerName});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  PaymentMode _mode = PaymentMode.cash;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final amount = double.parse(_amountController.text.trim());
      await ref.read(paymentControllerProvider).recordPayment(
            customerId: widget.customerId,
            amount: amount,
            mode: _mode,
            remarks: _remarksController.text,
          );
      if (mounted) {
        showAppSnackBar(context, 'Payment recorded');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed to record payment: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Payment · ${widget.customerName}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount *',
                prefixText: '${AppConstants.currencySymbol} ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Amount is required';
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('Payment Mode', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: PaymentMode.values.map((mode) {
                return ChoiceChip(
                  label: Text(mode.label),
                  selected: _mode == mode,
                  onSelected: (_) => setState(() => _mode = mode),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Remarks'),
              maxLines: 2,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
