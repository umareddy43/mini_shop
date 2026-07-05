import 'package:sqflite/sqflite.dart';

import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/order.dart';
import '../models/order_item.dart';

enum OrderFilter { today, pending, delivered, all }

class OrderRepository {
  final DatabaseHelper _dbHelper;
  OrderRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Creates an order together with its line items inside a single
  /// transaction so we never end up with a half-saved order.
  Future<int> createOrder(Order order, List<OrderItemModel> items) async {
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final orderId =
          await txn.insert(DatabaseHelper.tableOrders, order.toMap());
      for (final item in items) {
        await txn.insert(
          DatabaseHelper.tableOrderItems,
          item.copyWith(orderId: orderId).toMap(),
        );
      }
      return orderId;
    });
  }

  /// Replaces an existing order's items and updates its header row -
  /// used by the "Edit Order" flow.
  Future<void> updateOrder(Order order, List<OrderItemModel> items) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        DatabaseHelper.tableOrders,
        order.toMap(),
        where: 'id = ?',
        whereArgs: [order.id],
      );
      await txn.delete(
        DatabaseHelper.tableOrderItems,
        where: 'orderId = ?',
        whereArgs: [order.id],
      );
      for (final item in items) {
        await txn.insert(
          DatabaseHelper.tableOrderItems,
          item.copyWith(orderId: order.id).toMap(),
        );
      }
    });
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableOrders,
      {'status': status.dbValue},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> deleteOrder(int orderId) async {
    final db = await _dbHelper.database;
    // order_items cascade-delete via FK, but sqflite doesn't always
    // enforce ON DELETE CASCADE depending on platform, so clean up
    // explicitly to be safe.
    await db.transaction((txn) async {
      await txn.delete(
        DatabaseHelper.tableOrderItems,
        where: 'orderId = ?',
        whereArgs: [orderId],
      );
      await txn.delete(
        DatabaseHelper.tableOrders,
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }

  Future<List<OrderItemModel>> getOrderItems(int orderId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT oi.*, i.name as itemName, i.unit as itemUnit
      FROM ${DatabaseHelper.tableOrderItems} oi
      JOIN ${DatabaseHelper.tableItems} i ON i.id = oi.itemId
      WHERE oi.orderId = ?
      ORDER BY oi.id ASC
    ''', [orderId]);
    return rows.map(OrderItemModel.fromMap).toList();
  }

  Future<Order?> getOrderById(int orderId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT o.*, c.name as customerName
      FROM ${DatabaseHelper.tableOrders} o
      JOIN ${DatabaseHelper.tableCustomers} c ON c.id = o.customerId
      WHERE o.id = ?
    ''', [orderId]);
    if (rows.isEmpty) return null;
    final order = Order.fromMap(rows.first);
    final items = await getOrderItems(orderId);
    return order.copyWith(items: items);
  }

  /// Fetches orders (with customer name joined in) for the Orders module,
  /// applying the requested [filter] and optional [searchQuery] against
  /// the customer name.
  Future<List<Order>> getOrders({
    OrderFilter filter = OrderFilter.all,
    String? searchQuery,
  }) async {
    final db = await _dbHelper.database;

    final conditions = <String>[];
    final args = <Object?>[];

    switch (filter) {
      case OrderFilter.today:
        final today = DateTime.now();
        final startOfDay =
            DateTime(today.year, today.month, today.day).toIso8601String();
        final endOfDay = DateTime(today.year, today.month, today.day, 23, 59,
                59, 999)
            .toIso8601String();
        conditions.add('o.date BETWEEN ? AND ?');
        args.addAll([startOfDay, endOfDay]);
        break;
      case OrderFilter.pending:
        conditions.add('o.status = ?');
        args.add(OrderStatus.pendingDelivery.dbValue);
        break;
      case OrderFilter.delivered:
        conditions.add('o.status = ?');
        args.add(OrderStatus.delivered.dbValue);
        break;
      case OrderFilter.all:
        break;
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('c.name LIKE ?');
      args.add('%$searchQuery%');
    }

    final whereClause =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT o.*, c.name as customerName
      FROM ${DatabaseHelper.tableOrders} o
      JOIN ${DatabaseHelper.tableCustomers} c ON c.id = o.customerId
      $whereClause
      ORDER BY o.date DESC
    ''', args);

    return rows.map(Order.fromMap).toList();
  }

  Future<List<Order>> getOrdersForCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT o.*, c.name as customerName
      FROM ${DatabaseHelper.tableOrders} o
      JOIN ${DatabaseHelper.tableCustomers} c ON c.id = o.customerId
      WHERE o.customerId = ?
      ORDER BY o.date DESC
    ''', [customerId]);
    return rows.map(Order.fromMap).toList();
  }

  // ---- Dashboard statistics -------------------------------------------

  Future<double> getTodaysSales() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay =
        DateTime(today.year, today.month, today.day, 23, 59, 59, 999)
            .toIso8601String();

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(totalAmount), 0) as total
      FROM ${DatabaseHelper.tableOrders}
      WHERE date BETWEEN ? AND ?
    ''', [startOfDay, endOfDay]);

    return ((result.first['total'] as num?) ?? 0).toDouble();
  }

  Future<int> getPendingDeliveriesCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${DatabaseHelper.tableOrders}
      WHERE status = ?
    ''', [OrderStatus.pendingDelivery.dbValue]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalOrderCount() async {
    final db = await _dbHelper.database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as count FROM ${DatabaseHelper.tableOrders}');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
