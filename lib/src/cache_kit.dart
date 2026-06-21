import 'package:cache_kit/src/encryption/encryption.dart';

import 'cache/cache.dart'
    if (dart.library.io) 'cache/io.dart'
    if (dart.library.js_interop) 'cache/html.dart'
    if (dart.library.html) 'cache/html.dart';

class CacheKit {
  CacheKit({
    Cache? cache,
    String storeName = 'cache_kit_store',
    this._encryption = const BaseCacheEncryption(),
  }) : _cache = cache ?? Cache(storeName: storeName, encryption: _encryption);

  final BaseCacheEncryption _encryption;
  final Cache _cache;

  late final set = _cache.set;
  late final get = _cache.get;
  late final contains = _cache.contains;
  late final renameKey = _cache.renameKey;
  late final delete = _cache.delete;
  late final deleteAll = _cache.deleteAll;
  late final getStoreSize = _cache.getStoreSize;

  void dispose() {
    _encryption.dispose();
    _cache.dispose();
  }
}
