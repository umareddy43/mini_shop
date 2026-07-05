import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import 'repository_providers.dart';

/// Holds the customer list + the current search query, and exposes
/// mutation methods that transparently refresh the list afterwards.
/// Used by: Create Order > Select Customer, and as the base list that the
/// Khata module further enriches with due amounts.
class CustomerListState {
  final List<Customer> customers;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const CustomerListState({
    this.customers = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  CustomerListState copyWith({
    List<Customer>? customers,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return CustomerListState(
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CustomerListNotifier extends StateNotifier<CustomerListState> {
  final CustomerRepository _repository;

  CustomerListNotifier(this._repository) : super(const CustomerListState()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final customers =
          await _repository.getAllCustomers(searchQuery: state.searchQuery);
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadCustomers();
  }

  /// Creates a new customer. Throws a [StateError] if the name is a
  /// duplicate (checked case-insensitively) so the UI can show a friendly
  /// validation message.
  Future<Customer> addCustomer({
    required String name,
    String? phone,
    String? address,
  }) async {
    final trimmedName = name.trim();
    final exists = await _repository.nameExists(trimmedName);
    if (exists) {
      throw StateError('A customer named "$trimmedName" already exists');
    }
    final customer = Customer(
      name: trimmedName,
      phone: (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
      address: (address?.trim().isEmpty ?? true) ? null : address!.trim(),
      createdAt: DateTime.now(),
    );
    final id = await _repository.insertCustomer(customer);
    await loadCustomers();
    return customer.copyWith(id: id);
  }

  Future<void> updateCustomer(Customer customer) async {
    final exists =
        await _repository.nameExists(customer.name.trim(), excludeId: customer.id);
    if (exists) {
      throw StateError('A customer named "${customer.name}" already exists');
    }
    await _repository.updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await _repository.deleteCustomer(id);
    await loadCustomers();
  }
}

final customerListProvider =
    StateNotifierProvider<CustomerListNotifier, CustomerListState>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomerListNotifier(repository);
});
