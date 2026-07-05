import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/payment.dart';
import 'khata_provider.dart';
import 'repository_providers.dart';

/// Records a payment against a customer's khata and refreshes every
/// provider that shows due amounts, so the reduction is reflected
/// instantly across the Khata list, the customer detail page, and (via
/// the dashboard provider's own dependency) the dashboard stat card.
class PaymentController {
  final Ref _ref;
  PaymentController(this._ref);

  Future<void> recordPayment({
    required int customerId,
    required double amount,
    required PaymentMode mode,
    String? remarks,
  }) async {
    final repository = _ref.read(paymentRepositoryProvider);
    final payment = Payment(
      customerId: customerId,
      amount: amount,
      paymentMode: mode,
      remarks: (remarks?.trim().isEmpty ?? true) ? null : remarks!.trim(),
      paymentDate: DateTime.now(),
    );
    await repository.insertPayment(payment);

    // Refresh dependents.
    await _ref.read(khataListProvider.notifier).load();
    _ref.invalidate(customerKhataDetailProvider(customerId));
  }
}

final paymentControllerProvider = Provider<PaymentController>((ref) {
  return PaymentController(ref);
});
