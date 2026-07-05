import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../printing/printer_service.dart';
import '../../providers/pdf_provider.dart';
import '../../providers/printer_provider.dart';
import '../../widgets/confirm_dialog.dart';

/// Create Order - Step 3: review items & total, then Print / Save / mark
/// the delivery status. This is also reused as the final step of the
/// "Edit Order" flow.
class OrderSummaryScreen extends ConsumerStatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  ConsumerState<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends ConsumerState<OrderSummaryScreen> {
  bool _isSaving = false;
  bool _isPrinting = false;
  late OrderStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _selectedStatus = cart.editingOriginalStatus ?? OrderStatus.pendingDelivery;
  }

  Order _buildPreviewOrder() {
    final cart = ref.read(cartProvider);
    return Order(
      id: cart.editingOrderId,
      customerId: cart.customer?.id ?? 0,
      date: DateTime.now(),
      status: _selectedStatus,
      totalAmount: cart.grandTotal,
      customerName: cart.customer?.name,
      items: cart.lineItems,
    );
  }

  Future<void> _printBill() async {
    setState(() => _isPrinting = true);
    try {
      final pdfService = ref.read(pdfServiceProvider);
      final order = _buildPreviewOrder();
      final bytes = await pdfService.generateOrderBill(order);
      await pdfService.printBytes(bytes, docName: 'Bill - ${order.customerName}');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _printThermalReceipt() async {
    final printer = ref.read(printerServiceProvider);
    final order = _buildPreviewOrder();

    if (printer.currentStatus != PrinterConnectionStatus.connected) {
      final devices = await showDialog<bool>(
        context: context,
        builder: (context) => _PrinterConnectDialog(printer: printer),
      );
      if (devices != true) return;
    }
    final success = await printer.printOrderReceipt(order);
    if (mounted) {
      showAppSnackBar(
        context,
        success ? 'Receipt sent to printer' : 'Printing failed',
        isError: !success,
      );
    }
  }

  Future<void> _save({required OrderStatus status}) async {
    final cart = ref.read(cartProvider);
    if (cart.customer?.id == null || cart.isEmpty) return;

    setState(() {
      _isSaving = true;
      _selectedStatus = status;
    });

    try {
      final service = ref.read(orderCreationServiceProvider);
      if (cart.isEditing) {
        // We don't have the original order date handy here without another
        // fetch, but keeping "today" for edited orders is an acceptable,
        // explicit trade-off - it reflects when the edit was made.
        await service.updateExistingOrder(
          orderId: cart.editingOrderId!,
          customerId: cart.customer!.id!,
          originalDate: DateTime.now(),
          status: status,
          items: cart.lineItems,
          totalAmount: cart.grandTotal,
        );
      } else {
        await service.saveNewOrder(
          customerId: cart.customer!.id!,
          status: status,
          items: cart.lineItems,
          totalAmount: cart.grandTotal,
        );
      }

      ref.invalidate(orderListProvider);
      ref.read(cartProvider.notifier).reset();

      if (mounted) {
        showAppSnackBar(context, 'Order saved successfully');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to save order: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final lineItems = cart.lineItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.person_outline),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cart.customer?.name ?? 'Unknown customer',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final line in lineItems)
                    ListTile(
                      dense: true,
                      title: Text(line.itemName ?? ''),
                      subtitle: Text(
                          '${line.quantity} x ${Formatters.currency(line.price)}'),
                      trailing: Text(
                        Formatters.currency(line.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text(
                          Formatters.currency(cart.grandTotal),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Delivery Status', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Pending Delivery'),
                  selected: _selectedStatus == OrderStatus.pendingDelivery,
                  onSelected: (_) =>
                      setState(() => _selectedStatus = OrderStatus.pendingDelivery),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Delivered'),
                  selected: _selectedStatus == OrderStatus.delivered,
                  onSelected: (_) =>
                      setState(() => _selectedStatus = OrderStatus.delivered),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _isPrinting ? null : _printBill,
            icon: _isPrinting
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Print Bill (PDF)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _printThermalReceipt,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print Receipt (Thermal Printer)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Order'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => _save(status: OrderStatus.pendingDelivery),
                  child: const Text('Keep Pending'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _save(status: OrderStatus.delivered),
                  child: const Text('Mark Delivered'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _save(status: _selectedStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Minimal Bluetooth "connect a printer" dialog backed by [PrinterService].
/// Since the service is currently stubbed, this simulates a device scan;
/// swapping in a real plugin later requires no changes here.
class _PrinterConnectDialog extends StatefulWidget {
  final PrinterService printer;
  const _PrinterConnectDialog({required this.printer});

  @override
  State<_PrinterConnectDialog> createState() => _PrinterConnectDialogState();
}

class _PrinterConnectDialogState extends State<_PrinterConnectDialog> {
  List<BluetoothPrinterDevice> _devices = [];
  bool _scanning = true;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    final devices = await widget.printer.scanForDevices();
    if (mounted) setState(() {
      _devices = devices;
      _scanning = false;
    });
  }

  Future<void> _connect(BluetoothPrinterDevice device) async {
    setState(() => _connecting = true);
    final ok = await widget.printer.connect(device);
    if (mounted) Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect Thermal Printer'),
      content: SizedBox(
        width: 300,
        child: _scanning || _connecting
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final device in _devices)
                    ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(device.name),
                      subtitle: Text(device.address),
                      onTap: () => _connect(device),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
