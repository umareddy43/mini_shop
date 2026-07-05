import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../models/customer.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/customer_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';
import 'select_items_screen.dart';

/// Create Order - Step 1: choose an existing customer or create a new one.
class SelectCustomerScreen extends ConsumerWidget {
  const SelectCustomerScreen({super.key});

  void _proceedWithCustomer(BuildContext context, WidgetRef ref, Customer customer) {
    ref.read(cartProvider.notifier).selectCustomer(customer);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SelectItemsScreen()),
    );
  }

  Future<void> _showAddCustomerSheet(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    bool isSaving = false;

    final createdCustomer = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(sheetContext).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Text('New Customer', style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
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
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setState(() => isSaving = true);
                              try {
                                final customer =
                                    await ref.read(customerListProvider.notifier).addCustomer(
                                          name: nameController.text,
                                          phone: phoneController.text,
                                          address: addressController.text,
                                        );
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop(customer);
                                }
                              } catch (e) {
                                setState(() => isSaving = false);
                                if (sheetContext.mounted) {
                                  showAppSnackBar(sheetContext, e.toString(), isError: true);
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save & Continue'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (createdCustomer != null && context.mounted) {
      _proceedWithCustomer(context, ref, createdCustomer);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Order · Select Customer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              hintText: 'Search customer by name or phone',
              onChanged: (q) => ref.read(customerListProvider.notifier).search(q),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.customers.isEmpty
                    ? EmptyState(
                        icon: Icons.person_search_outlined,
                        title: state.searchQuery.isEmpty
                            ? 'No customers yet'
                            : 'No customers match "${state.searchQuery}"',
                        subtitle: 'Tap "Create New Customer" below to add one.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: state.customers.length,
                        itemBuilder: (context, index) {
                          final customer = state.customers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: CustomerListTile(
                              customer: customer,
                              onTap: () => _proceedWithCustomer(context, ref, customer),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerSheet(context, ref),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Create New Customer'),
      ),
    );
  }
}
