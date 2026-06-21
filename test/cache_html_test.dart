@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:cache_kit/src/cache/html.dart' as html_cache;
import 'package:cache_kit/src/encryption/encryption.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Web Cache', () {
    late html_cache.Cache cache;

    setUp(() {
      cache = _cache();
    });

    tearDown(() async {
      await cache.deleteAll();
      cache.dispose();
    });

    test('returns the total stored byte size', () async {
      expect(await cache.getStoreSize(), 0);

      await cache.set('first', Uint8List.fromList([1, 2, 3]));
      await cache.set('second', Uint8List.fromList([4, 5]));

      expect(await cache.getStoreSize(), 5);

      await cache.set('first', Uint8List.fromList([6]));

      expect(await cache.getStoreSize(), 3);
    });

    test('returns zero size after clearing the store', () async {
      await cache.set('first', Uint8List.fromList([1, 2, 3]));
      await cache.set('second', Uint8List.fromList([4, 5]));
      await cache.deleteAll();

      expect(await cache.getStoreSize(), 0);
    });
  });
}

html_cache.Cache _cache() {
  return html_cache.Cache(
    storeName: 'cache_kit_web_test_${DateTime.now().microsecondsSinceEpoch}',
    encryption: const BaseCacheEncryption(),
  );
}
