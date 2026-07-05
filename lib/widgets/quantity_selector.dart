import 'package:flutter/material.dart';

/// The (- qty +) control used on item cards during item selection.
/// Deliberately large tap targets so a shopkeeper can operate it quickly
/// with one hand while a customer is waiting at the counter.
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = quantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            enabled: quantity > min,
            onTap: () {
              if (quantity > min) onChanged(quantity - 1);
            },
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            enabled: true,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? null : Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }
}
