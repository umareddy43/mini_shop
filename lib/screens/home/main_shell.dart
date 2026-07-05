import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../create_order/select_customer_screen.dart';
import '../items/item_list_screen.dart';
import '../khata/khata_screen.dart';
import '../orders/orders_screen.dart';

/// Root scaffold hosting the four main modules behind a bottom navigation
/// bar, as specified. Each tab keeps its own navigation stack via
/// IndexedStack so switching tabs never loses scroll position or
/// in-progress state (e.g. a half-built order).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Each tab gets its own Navigator so pushing detail screens doesn't
  // hide the bottom navigation bar.
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(4, (_) => GlobalKey<NavigatorState>());

  static final List<Widget Function()> _tabBuilders = [
    () => const SelectCustomerScreen(),
    () => const OrdersScreen(),
    () => const KhataScreen(),
    () => const ItemListScreen(),
  ];

  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => _tabBuilders[index]());
      },
    );
  }

  Future<bool> _onWillPop() async {
    final navigator = _navigatorKeys[_index].currentState!;
    if (navigator.canPop()) {
      navigator.pop();
      return false;
    }
    return true;
  }

  void _onTabTapped(int index) {
    if (index == _index) {
      // Tapping the active tab again pops it back to its root screen.
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: List.generate(4, _buildTabNavigator),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onTabTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.add_shopping_cart_outlined),
              selectedIcon: Icon(Icons.add_shopping_cart),
              label: AppConstants.tabCreateOrder,
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: AppConstants.tabOrders,
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: AppConstants.tabKhata,
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: AppConstants.tabItems,
            ),
          ],
        ),
      ),
    );
  }
}
