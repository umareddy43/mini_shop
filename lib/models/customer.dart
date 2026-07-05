/// Customer model mapped to the `customers` table.
class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final DateTime createdAt;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.address,
    required this.createdAt,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
