import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../models/order.dart';

/// Builds the plain-text layout for a 58mm thermal receipt (32 characters
/// per line is the standard width for 58mm paper at normal font).
///
/// This text is used both by [PrinterService] (as the payload eventually
/// sent to the printer as ESC/POS bytes) and can be inspected/tested
/// independently of any Bluetooth or PDF plumbing.
class ReceiptFormatter {
  ReceiptFormatter._();

  static const int lineWidth = 32;

  static String buildReceiptText(Order order) {
    final buffer = StringBuffer();

    buffer.writeln(_centered(AppConstants.shopName.toUpperCase()));
    buffer.writeln(_centered(AppConstants.shopAddress));
    buffer.writeln(_centered(AppConstants.shopPhone));
    buffer.writeln(_divider());
    buffer.writeln('Customer: ${order.customerName ?? '-'}');
    buffer.writeln('Date: ${Formatters.dateTime(order.date)}');
    if (order.id != null) buffer.writeln('Bill No: #${order.id}');
    buffer.writeln(_divider());
    buffer.writeln(_row('Item', 'Qty', 'Amount'));
    buffer.writeln(_divider());

    for (final line in order.items) {
      final name = line.itemName ?? 'Item';
      buffer.writeln(name);
      buffer.writeln(_row(
        '  ${line.quantity} x ${line.price.toStringAsFixed(2)}',
        '',
        line.subtotal.toStringAsFixed(2),
      ));
    }

    buffer.writeln(_divider());
    buffer.writeln(_row('TOTAL', '', Formatters.currency(order.totalAmount)));
    buffer.writeln(_divider());
    buffer.writeln(_centered('Thank You! Visit Again.'));

    return buffer.toString();
  }

  static String _divider() => '-' * lineWidth;

  static String _centered(String text) {
    if (text.length >= lineWidth) return text.substring(0, lineWidth);
    final padding = ((lineWidth - text.length) / 2).floor();
    return ' ' * padding + text;
  }

  /// Lays out a 3-column row (label, middle, amount) within [lineWidth].
  static String _row(String left, String mid, String right) {
    final rightPadded = right.padLeft(10);
    final available = lineWidth - rightPadded.length;
    final leftMid = (left + (mid.isNotEmpty ? ' $mid' : ''));
    final leftTrimmed = leftMid.length > available
        ? leftMid.substring(0, available)
        : leftMid.padRight(available);
    return '$leftTrimmed$rightPadded';
  }
}
