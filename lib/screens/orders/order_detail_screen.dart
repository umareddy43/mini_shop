import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/pdf_provider.dart';
import '../../providers/printer_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import '../create_order/select_items_screen.dart';

/// Order Details screen (opened by tapping an order card in the Orders
/// list or from a customer's order history in Khata).
class OrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isBusy = false;

  Future<void> _printBill() async {
    setState(() => _isBusy = true);
    try {
      final order = await ref.read(orderRepositoryProvider).getOrderById(widget.orderId);
      if (order == null) return;
      final pdfService = ref.read(pdfServiceProvider);
      final bytes = await pdfService.generateOrderBill(order);
      await pdfService.printBytes(bytes, docName: 'Bill - ${order.customerName}');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _printThermal() async {
    final order = await ref.read(orderRepositoryProvider).getOrderById(widget.orderId);
    if (order == null || !mounted) return;
    final printer = ref.read(printerServiceProvider);
    final success = await printer.printOrderReceipt(order);
    if (mounted) {
      showAppSnackBar(context, success ? 'Receipt sent to printer' : 'Printing failed',
          isError: !success);
    }
  }

  Future<void> _editOrder() async {
    final order = await ref.read(orderRepositoryProvider).getOrderById(widget.orderId);
    if (order == null || !mounted) return;

    final customer = await ref.read(customerRepositoryProvider).getCustomerById(order.customerId);
    if (customer == null || !mounted) return;

    ref.read(cartProvider.notifier).loadForEdit(
          customer: customer,
          items: order.items,
          orderId: order.id!,
          originalStatus: order.status,
        );

    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SelectItemsScreen()),
      );
      ref.invalidate(orderDetailProvider(widget.orderId));
    }
  }

  Future<void> _deleteOrder() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Order',
      message: 'This will permanently delete this order. Continue?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;

    await ref.read(orderListProvider.notifier).deleteOrder(widget.orderId);
    ref.invalidate(orderDetailProvider(widget.orderId));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleStatus(bool markDelivered) async {
    if (markDelivered) {
      await ref.read(orderListProvider.notifier).markDelivered(widget.orderId);
    } else {
      await ref.read(orderListProvider.notifier).markPending(widget.orderId);
    }
    ref.invalidate(orderDetailProvider(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load order: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customerName ?? '-',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(Formatters.dateTime(order.date)),
                          ],
                        ),
                      ),
                      StatusBadge(status: order.status),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (final line in order.items)
                      ListTile(
                        dense: true,
                        title: Text(line.itemName ?? ''),
                        subtitle: Text('${line.quantity} x ${Formatters.currency(line.price)}'),
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
                            Formatters.currency(order.totalAmount),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : _printBill,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Print Bill'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _printThermal,
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Thermal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (order.status == OrderStatus.pendingDelivery)
                ElevatedButton.icon(
                  onPressed: () => _toggleStatus(true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Delivered'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _toggleStatus(false),
                  icon: const Icon(Icons.undo),
                  label: const Text('Move Back to Pending'),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _editOrder,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _deleteOrder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }
}
