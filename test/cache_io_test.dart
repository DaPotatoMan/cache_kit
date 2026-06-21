@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:cache_kit/src/cache/io.dart' as io_cache;
import 'package:cache_kit/src/encryption/encryption.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory cacheRoot;

  setUp(() async {
    cacheRoot = await Directory.systemTemp.createTemp('cache_kit_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (methodCall) async {
        if (methodCall.method == 'getApplicationCacheDirectory') {
          return cacheRoot.path;
        }

        return null;
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, null);

    if (await cacheRoot.exists()) {
      await cacheRoot.delete(recursive: true);
    }
  });

  File storedFile({required String storeName, required String key}) {
    final fileName = sha256.convert(utf8.encode(key)).toString();
    return File('${cacheRoot.path}/$storeName/$fileName');
  }

  group('IO Cache', () {
    test('stores, overwrites, and reads bytes by key', () async {
      final cache = _cache();
      final first = Uint8List.fromList([1, 2, 3]);
      final second = Uint8List.fromList([4, 5, 6]);

      expect(await cache.contains('avatar'), isFalse);

      await cache.set('avatar', first);
      expect(await cache.contains('avatar'), isTrue);
      expect(await cache.get('avatar'), first);

      await cache.set('avatar', second);
      expect(await cache.get('avatar'), second);
    });

    test('deletes keys idempotently', () async {
      final cache = _cache();

      await cache.set('avatar', Uint8List.fromList([1, 2, 3]));
      await cache.delete('avatar');

      expect(await cache.contains('avatar'), isFalse);
      expect(() => cache.get('avatar'), throwsA(isA<FileSystemException>()));

      await cache.delete('avatar');
    });

    test('renames keys without changing values', () async {
      final cache = _cache();
      final value = Uint8List.fromList([9, 8, 7]);

      await cache.set('old-key', value);
      await cache.renameKey('old-key', 'new-key');

      expect(await cache.contains('old-key'), isFalse);
      expect(await cache.contains('new-key'), isTrue);
      expect(await cache.get('new-key'), value);
    });

    test('keeps same-key renames as a no-op', () async {
      final cache = _cache();
      final value = Uint8List.fromList([1, 1, 2, 3]);

      await cache.set('same-key', value);
      await cache.renameKey('same-key', 'same-key');

      expect(await cache.contains('same-key'), isTrue);
      expect(await cache.get('same-key'), value);
    });

    test('throws when renaming a missing key', () async {
      final cache = _cache();

      expect(
        () => cache.renameKey('missing', 'new-key'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('clears only the selected store', () async {
      final avatars = _cache(storeName: 'avatars');
      final documents = _cache(storeName: 'documents');

      await avatars.set('user-1', Uint8List.fromList([1]));
      await documents.set('user-1', Uint8List.fromList([2]));

      await avatars.deleteAll();

      expect(await avatars.contains('user-1'), isFalse);
      expect(await documents.contains('user-1'), isTrue);
      expect(await documents.get('user-1'), Uint8List.fromList([2]));
    });

    test('returns the total stored byte size', () async {
      final cache = _cache();

      expect(await cache.getStoreSize(), 0);

      await cache.set('first', Uint8List.fromList([1, 2, 3]));
      await cache.set('second', Uint8List.fromList([4, 5]));

      expect(await cache.getStoreSize(), 5);

      await cache.set('first', Uint8List.fromList([6]));

      expect(await cache.getStoreSize(), 3);
    });

    test('returns zero size after clearing the store', () async {
      final cache = _cache();

      await cache.set('first', Uint8List.fromList([1, 2, 3]));
      await cache.set('second', Uint8List.fromList([4, 5]));
      await cache.deleteAll();

      expect(await cache.getStoreSize(), 0);
    });

    test('stores encrypted bytes on disk', () async {
      final cache = _cache(
        storeName: 'secure',
        encryption: PasswordEncryption(seed: 'test-password'),
      );
      final key = 'payload';
      final value = Uint8List.fromList([1, 2, 3, 4, 5]);

      await cache.set(key, value);

      final file = storedFile(storeName: 'secure', key: key);
      final storedBytes = await file.readAsBytes();

      expect(storedBytes, isNot(value));
      expect(await cache.get(key), value);
    });
  });
}

io_cache.Cache _cache({
  String storeName = 'cache_kit_store',
  BaseCacheEncryption encryption = const BaseCacheEncryption(),
}) {
  return io_cache.Cache(storeName: storeName, encryption: encryption);
}
