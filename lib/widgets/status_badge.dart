import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

/// Small pill badge used everywhere an order's delivery status is shown.
/// Green = Delivered, Yellow/Amber = Pending Delivery, per spec.
class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final delivered = status == OrderStatus.delivered;
    final fg = delivered ? StatusColors.delivered : StatusColors.pending;
    final bg = delivered ? StatusColors.deliveredBg : StatusColors.pendingBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            delivered ? Icons.check_circle : Icons.schedule,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
