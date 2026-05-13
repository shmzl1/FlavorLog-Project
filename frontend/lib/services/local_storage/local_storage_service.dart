import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// 本地 SQLite 缓存服务
///
/// 缓存策略：覆盖写入（每次从服务端拉取最新数据后整体替换缓存）
/// 适用场景：网络请求失败时展示上次缓存内容，提升离线体验
class LocalStorageService {
  LocalStorageService._internal();

  static final LocalStorageService instance = LocalStorageService._internal();

  static const String _dbName = 'flavorlog.db';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 饮食记录缓存表
    await db.execute('''
      CREATE TABLE food_records_cache (
        id INTEGER PRIMARY KEY,
        user_id INTEGER,
        meal_type TEXT,
        record_time TEXT,
        source_type TEXT,
        description TEXT,
        total_calories REAL,
        total_protein_g REAL,
        total_fat_g REAL,
        total_carbohydrate_g REAL,
        items_json TEXT,
        created_at TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    // 冰箱食材缓存表
    await db.execute('''
      CREATE TABLE fridge_items_cache (
        id INTEGER PRIMARY KEY,
        user_id INTEGER,
        name TEXT NOT NULL,
        category TEXT,
        quantity REAL,
        unit TEXT,
        weight_g REAL,
        expire_date TEXT,
        storage_location TEXT,
        remark TEXT,
        created_at TEXT,
        cached_at TEXT NOT NULL
      )
    ''');
  }

  // ──────────────────── 饮食记录缓存 ────────────────────

  /// 整体替换饮食记录缓存
  /// [records] 为接口返回的 items 列表（Map 形式）
  Future<void> cacheFoodRecords(List<Map<String, dynamic>> records) async {
    final db = await _database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete('food_records_cache');
    for (final r in records) {
      batch.insert('food_records_cache', {
        'id': r['id'],
        'user_id': r['user_id'],
        'meal_type': r['meal_type'],
        'record_time': r['record_time'],
        'source_type': r['source_type'],
        'description': r['description'],
        'total_calories': r['total_calories'],
        'total_protein_g': r['total_protein_g'],
        'total_fat_g': r['total_fat_g'],
        'total_carbohydrate_g': r['total_carbohydrate_g'],
        'items_json': jsonEncode(r['items'] ?? []),
        'created_at': r['created_at'],
        'cached_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  /// 读取缓存的饮食记录，按 record_time 降序
  Future<List<Map<String, dynamic>>> getCachedFoodRecords({
    String? startDate,
    String? endDate,
  }) async {
    final db = await _database;
    final where = StringBuffer();
    final args = <Object>[];
    if (startDate != null) {
      where.write('record_time >= ?');
      args.add('${startDate}T00:00:00');
    }
    if (endDate != null) {
      if (where.isNotEmpty) where.write(' AND ');
      where.write('record_time <= ?');
      args.add('${endDate}T23:59:59');
    }
    final rows = await db.query(
      'food_records_cache',
      where: where.isNotEmpty ? where.toString() : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'record_time DESC',
    );
    return rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      try {
        map['items'] = jsonDecode(map['items_json'] as String? ?? '[]');
      } catch (_) {
        map['items'] = <dynamic>[];
      }
      return map;
    }).toList();
  }

  /// 清空饮食记录缓存
  Future<void> clearFoodRecordsCache() async {
    final db = await _database;
    await db.delete('food_records_cache');
  }

  // ──────────────────── 冰箱食材缓存 ────────────────────

  /// 整体替换冰箱食材缓存
  Future<void> cacheFridgeItems(List<Map<String, dynamic>> items) async {
    final db = await _database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete('fridge_items_cache');
    for (final item in items) {
      batch.insert('fridge_items_cache', {
        'id': item['id'],
        'user_id': item['user_id'],
        'name': item['name'],
        'category': item['category'],
        'quantity': item['quantity'],
        'unit': item['unit'],
        'weight_g': item['weight_g'],
        'expire_date': item['expire_date'],
        'storage_location': item['storage_location'],
        'remark': item['remark'],
        'created_at': item['created_at'],
        'cached_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  /// 读取缓存的冰箱食材，按 created_at 降序
  Future<List<Map<String, dynamic>>> getCachedFridgeItems() async {
    final db = await _database;
    return db.query('fridge_items_cache', orderBy: 'created_at DESC');
  }

  /// 清空冰箱食材缓存
  Future<void> clearFridgeItemsCache() async {
    final db = await _database;
    await db.delete('fridge_items_cache');
  }

  // ──────────────────── 全局操作 ────────────────────

  /// 清空所有缓存（退出登录时调用）
  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('food_records_cache');
    await db.delete('fridge_items_cache');
  }

  /// 关闭数据库连接
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
