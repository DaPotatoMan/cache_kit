import 'package:cache_kit/src/encryption/encryption.dart';
import 'package:cache_kit/src/utils/utils.dart';

import 'cache/cache.dart'
    if (dart.library.io) 'cache/io.dart'
    if (dart.library.js_interop) 'cache/web.dart'
    if (dart.library.html) 'cache/web.dart';

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

  DownloadTask download(Uri uri, {DownloadTaskParams? params}) =>
      DownloadTask(uri: uri, cache: _cache, params: params ?? DownloadTaskParams());

  void dispose() {
    _encryption.dispose();
    _cache.dispose();
  }
}
