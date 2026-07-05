import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/customer_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/payment_repository.dart';

/// Repositories are stateless wrappers around the DB, so plain `Provider`s
/// (not families, not Notifiers) are enough - they're created once and
/// reused everywhere via ref.watch/ref.read.
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});
