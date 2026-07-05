import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../providers/dashboard_provider.dart';

/// The 5 dashboard stats required by the spec, shown as a horizontally
/// scrollable row of stat cards at the top of the Orders tab - the
/// natural "home base" screen a shopkeeper opens the app to.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 96,
        child: Center(child: Text('Could not load stats: $e')),
      ),
      data: (stats) => SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _StatCard(
              label: "Today's Sales",
              value: Formatters.currency(stats.todaysSales),
              icon: Icons.trending_up,
              color: StatusColors.delivered,
            ),
            _StatCard(
              label: 'Pending Deliveries',
              value: '${stats.pendingDeliveries}',
              icon: Icons.local_shipping_outlined,
              color: StatusColors.pending,
            ),
            _StatCard(
              label: 'Pending Khata',
              value: Formatters.currency(stats.pendingKhataAmount),
              icon: Icons.account_balance_wallet_outlined,
              color: StatusColors.due,
            ),
            _StatCard(
              label: 'Total Customers',
              value: '${stats.totalCustomers}',
              icon: Icons.people_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            _StatCard(
              label: 'Total Orders',
              value: '${stats.totalOrders}',
              icon: Icons.receipt_long_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
