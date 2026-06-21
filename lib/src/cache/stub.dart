import 'dart:typed_data';

import 'package:cache_kit/src/encryption/encryption.dart';

abstract class BaseCache {
  BaseCache({
    this.storeName = 'cache_kit_store',
    required this.encryption,
  });

  /// Name of the store (has to be a valid folder name)
  ///
  /// By default it is `cache_kit_store`
  final String storeName;

  final BaseCacheEncryption encryption;

  /// Stores file with given [key]
  Future<void> set(String key, Uint8List value);

  /// Returns file from store with given [key]
  ///
  /// Throws if file doesn't exist
  Future<Uint8List> get(String key);

  /// Checks if file exists in cache store
  Future<bool> contains(String key);

  /// Renames an existing cache entry from [key] to [newKey].
  ///
  /// Throws if the original [key] is not found.
  Future<void> renameKey(String key, String newKey);

  /// Removes file from cache with given [key]
  Future<void> delete(String key);

  /// Clears the cache store
  Future<void> deleteAll();

  /// Returns the full size of the store (in bytes)
  Future<int> getStoreSize();

  /// Closes the cache store and releases all resources
  void dispose();
}
