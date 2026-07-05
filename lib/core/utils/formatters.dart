import 'package:intl/intl.dart';

/// Centralised date/currency formatting so every screen renders values
/// identically (dashboard, bills, receipts, khata statements, etc).
class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final DateFormat _dateOnly = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeOnly = DateFormat('hh:mm a');

  static String currency(double amount) => _currency.format(amount);

  static String date(DateTime dateTime) => _dateOnly.format(dateTime);

  static String dateTime(DateTime dateTime) => _dateTime.format(dateTime);

  static String time(DateTime dateTime) => _timeOnly.format(dateTime);

  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }
}
