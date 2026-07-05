import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_provider.dart';
import 'repository_providers.dart';

class DashboardStats {
  final double todaysSales;
  final int pendingDeliveries;
  final double pendingKhataAmount;
  final int totalCustomers;
  final int totalOrders;

  const DashboardStats({
    required this.todaysSales,
    required this.pendingDeliveries,
    required this.pendingKhataAmount,
    required this.totalCustomers,
    required this.totalOrders,
  });
}

/// Aggregates numbers from three repositories into one snapshot for the
/// dashboard header. `autoDispose` + watching [orderListProvider] means it
/// automatically recomputes whenever an order is created/updated/deleted.
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  // Re-run whenever the order list changes (new order, status change, etc).
  ref.watch(orderListProvider);

  final orderRepo = ref.watch(orderRepositoryProvider);
  final customerRepo = ref.watch(customerRepositoryProvider);

  final results = await Future.wait([
    orderRepo.getTodaysSales(),
    orderRepo.getPendingDeliveriesCount(),
    customerRepo.getTotalPendingKhata(),
    customerRepo.getTotalCustomerCount(),
    orderRepo.getTotalOrderCount(),
  ]);

  return DashboardStats(
    todaysSales: results[0] as double,
    pendingDeliveries: results[1] as int,
    pendingKhataAmount: results[2] as double,
    totalCustomers: results[3] as int,
    totalOrders: results[4] as int,
  );
});
