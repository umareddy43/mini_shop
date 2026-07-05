import '../core/constants/app_constants.dart';
import 'order_item.dart';

/// Order model mapped to the `orders` table.
class Order {
  final int? id;
  final int customerId;
  final DateTime date;
  final OrderStatus status;
  final double totalAmount;

  // Convenience fields populated via joins (not persisted directly here).
  final String? customerName;
  final List<OrderItemModel> items;

  const Order({
    this.id,
    required this.customerId,
    required this.date,
    required this.status,
    required this.totalAmount,
    this.customerName,
    this.items = const [],
  });

  Order copyWith({
    int? id,
    int? customerId,
    DateTime? date,
    OrderStatus? status,
    double? totalAmount,
    String? customerName,
    List<OrderItemModel>? items,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'date': date.toIso8601String(),
      'status': status.dbValue,
      'totalAmount': totalAmount,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      date: DateTime.parse(map['date'] as String),
      status: OrderStatusX.fromDb(map['status'] as String),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      customerName: map['customerName'] as String?,
    );
  }
}
