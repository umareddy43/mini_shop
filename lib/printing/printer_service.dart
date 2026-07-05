import 'dart:async';

import '../models/order.dart';
import 'receipt_formatter.dart';

/// Represents a discovered Bluetooth printer. Mirrors the shape of what
/// plugins like `esc_pos_bluetooth` / `blue_thermal_printer` /
/// `print_bluetooth_thermal` typically return, so swapping the stub for a
/// real implementation later only touches [PrinterService].
class BluetoothPrinterDevice {
  final String name;
  final String address;

  const BluetoothPrinterDevice({required this.name, required this.address});
}

enum PrinterConnectionStatus { disconnected, connecting, connected }

/// Abstraction over "send this order to a 58mm thermal printer".
///
/// -----------------------------------------------------------------------
/// STATUS: STUBBED. This app currently *simulates* scanning/connecting/
/// printing so the rest of the app (Create Order, Order Details, Khata
/// statements) can be built and demoed without a physical printer.
///
/// To wire up a real printer:
///   1. Add a plugin such as `esc_pos_bluetooth`, `blue_thermal_printer`,
///      or `print_bluetooth_thermal` to pubspec.yaml.
///   2. Implement `scanForDevices`, `connect`, and `printOrderReceipt`
///      below using that plugin's API, converting the plain text from
///      [ReceiptFormatter.buildReceiptText] (or building ESC/POS commands
///      directly) into the bytes the plugin expects.
///   3. No other file in the app needs to change - every screen only
///      talks to this class via [printerServiceProvider].
/// -----------------------------------------------------------------------
abstract class PrinterService {
  Stream<PrinterConnectionStatus> get statusStream;
  PrinterConnectionStatus get currentStatus;

  Future<List<BluetoothPrinterDevice>> scanForDevices();
  Future<bool> connect(BluetoothPrinterDevice device);
  Future<void> disconnect();

  /// Prints the given order's receipt. Returns true on success.
  Future<bool> printOrderReceipt(Order order);
}

class StubPrinterService implements PrinterService {
  final _statusController =
      StreamController<PrinterConnectionStatus>.broadcast();
  PrinterConnectionStatus _status = PrinterConnectionStatus.disconnected;

  @override
  Stream<PrinterConnectionStatus> get statusStream => _statusController.stream;

  @override
  PrinterConnectionStatus get currentStatus => _status;

  void _setStatus(PrinterConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }

  @override
  Future<List<BluetoothPrinterDevice>> scanForDevices() async {
    // Simulate the couple of seconds a real Bluetooth scan takes.
    await Future.delayed(const Duration(milliseconds: 900));
    return const [
      BluetoothPrinterDevice(name: 'MPT-II 58mm Printer', address: '00:11:22:33:44:55'),
      BluetoothPrinterDevice(name: 'Goojprt PT-210', address: '66:77:88:99:AA:BB'),
    ];
  }

  @override
  Future<bool> connect(BluetoothPrinterDevice device) async {
    _setStatus(PrinterConnectionStatus.connecting);
    await Future.delayed(const Duration(milliseconds: 700));
    _setStatus(PrinterConnectionStatus.connected);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _setStatus(PrinterConnectionStatus.disconnected);
  }

  @override
  Future<bool> printOrderReceipt(Order order) async {
    // Build the exact text a real printer would receive - this is the
    // seam where a real plugin call (e.g. `printer.printCustom(...)` or
    // `printer.writeBytes(generator.text(...))`) would go.
    final receiptText = ReceiptFormatter.buildReceiptText(order);
    await Future.delayed(const Duration(milliseconds: 600));

    // ignore: avoid_print
    print('----- SIMULATED THERMAL PRINT -----\n$receiptText');
    return true;
  }

  void dispose() {
    _statusController.close();
  }
}
