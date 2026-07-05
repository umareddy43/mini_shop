import '../database/database_helper.dart';
import '../models/item.dart';

class ItemRepository {
  final DatabaseHelper _dbHelper;
  ItemRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> insertItem(Item item) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseHelper.tableItems, item.toMap());
  }

  Future<int> updateItem(Item item) async {
    final db = await _dbHelper.database;
    return db.update(
      DatabaseHelper.tableItems,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseHelper.tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Item?> getItemById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Item.fromMap(rows.first);
  }

  Future<bool> nameExists(String name, {int? excludeId}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableItems,
      where: excludeId != null
          ? 'LOWER(name) = ? AND id != ?'
          : 'LOWER(name) = ?',
      whereArgs: excludeId != null
          ? [name.toLowerCase(), excludeId]
          : [name.toLowerCase()],
    );
    return rows.isNotEmpty;
  }

  /// Returns items, optionally filtered by [searchQuery] and/or
  /// [onlyAvailable]. Always sorted alphabetically by name as per spec.
  Future<List<Item>> getAllItems({
    String? searchQuery,
    bool onlyAvailable = false,
  }) async {
    final db = await _dbHelper.database;

    final conditions = <String>[];
    final args = <Object?>[];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('name LIKE ?');
      args.add('%$searchQuery%');
    }
    if (onlyAvailable) {
      conditions.add('available = 1');
    }

    final rows = await db.query(
      DatabaseHelper.tableItems,
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Item.fromMap).toList();
  }

  Future<int> getTotalItemCount() async {
    final db = await _dbHelper.database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as count FROM ${DatabaseHelper.tableItems}');
    return (result.first['count'] as int?) ?? 0;
  }
}
