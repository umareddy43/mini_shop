import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/order_item.dart';

/// In-memory draft of the order currently being built in the
/// Create Order flow (Select Customer -> Select Items -> Summary).
/// Nothing is written to the DB until the user taps Save/Print/Deliver,
/// so navigating back and forth between the three steps is free.
class CartState {
  final Customer? customer;
  final Map<int, int> quantities; // itemId -> quantity
  final Map<int, Item> itemLookup; // itemId -> Item (for price/name/unit)

  // Set when editing an existing order, so Save updates instead of inserts.
  final int? editingOrderId;
  final OrderStatus? editingOriginalStatus;

  const CartState({
    this.customer,
    this.quantities = const {},
    this.itemLookup = const {},
    this.editingOrderId,
    this.editingOriginalStatus,
  });

  bool get isEditing => editingOrderId != null;

  List<OrderItemModel> get lineItems {
    final result = <OrderItemModel>[];
    quantities.forEach((itemId, qty) {
      if (qty <= 0) return;
      final item = itemLookup[itemId];
      if (item == null) return;
      result.add(OrderItemModel(
        itemId: itemId,
        quantity: qty,
        price: item.price,
        itemName: item.name,
        itemUnit: item.unit,
      ));
    });
    // Keep a stable, readable order (alphabetical by item name).
    result.sort((a, b) => (a.itemName ?? '').compareTo(b.itemName ?? ''));
    return result;
  }

  double get grandTotal =>
      lineItems.fold(0.0, (sum, item) => sum + item.subtotal);

  int get totalItemCount =>
      quantities.values.fold(0, (sum, qty) => sum + (qty > 0 ? qty : 0));

  bool get isEmpty => totalItemCount == 0;

  CartState copyWith({
    Customer? customer,
    Map<int, int>? quantities,
    Map<int, Item>? itemLookup,
    int? editingOrderId,
    OrderStatus? editingOriginalStatus,
    bool clearEditing = false,
  }) {
    return CartState(
      customer: customer ?? this.customer,
      quantities: quantities ?? this.quantities,
      itemLookup: itemLookup ?? this.itemLookup,
      editingOrderId: clearEditing ? null : (editingOrderId ?? this.editingOrderId),
      editingOriginalStatus: clearEditing
          ? null
          : (editingOriginalStatus ?? this.editingOriginalStatus),
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void selectCustomer(Customer customer) {
    state = state.copyWith(customer: customer);
  }

  void setQuantity(Item item, int quantity) {
    if (quantity < 0) return; // guard: never allow negative quantities
    final updatedQuantities = Map<int, int>.from(state.quantities);
    final updatedLookup = Map<int, Item>.from(state.itemLookup);

    if (item.id == null) return;
    updatedQuantities[item.id!] = quantity;
    updatedLookup[item.id!] = item;

    state = state.copyWith(
      quantities: updatedQuantities,
      itemLookup: updatedLookup,
    );
  }

  void increment(Item item) {
    final current = state.quantities[item.id] ?? 0;
    setQuantity(item, current + 1);
  }

  void decrement(Item item) {
    final current = state.quantities[item.id] ?? 0;
    if (current <= 0) return;
    setQuantity(item, current - 1);
  }

  /// Loads an existing order into the cart for editing.
  void loadForEdit({
    required Customer customer,
    required List<OrderItemModel> items,
    required int orderId,
    required OrderStatus originalStatus,
  }) {
    final quantities = <int, int>{};
    final lookup = <int, Item>{};
    for (final line in items) {
      quantities[line.itemId] = line.quantity;
      lookup[line.itemId] = Item(
        id: line.itemId,
        name: line.itemName ?? '',
        price: line.price,
        unit: line.itemUnit ?? '',
      );
    }
    state = CartState(
      customer: customer,
      quantities: quantities,
      itemLookup: lookup,
      editingOrderId: orderId,
      editingOriginalStatus: originalStatus,
    );
  }

  void reset() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
