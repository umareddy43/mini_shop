import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../repositories/order_repository.dart';
import 'repository_providers.dart';

class OrderListState {
  final List<Order> orders;
  final OrderFilter filter;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const OrderListState({
    this.orders = const [],
    this.filter = OrderFilter.all,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  OrderListState copyWith({
    List<Order>? orders,
    OrderFilter? filter,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return OrderListState(
      orders: orders ?? this.orders,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OrderListNotifier extends StateNotifier<OrderListState> {
  final OrderRepository _repository;

  OrderListNotifier(this._repository) : super(const OrderListState()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _repository.getOrders(
        filter: state.filter,
        searchQuery: state.searchQuery,
      );
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setFilter(OrderFilter filter) async {
    state = state.copyWith(filter: filter);
    await loadOrders();
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadOrders();
  }

  Future<void> markDelivered(int orderId) async {
    await _repository.updateOrderStatus(orderId, OrderStatus.delivered);
    await loadOrders();
  }

  Future<void> markPending(int orderId) async {
    await _repository.updateOrderStatus(orderId, OrderStatus.pendingDelivery);
    await loadOrders();
  }

  Future<void> deleteOrder(int orderId) async {
    await _repository.deleteOrder(orderId);
    await loadOrders();
  }
}

final orderListProvider =
    StateNotifierProvider<OrderListNotifier, OrderListState>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrderListNotifier(repository);
});

/// Fetches a single order (with items + customer name) fresh from the DB -
/// used by the Order Details screen. `.family` keyed by orderId, and
/// `autoDispose` so stale detail screens don't linger in memory.
final orderDetailProvider =
    FutureProvider.autoDispose.family<Order?, int>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrderById(orderId);
});

/// Thin façade used by the Create Order flow to persist the cart, kept
/// separate from [OrderListNotifier] since it doesn't need list/filter
/// state of its own.
class OrderCreationService {
  final OrderRepository _repository;
  OrderCreationService(this._repository);

  Future<int> saveNewOrder({
    required int customerId,
    required OrderStatus status,
    required List<OrderItemModel> items,
    required double totalAmount,
  }) {
    final order = Order(
      customerId: customerId,
      date: DateTime.now(),
      status: status,
      totalAmount: totalAmount,
    );
    return _repository.createOrder(order, items);
  }

  Future<void> updateExistingOrder({
    required int orderId,
    required int customerId,
    required DateTime originalDate,
    required OrderStatus status,
    required List<OrderItemModel> items,
    required double totalAmount,
  }) {
    final order = Order(
      id: orderId,
      customerId: customerId,
      date: originalDate,
      status: status,
      totalAmount: totalAmount,
    );
    return _repository.updateOrder(order, items);
  }
}

final orderCreationServiceProvider = Provider<OrderCreationService>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrderCreationService(repository);
});
