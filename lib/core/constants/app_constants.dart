/// Central place for app-wide constant values.
/// Keeping these here avoids magic strings/numbers scattered across the app.
class AppConstants {
  AppConstants._();

  // Shop details used on receipts / bills. In a real deployment these
  // would come from a "Shop Settings" screen persisted in the DB/prefs.
  static const String shopName = 'Sri Lakshmi General Store';
  static const String shopAddress = 'Main Bazar Road, Eluru, Andhra Pradesh';
  static const String shopPhone = '+91 90000 00000';

  static const String currencySymbol = '₹';

  // Units available for items.
  static const List<String> itemUnits = [
    'kg',
    'gram',
    'liter',
    'packet',
    'piece',
    'box',
  ];

  // Payment modes.
  static const List<String> paymentModes = ['Cash', 'UPI', 'Card'];

  // Bottom navigation tab titles.
  static const String tabCreateOrder = 'New Order';
  static const String tabOrders = 'Orders';
  static const String tabKhata = 'Khata';
  static const String tabItems = 'Items';
}

/// Order status values. Stored as plain strings in SQLite for simplicity
/// and easy readability when inspecting the DB directly.
enum OrderStatus { pendingDelivery, delivered }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pendingDelivery:
        return 'Pending Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  /// Value persisted in the database.
  String get dbValue => name;

  static OrderStatus fromDb(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pendingDelivery,
    );
  }
}

enum PaymentMode { cash, upi, card }

extension PaymentModeX on PaymentMode {
  String get label {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.card:
        return 'Card';
    }
  }

  String get dbValue => name;

  static PaymentMode fromDb(String value) {
    return PaymentMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMode.cash,
    );
  }

  static PaymentMode fromLabel(String label) {
    return PaymentMode.values.firstWhere(
      (e) => e.label.toLowerCase() == label.toLowerCase(),
      orElse: () => PaymentMode.cash,
    );
  }
}
