import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/khata_provider.dart';
import '../../providers/pdf_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import '../orders/order_detail_screen.dart';
import 'payment_screen.dart';

/// Khata > Customer Detail: profile, running due summary, full order
/// history and full payment history, plus Add Payment / Print Statement /
/// Edit Customer actions.
class CustomerDetailScreen extends ConsumerWidget {
  final int customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  Future<void> _editCustomer(BuildContext context, WidgetRef ref, Customer customer) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone ?? '');
    final addressController = TextEditingController(text: customer.address ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Customer', style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => Validators.requiredField(v, label: 'Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  validator: Validators.optionalPhone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ref.read(customerListProvider.notifier).updateCustomer(
                            customer.copyWith(
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim().isEmpty
                                  ? null
                                  : phoneController.text.trim(),
                              address: addressController.text.trim().isEmpty
                                  ? null
                                  : addressController.text.trim(),
                            ),
                          );
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop(true);
                    } catch (e) {
                      if (sheetContext.mounted) {
                        showAppSnackBar(sheetContext, e.toString(), isError: true);
                      }
                    }
                  },
                  child: const Text('Save Changes'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    if (saved == true) {
      ref.invalidate(customerKhataDetailProvider(customerId));
    }
  }

  Future<void> _printStatement(BuildContext context, WidgetRef ref) async {
    final detail = await ref.read(customerKhataDetailProvider(customerId).future);
    if (detail == null || !context.mounted) return;

    final pdfService = ref.read(pdfServiceProvider);
    final bytes = await pdfService.generateKhataStatement(
      khata: detail.khata,
      orders: detail.orders,
      payments: detail.payments,
    );
    await pdfService.printBytes(bytes, docName: 'Statement - ${detail.khata.customer.name}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(customerKhataDetailProvider(customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Khata')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Customer not found'));
          }
          final khata = detail.khata;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(khata.customer.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      if (khata.customer.phone != null) ...[
                        const SizedBox(height: 4),
                        Text(khata.customer.phone!),
                      ],
                      if (khata.customer.address != null) ...[
                        const SizedBox(height: 4),
                        Text(khata.customer.address!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Total Due',
                      value: Formatters.currency(khata.totalOrdered),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Total Paid',
                      value: Formatters.currency(khata.totalPaid),
                      color: StatusColors.delivered,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Outstanding',
                      value: Formatters.currency(khata.pendingAmount),
                      color: khata.pendingAmount > 0 ? StatusColors.due : StatusColors.delivered,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final recorded = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              customerId: customerId,
                              customerName: khata.customer.name,
                            ),
                          ),
                        );
                        if (recorded == true) {
                          ref.invalidate(customerKhataDetailProvider(customerId));
                        }
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Add Payment'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _printStatement(context, ref),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Print Statement'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editCustomer(context, ref, khata.customer),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Customer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Order History', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (detail.orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No orders yet.'),
                )
              else
                ...detail.orders.map((order) => Card(
                      child: ListTile(
                        title: Text(Formatters.date(order.date)),
                        subtitle: Text(
                            '${order.items.length} item(s) · ${Formatters.currency(order.totalAmount)}'),
                        trailing: StatusBadge(status: order.status),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(orderId: order.id!),
                          ),
                        ),
                      ),
                    )),
              const SizedBox(height: 24),
              Text('Payment History', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (detail.payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No payments recorded yet.'),
                )
              else
                ...detail.payments.map((payment) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: Text(Formatters.currency(payment.amount)),
                        subtitle: Text(
                            '${payment.paymentMode.label} · ${Formatters.dateTime(payment.paymentDate)}'
                            '${payment.remarks != null ? ' · ${payment.remarks}' : ''}'),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
