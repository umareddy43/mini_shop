import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton wrapper around the app's single SQLite database.
///
/// The whole app works fully offline - every read/write goes through this
/// helper (usually via a repository), so there is exactly one place that
/// knows about table/column names and schema versioning.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'grocery_shop.db';
  static const int _dbVersion = 1;

  // Table names.
  static const String tableCustomers = 'customers';
  static const String tableItems = 'items';
  static const String tableOrders = 'orders';
  static const String tableOrderItems = 'order_items';
  static const String tablePayments = 'payments';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        // Enforce FK constraints (off by default in sqflite).
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCustomers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        unit TEXT NOT NULL,
        available INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableOrders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        FOREIGN KEY (customerId) REFERENCES $tableCustomers (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableOrderItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        itemId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (orderId) REFERENCES $tableOrders (id)
          ON DELETE CASCADE,
        FOREIGN KEY (itemId) REFERENCES $tableItems (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablePayments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        amount REAL NOT NULL,
        paymentMode TEXT NOT NULL,
        remarks TEXT,
        paymentDate TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES $tableCustomers (id)
          ON DELETE CASCADE
      )
    ''');

    // Helpful indexes for the lookups the app performs constantly.
    await db.execute(
        'CREATE INDEX idx_orders_customer ON $tableOrders (customerId)');
    await db.execute(
        'CREATE INDEX idx_orderitems_order ON $tableOrderItems (orderId)');
    await db.execute(
        'CREATE INDEX idx_payments_customer ON $tablePayments (customerId)');
  }

  /// Closes the database. Mainly useful for tests.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
