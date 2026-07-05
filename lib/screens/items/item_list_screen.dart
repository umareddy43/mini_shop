import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../models/item.dart';
import '../../providers/item_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_card.dart';
import '../../widgets/search_field.dart';

/// Module 4: Item List. Add/Edit/Delete shop items, toggle availability,
/// search, always sorted by name (per spec).
class ItemListScreen extends ConsumerWidget {
  const ItemListScreen({super.key});

  Future<void> _showItemForm(BuildContext context, WidgetRef ref, {Item? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name ?? '');
    final priceController =
        TextEditingController(text: existing != null ? existing.price.toStringAsFixed(2) : '');
    String unit = existing?.unit ?? AppConstants.itemUnits.first;
    bool available = existing?.available ?? true;
    bool isSaving = false;

    await showModalBottomSheet<void>(
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
                    Text(existing == null ? 'Add Item' : 'Edit Item',
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Item Name *'),
                      validator: (v) => Validators.requiredField(v, label: 'Item name'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Price *',
                              prefixText: '${AppConstants.currencySymbol} ',
                            ),
                            validator: Validators.price,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: unit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: AppConstants.itemUnits
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => unit = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available'),
                      value: available,
                      onChanged: (v) => setState(() => available = v),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setState(() => isSaving = true);
                              try {
                                final notifier = ref.read(itemListProvider.notifier);
                                final price = double.parse(priceController.text.trim());
                                if (existing == null) {
                                  await notifier.addItem(
                                    name: nameController.text,
                                    price: price,
                                    unit: unit,
                                    available: available,
                                  );
                                } else {
                                  await notifier.updateItem(existing.copyWith(
                                    name: nameController.text.trim(),
                                    price: price,
                                    unit: unit,
                                    available: available,
                                  ));
                                }
                                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                              } catch (e) {
                                setState(() => isSaving = false);
                                if (sheetContext.mounted) {
                                  showAppSnackBar(sheetContext, e.toString(), isError: true);
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Item'),
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
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref, Item item) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Item',
      message: 'Delete "${item.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;
    await ref.read(itemListProvider.notifier).deleteItem(item.id!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itemListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Item List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              hintText: 'Search items',
              onChanged: (q) => ref.read(itemListProvider.notifier).search(q),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.items.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: state.searchQuery.isEmpty
                            ? 'No items yet'
                            : 'No items match "${state.searchQuery}"',
                        subtitle: 'Tap + to add your first item.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ItemCard(
                              item: item,
                              onEdit: () => _showItemForm(context, ref, existing: item),
                              onDelete: () => _deleteItem(context, ref, item),
                              onAvailabilityChanged: (_) =>
                                  ref.read(itemListProvider.notifier).toggleAvailability(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}
