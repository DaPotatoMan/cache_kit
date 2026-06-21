import 'dart:typed_data';

import 'stub.dart';

class Cache extends BaseCache {
  Cache({super.storeName, required super.encryption});

  final _error = UnimplementedError('CacheKit: not supported in this platform');

  @override
  Future<void> set(String key, Uint8List value) => throw _error;

  @override
  Future<Uint8List> get(String key) => throw _error;

  @override
  Future<bool> contains(String key) => throw _error;

  @override
  Future<void> delete(String key) => throw _error;

  @override
  Future<void> deleteAll() => throw _error;

  @override
  Future<void> renameKey(String key, String newKey) => throw _error;

  @override
  Future<int> getStoreSize() => throw _error;

  @override
  void dispose() => throw _error;
}
