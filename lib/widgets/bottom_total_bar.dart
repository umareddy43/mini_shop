import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';

/// The sticky "running total" bar shown at the bottom of the Select Items
/// screen, and reused wherever a total + single primary action pairing is
/// needed. Kept as a single reusable widget instead of duplicating the
/// same Container/Row markup in every screen.
class BottomTotalBar extends StatelessWidget {
  final double total;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final String? subLabel;

  const BottomTotalBar({
    super.key,
    required this.total,
    required this.buttonLabel,
    required this.onPressed,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (subLabel != null)
                    Text(
                      subLabel!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  Text(
                    Formatters.currency(total),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 170,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
