import 'package:flutter/material.dart';

import '../models/item.dart';
import 'quantity_selector.dart';

/// Item card used in Create Order > Select Items. Deliberately has NO
/// checkbox per spec - tapping + on the quantity selector is what adds
/// the item to the order.
class ItemSelectorCard extends StatelessWidget {
  final Item item;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  const ItemSelectorCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 1.4)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.priceLabel,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            QuantitySelector(quantity: quantity, onChanged: onQuantityChanged),
          ],
        ),
      ),
    );
  }
}
