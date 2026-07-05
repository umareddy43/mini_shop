import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../providers/item_provider.dart';
import '../../widgets/bottom_total_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_selector_card.dart';
import '../../widgets/search_field.dart';
import 'order_summary_screen.dart';

/// Create Order - Step 2: pick items with the (- qty +) selector.
/// No checkboxes - incrementing the quantity is itself "adding" the item.
class SelectItemsScreen extends ConsumerStatefulWidget {
  const SelectItemsScreen({super.key});

  @override
  ConsumerState<SelectItemsScreen> createState() => _SelectItemsScreenState();
}

class _SelectItemsScreenState extends ConsumerState<SelectItemsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final itemsAsync = ref.watch(availableItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Items · ${cart.customer?.name ?? ''}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              hintText: 'Search items',
              onChanged: (q) => setState(() => _query = q.toLowerCase()),
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load items: $e')),
              data: (items) {
                final filtered = _query.isEmpty
                    ? items
                    : items.where((i) => i.name.toLowerCase().contains(_query)).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No items found',
                    subtitle: 'Add items from the Items tab first.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final qty = cart.quantities[item.id] ?? 0;
                    return ItemSelectorCard(
                      item: item,
                      quantity: qty,
                      onQuantityChanged: (newQty) =>
                          ref.read(cartProvider.notifier).setQuantity(item, newQty),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomTotalBar(
        total: cart.grandTotal,
        subLabel: '${cart.totalItemCount} item${cart.totalItemCount == 1 ? '' : 's'} selected',
        buttonLabel: 'Review Order',
        onPressed: cart.isEmpty
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrderSummaryScreen()),
                ),
      ),
    );
  }
}
