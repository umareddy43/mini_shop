import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../printing/printer_service.dart';

/// Single shared instance so the Bluetooth connection (real or, currently,
/// stubbed) persists across screens instead of reconnecting every print.
final printerServiceProvider = Provider<PrinterService>((ref) {
  final service = StubPrinterService();
  ref.onDispose(() {
    if (service is StubPrinterService) service.dispose();
  });
  return service;
});

final printerStatusProvider = StreamProvider<PrinterConnectionStatus>((ref) {
  final service = ref.watch(printerServiceProvider);
  return service.statusStream;
});
