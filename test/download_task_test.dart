import 'dart:async';
import 'dart:typed_data';

import 'package:cache_kit/src/cache/stub.dart';
import 'package:cache_kit/src/encryption/encryption.dart';
import 'package:cache_kit/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/utils.dart';

void main() {
  initTest();

  group('DownloadTask', () {
    test('exposes a Future result and completes from cache', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final contains = Completer<bool>();
      final cache = _FakeCache(
        containsHandler: (_) => contains.future,
        getHandler: (_) async => bytes,
      );
      final task = DownloadTask(
        uri: Uri.parse('https://example.com/avatar.png'),
        params: DownloadTaskParams(),
        cache: cache,
      );

      expect(task.result, isA<Future<Uint8List>>());

      var notifications = 0;
      task.addListener(() {
        notifications++;
      });

      contains.complete(true);

      expect(await task.result, bytes);
      expect(task.progress, 100);
      expect(notifications, 1);

      task.dispose();
    });

    test('cancel is idempotent and completes with StateError', () async {
      final contains = Completer<bool>();
      final cache = _FakeCache(containsHandler: (_) => contains.future);
      final task = DownloadTask(
        uri: Uri.parse('https://example.com/avatar.png'),
        params: DownloadTaskParams(),
        cache: cache,
      );

      task.cancel();
      task.cancel();
      contains.complete(false);

      await expectLater(task.result, throwsA(isA<StateError>()));
      task.dispose();
    });

    test('dispose cancels a pending task', () async {
      final contains = Completer<bool>();
      final cache = _FakeCache(containsHandler: (_) => contains.future);
      final task = DownloadTask(
        uri: Uri.parse('https://example.com/avatar.png'),
        params: DownloadTaskParams(),
        cache: cache,
      );

      task.dispose();
      contains.complete(true);

      await expectLater(task.result, throwsA(isA<StateError>()));
    });

    test('does not write downloaded bytes after cancellation', () async {
      final contains = Completer<bool>();
      final cache = _FakeCache(
        containsHandler: (_) => contains.future,
        setHandler: (_, _) => fail('Cancelled task should not write to cache'),
      );
      final task = DownloadTask(
        uri: Uri.parse('file:///avatar.png'),
        params: DownloadTaskParams(),
        cache: cache,
      );

      task.cancel();
      contains.complete(false);

      await expectLater(task.result, throwsA(isA<StateError>()));
    });
  });
}

class _FakeCache extends BaseCache {
  _FakeCache({
    Future<bool> Function(String key)? containsHandler,
    Future<Uint8List> Function(String key)? getHandler,
    Future<void> Function(String key, Uint8List value)? setHandler,
  }) : this._(
         containsHandler: containsHandler,
         getHandler: getHandler,
         setHandler: setHandler,
       );

  _FakeCache._({
    this._containsHandler,
    this._getHandler,
    this._setHandler,
  }) : super(encryption: const BaseCacheEncryption());

  final Future<bool> Function(String key)? _containsHandler;
  final Future<Uint8List> Function(String key)? _getHandler;
  final Future<void> Function(String key, Uint8List value)? _setHandler;

  @override
  Future<bool> contains(String key) {
    return _containsHandler?.call(key) ?? Future.value(false);
  }

  @override
  Future<Uint8List> get(String key) {
    return _getHandler?.call(key) ?? Future.error(StateError('Missing test value'));
  }

  @override
  Future<void> set(String key, Uint8List value) {
    return _setHandler?.call(key, value) ?? Future.value();
  }

  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  Future<int> getStoreSize() async => 0;

  @override
  Future<void> renameKey(String key, String newKey) async {}

  @override
  void dispose() {}
}
