import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../models/payment.dart';
import '../repositories/customer_repository.dart';
import 'repository_providers.dart';

class KhataListState {
  final List<CustomerWithKhata> customers;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const KhataListState({
    this.customers = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  KhataListState copyWith({
    List<CustomerWithKhata>? customers,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return KhataListState(
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class KhataListNotifier extends StateNotifier<KhataListState> {
  final CustomerRepository _repository;

  KhataListNotifier(this._repository) : super(const KhataListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final customers = await _repository.getAllCustomersWithKhata(
        searchQuery: state.searchQuery,
      );
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await load();
  }
}

final khataListProvider =
    StateNotifierProvider<KhataListNotifier, KhataListState>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return KhataListNotifier(repository);
});

/// Full detail bundle for a single customer's khata page: their profile +
/// due totals, full order history, and full payment history.
class CustomerKhataDetail {
  final CustomerWithKhata khata;
  final List<Order> orders;
  final List<Payment> payments;

  const CustomerKhataDetail({
    required this.khata,
    required this.orders,
    required this.payments,
  });
}

final customerKhataDetailProvider = FutureProvider.autoDispose
    .family<CustomerKhataDetail?, int>((ref, customerId) async {
  final customerRepo = ref.watch(customerRepositoryProvider);
  final orderRepo = ref.watch(orderRepositoryProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);

  final khata = await customerRepo.getCustomerWithKhata(customerId);
  if (khata == null) return null;

  final orders = await orderRepo.getOrdersForCustomer(customerId);
  final payments = await paymentRepo.getPaymentsForCustomer(customerId);

  return CustomerKhataDetail(khata: khata, orders: orders, payments: payments);
});
