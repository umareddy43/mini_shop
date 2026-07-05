/// Shop item model mapped to the `items` table.
class Item {
  final int? id;
  final String name;
  final double price;
  final String unit;
  final bool available;

  const Item({
    this.id,
    required this.name,
    required this.price,
    required this.unit,
    this.available = true,
  });

  Item copyWith({
    int? id,
    String? name,
    double? price,
    String? unit,
    bool? available,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      available: available ?? this.available,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'unit': unit,
      'available': available ? 1 : 0,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String,
      available: (map['available'] as int) == 1,
    );
  }

  String get priceLabel => '₹${price.toStringAsFixed(2)}/$unit';
}
