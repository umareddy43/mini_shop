import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/khata_provider.dart';
import '../../widgets/customer_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';
import 'customer_detail_screen.dart';

/// Module 3: Khata. Lists every customer with their pending amount and
/// order count, most useful ones (with dues) are easy to spot via the
/// red "Due" chip on each card.
class KhataScreen extends ConsumerWidget {
  const KhataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(khataListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Khata')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(khataListProvider.notifier).load(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchField(
                hintText: 'Search customers',
                onChanged: (q) => ref.read(khataListProvider.notifier).search(q),
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.customers.isEmpty
                      ? const EmptyState(
                          icon: Icons.menu_book_outlined,
                          title: 'No customers yet',
                          subtitle: 'Customers appear here once they place an order.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: state.customers.length,
                          itemBuilder: (context, index) {
                            final khata = state.customers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: KhataCustomerCard(
                                khata: khata,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CustomerDetailScreen(
                                      customerId: khata.customer.id!,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
