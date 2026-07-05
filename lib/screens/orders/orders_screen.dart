import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/order_provider.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_card.dart';
import '../../widgets/search_field.dart';
import 'order_detail_screen.dart';

/// Module 2: Orders. Shows the dashboard stats up top (the natural "home"
/// screen), then filterable/searchable order list.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  String _filterLabel(OrderFilter filter) {
    switch (filter) {
      case OrderFilter.today:
        return "Today's Orders";
      case OrderFilter.pending:
        return 'Pending';
      case OrderFilter.delivered:
        return 'Delivered';
      case OrderFilter.all:
        return 'All Orders';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(orderListProvider.notifier).loadOrders(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 12),
            const DashboardHeader(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchField(
                hintText: 'Search orders by customer name',
                onChanged: (q) => ref.read(orderListProvider.notifier).search(q),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: OrderFilter.values.map((filter) {
                  final selected = state.filter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filterLabel(filter)),
                      selected: selected,
                      onSelected: (_) =>
                          ref.read(orderListProvider.notifier).setFilter(filter),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.orders.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders found',
                  subtitle: 'Orders you create will show up here.',
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: state.orders
                      .map((order) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: OrderCard(
                              order: order,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailScreen(orderId: order.id!),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
