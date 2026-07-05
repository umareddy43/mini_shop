import '../core/constants/app_constants.dart';

/// Payment model mapped to the `payments` table. Represents money the
/// customer has paid against their khata (running credit account).
class Payment {
  final int? id;
  final int customerId;
  final double amount;
  final PaymentMode paymentMode;
  final String? remarks;
  final DateTime paymentDate;

  const Payment({
    this.id,
    required this.customerId,
    required this.amount,
    required this.paymentMode,
    this.remarks,
    required this.paymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'amount': amount,
      'paymentMode': paymentMode.dbValue,
      'remarks': remarks,
      'paymentDate': paymentDate.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentMode: PaymentModeX.fromDb(map['paymentMode'] as String),
      remarks: map['remarks'] as String?,
      paymentDate: DateTime.parse(map['paymentDate'] as String),
    );
  }
}
