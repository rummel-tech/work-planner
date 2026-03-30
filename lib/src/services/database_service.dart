import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';

import 'db_factory_io.dart' if (dart.library.html) 'db_factory_web.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;

  DatabaseService._internal();

  late Database _db;
  Database get db => _db;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _db = await openAppDatabase();
    _initialized = true;
  }

  /// Opens an isolated in-memory database. Call before each test that touches
  /// the database so tests don't share state.
  @visibleForTesting
  static Future<void> initializeForTesting() async {
    if (_instance._initialized) {
      await _instance._db.close();
      _instance._initialized = false;
    }
    _instance._db = await databaseFactoryMemory
        .openDatabase('test_${DateTime.now().millisecondsSinceEpoch}.db');
    _instance._initialized = true;
  }

  Future<void> close() async {
    await _db.close();
    _initialized = false;
  }

  Future<void> clearAll() async {
    await _db.transaction((txn) async {
      await stringMapStoreFactory.store('goals').delete(txn);
      await stringMapStoreFactory.store('plans').delete(txn);
      await stringMapStoreFactory.store('dayPlanners').delete(txn);
      await stringMapStoreFactory.store('weekPlanners').delete(txn);
    });
  }
}
