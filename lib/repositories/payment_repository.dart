import '../database/database_helper.dart';
import '../models/payment.dart';

class PaymentRepository {
  final DatabaseHelper _dbHelper;
  PaymentRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> insertPayment(Payment payment) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseHelper.tablePayments, payment.toMap());
  }

  Future<int> deletePayment(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseHelper.tablePayments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Payment>> getPaymentsForCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tablePayments,
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'paymentDate DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<double> getTotalPaidByCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM ${DatabaseHelper.tablePayments}
      WHERE customerId = ?
    ''', [customerId]);
    return ((result.first['total'] as num?) ?? 0).toDouble();
  }
}
