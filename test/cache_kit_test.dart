import 'package:cache_kit/cache_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheKit', () {
    test('accepts custom store names', () {
      expect(
        () => CacheKit(storeName: 'secure-app-db', encryption: const BaseCacheEncryption()),
        returnsNormally,
      );
    });

    test('accepts custom encryption', () {
      expect(
        () => CacheKit(encryption: PasswordEncryption(seed: 'test-password')),
        returnsNormally,
      );
    });

    test('exposes store size lookup', () {
      final cache = CacheKit(encryption: const BaseCacheEncryption());

      expect(cache.getStoreSize, isA<Future<int> Function()>());
    });
  });
}
