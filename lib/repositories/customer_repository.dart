import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';

/// A customer paired with their computed khata (running credit account)
/// figures. These are derived, not stored, so they're always accurate.
class CustomerWithKhata {
  final Customer customer;
  final double totalOrdered;
  final double totalPaid;
  final int totalOrders;

  const CustomerWithKhata({
    required this.customer,
    required this.totalOrdered,
    required this.totalPaid,
    required this.totalOrders,
  });

  double get pendingAmount => totalOrdered - totalPaid;
}

class CustomerRepository {
  final DatabaseHelper _dbHelper;
  CustomerRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> insertCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseHelper.tableCustomers, customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return db.update(
      DatabaseHelper.tableCustomers,
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseHelper.tableCustomers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableCustomers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  /// Case-insensitive check used to prevent duplicate customer names.
  /// [excludeId] lets an edit-in-place skip comparing against itself.
  Future<bool> nameExists(String name, {int? excludeId}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableCustomers,
      where: excludeId != null
          ? 'LOWER(name) = ? AND id != ?'
          : 'LOWER(name) = ?',
      whereArgs:
          excludeId != null ? [name.toLowerCase(), excludeId] : [name.toLowerCase()],
    );
    return rows.isNotEmpty;
  }

  Future<List<Customer>> getAllCustomers({String? searchQuery}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableCustomers,
      where: searchQuery != null && searchQuery.isNotEmpty
          ? 'name LIKE ? OR phone LIKE ?'
          : null,
      whereArgs: searchQuery != null && searchQuery.isNotEmpty
          ? ['%$searchQuery%', '%$searchQuery%']
          : null,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  /// Returns every customer together with their computed khata totals.
  /// Used by the Khata module list screen.
  Future<List<CustomerWithKhata>> getAllCustomersWithKhata({
    String? searchQuery,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT
        c.*,
        COALESCE(o.totalOrdered, 0) AS totalOrdered,
        COALESCE(p.totalPaid, 0) AS totalPaid,
        COALESCE(o.totalOrders, 0) AS totalOrders
      FROM ${DatabaseHelper.tableCustomers} c
      LEFT JOIN (
        SELECT customerId, SUM(totalAmount) AS totalOrdered, COUNT(*) AS totalOrders
        FROM ${DatabaseHelper.tableOrders}
        GROUP BY customerId
      ) o ON o.customerId = c.id
      LEFT JOIN (
        SELECT customerId, SUM(amount) AS totalPaid
        FROM ${DatabaseHelper.tablePayments}
        GROUP BY customerId
      ) p ON p.customerId = c.id
      ${searchQuery != null && searchQuery.isNotEmpty ? "WHERE c.name LIKE ? OR c.phone LIKE ?" : ""}
      ORDER BY c.name COLLATE NOCASE ASC
    ''', searchQuery != null && searchQuery.isNotEmpty
        ? ['%$searchQuery%', '%$searchQuery%']
        : null);

    return rows.map((row) {
      return CustomerWithKhata(
        customer: Customer.fromMap(row),
        totalOrdered: (row['totalOrdered'] as num).toDouble(),
        totalPaid: (row['totalPaid'] as num).toDouble(),
        totalOrders: (row['totalOrders'] as num).toInt(),
      );
    }).toList();
  }

  Future<CustomerWithKhata?> getCustomerWithKhata(int customerId) async {
    final all = await getAllCustomersWithKhata();
    try {
      return all.firstWhere((c) => c.customer.id == customerId);
    } catch (_) {
      return null;
    }
  }

  /// Sum of all outstanding dues across every customer - used on the
  /// dashboard.
  Future<double> getTotalPendingKhata() async {
    final all = await getAllCustomersWithKhata();
    double total = 0;
    for (final c in all) {
      if (c.pendingAmount > 0) total += c.pendingAmount;
    }
    return total;
  }

  Future<int> getTotalCustomerCount() async {
    final db = await _dbHelper.database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as count FROM ${DatabaseHelper.tableCustomers}');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
