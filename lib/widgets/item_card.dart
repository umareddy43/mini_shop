import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/item.dart';

/// Card used in the Item List module, with Edit / Delete actions.
class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onAvailabilityChanged;

  const ItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.available
                          ? StatusColors.deliveredBg
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.available ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.available
                            ? StatusColors.delivered
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: item.available, onChanged: onAvailabilityChanged),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
