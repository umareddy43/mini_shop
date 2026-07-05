import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

/// Simple customer row - used in Create Order > Select Customer.
class CustomerListTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const CustomerListTile({super.key, required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: customer.phone != null ? Text(customer.phone!) : null,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// Khata list card showing pending amount + order count.
class KhataCustomerCard extends StatelessWidget {
  final CustomerWithKhata khata;
  final VoidCallback onTap;

  const KhataCustomerCard({super.key, required this.khata, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = khata.pendingAmount;
    final hasDue = pending > 0.005;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  khata.customer.name.isNotEmpty
                      ? khata.customer.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(khata.customer.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      '${khata.totalOrders} order${khata.totalOrders == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hasDue ? StatusColors.dueBg : StatusColors.deliveredBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hasDue ? 'Due' : 'Settled',
                      style: TextStyle(
                        fontSize: 10,
                        color: hasDue ? StatusColors.due : StatusColors.delivered,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      Formatters.currency(pending.abs()),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: hasDue ? StatusColors.due : StatusColors.delivered,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
