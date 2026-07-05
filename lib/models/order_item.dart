/// A single line item within an order, mapped to `order_items`.
/// Stores the price at the time of the order so historical bills remain
/// accurate even if the shop later changes an item's price.
class OrderItemModel {
  final int? id;
  final int? orderId;
  final int itemId;
  final int quantity;
  final double price;

  // Not persisted - populated via joins for display convenience.
  final String? itemName;
  final String? itemUnit;

  const OrderItemModel({
    this.id,
    this.orderId,
    required this.itemId,
    required this.quantity,
    required this.price,
    this.itemName,
    this.itemUnit,
  });

  double get subtotal => price * quantity;

  OrderItemModel copyWith({
    int? id,
    int? orderId,
    int? itemId,
    int? quantity,
    double? price,
    String? itemName,
    String? itemUnit,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      itemName: itemName ?? this.itemName,
      itemUnit: itemUnit ?? this.itemUnit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'itemId': itemId,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as int?,
      orderId: map['orderId'] as int?,
      itemId: map['itemId'] as int,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      itemName: map['itemName'] as String?,
      itemUnit: map['itemUnit'] as String?,
    );
  }
}
