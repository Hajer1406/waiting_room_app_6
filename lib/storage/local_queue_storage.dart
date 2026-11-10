import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sync_status.dart';

class LocalQueueStorage {
  static Database? _database;
  Database? _instanceDb;
  final bool _inMemory;
  final bool _isWebEnvironment = kIsWeb;
  final List<Map<String, dynamic>> _inMemoryStore = [];

  LocalQueueStorage({bool inMemory = false}) : _inMemory = inMemory;

  Future<Database?> get database async {
    if (_isWebEnvironment) return null;

    if (_inMemory) {
      if (_instanceDb != null && _instanceDb!.isOpen) return _instanceDb!;
      _instanceDb = await openDatabase(
        ':memory:',
        version: 1,
        onCreate: _onCreate,
      );
      return _instanceDb!;
    }
    if (_database != null && _database!.isOpen) return _database!;
    try {
      final path = join(await getDatabasesPath(), 'waiting_queue.db');
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
      return _database!;
    } catch (e) {
      debugPrint('LocalQueueStorage init failed, falling back to memory: $e');
      return null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE clients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  lat REAL,
  lng REAL,
  location_accuracy_m REAL,
  created_at TEXT NOT NULL,
  sync_status TEXT NOT NULL
)
''');
  }

  Future<void> saveClient(Map<String, dynamic> client) async {
    final db = await database;
    if (db == null) {
      _inMemoryStore.removeWhere((item) => item['id'] == client['id']);
      _inMemoryStore.add(Map<String, dynamic>.from(client));
      return;
    }
    await db.insert(
      'clients',
      client,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final db = await database;
    if (db == null) {
      final list = List<Map<String, dynamic>>.from(_inMemoryStore);
      list.sort((a, b) {
        final aDate = a['created_at']?.toString() ?? '';
        final bDate = b['created_at']?.toString() ?? '';
        return bDate.compareTo(aDate);
      });
      return list;
    }
    return db.query('clients', orderBy: 'created_at DESC, id DESC');
  }

  /// Fetches both 'pending' and 'failed' records for retry logic
  Future<List<Map<String, dynamic>>> getPendingClients() async {
    final db = await database;
    if (db == null) {
      final list = _inMemoryStore.where((item) {
        final status = item['sync_status'];
        return status == 'pending' || status == 'failed';
      }).toList();
      list.sort((a, b) {
        final aDate = a['created_at']?.toString() ?? '';
        final bDate = b['created_at']?.toString() ?? '';
        return aDate.compareTo(bDate);
      });
      return list;
    }
    return db.query(
      'clients',
      where: 'sync_status = ? OR sync_status = ?',
      whereArgs: ['pending', 'failed'],
      orderBy: 'created_at ASC, id ASC',
    );
  }

  Future<void> updateSyncStatus(String id, SyncStatus status) async {
    final db = await database;
    if (db == null) {
      final idx = _inMemoryStore.indexWhere((item) => item['id'] == id);
      if (idx != -1) {
        _inMemoryStore[idx]['sync_status'] = status.name;
      }
      return;
    }
    await db.update(
      'clients',
      {'sync_status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteClient(String id) async {
    final db = await database;
    if (db == null) {
      _inMemoryStore.removeWhere((item) => item['id'] == id);
      return;
    }
    await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    _inMemoryStore.clear();
    final inst = _instanceDb;
    if (inst != null && inst.isOpen) {
      await inst.close();
      _instanceDb = null;
    }
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
