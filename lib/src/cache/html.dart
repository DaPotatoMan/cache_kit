import 'dart:async';
import 'dart:typed_data';

import 'package:idb_shim/idb_browser.dart';

import 'stub.dart';

typedef IDBTransactionRef<T> = (Transaction transaction, T data);

class _WebDB {
  _WebDB(this.dbName);

  final String dbName;
  Future<Database>? _ref;

  Future<Database> get() async {
    if (_ref != null) return _ref!;

    try {
      return await (_ref = idbFactoryBrowser.open(
        dbName,
        version: 1,
        onUpgradeNeeded: (event) async {
          final db = event.database;

          if (!db.objectStoreNames.contains('data')) {
            db.createObjectStore('data');
          }

          _ref = Future.value(db);
        },
      ));
    } catch (_) {
      _ref = null;
      rethrow;
    }
  }

  Future<IDBTransactionRef<ObjectStore>> getStore(String mode) async {
    final db = await get();
    final transaction = db.transaction('data', mode);
    final store = transaction.objectStore('data');

    return (transaction, store);
  }

  Future<IDBTransactionRef<Object?>> getObject(String key, String mode) async {
    final (transaction, store) = await getStore(mode);
    return (transaction, await store.getObject(key));
  }

  void dispose() {
    _ref?.then((db) {
      db.close();
      _ref = null;
    });
  }
}

/// Web (HTML) implementation of [BaseCache] using IndexedDB.
class Cache extends BaseCache {
  Cache({super.storeName, required super.encryption}) : _db = _WebDB(storeName);

  final _WebDB _db;

  @override
  Future<void> set(String key, Uint8List value) async {
    final (transaction, store) = await _db.getStore('readwrite');
    final data = await encryption.encrypt(value);

    await store.put(data, key);
    await transaction.completed;
  }

  @override
  Future<Uint8List> get(String key) async {
    final (transaction, data) = await _db.getObject(key, 'readonly');
    await transaction.completed;

    return switch (data) {
      Uint8List() => await encryption.decrypt(data),
      null => throw Exception('Key not found in cache: $key'),
      _ => throw Exception('Data is not of type Uint8List'),
    };
  }

  @override
  Future<bool> contains(String key) async {
    final (transaction, result) = await _db.getObject(key, 'readonly');
    await transaction.completed;

    return result != null;
  }

  @override
  Future<void> delete(String key) async {
    final (transaction, store) = await _db.getStore('readwrite');

    await store.delete(key);
    await transaction.completed;
  }

  @override
  Future<void> deleteAll() async {
    final (transaction, store) = await _db.getStore('readwrite');

    await store.clear();
    await transaction.completed;
  }

  @override
  Future<void> renameKey(String key, String newKey) async {
    if (key == newKey) return;

    final (transaction, store) = await _db.getStore('readwrite');
    final data = await store.getObject(key);

    if (data == null) {
      await transaction.completed;
      throw Exception('Key not found: $key');
    }

    try {
      await store.put(data, newKey);
      await store.delete(key);
      await transaction.completed;
    } catch (e) {
      transaction.abort();
      rethrow;
    }
  }

  @override
  void dispose() {
    _db.dispose();
  }
}
