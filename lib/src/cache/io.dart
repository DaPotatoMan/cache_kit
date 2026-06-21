import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'stub.dart';

class Cache extends BaseCache {
  Cache({super.storeName, required super.encryption});

  /// Returns the cache directory
  Future<Directory> _getCacheDir() async {
    final cache = await getApplicationCacheDirectory();
    final folder = Directory('${cache.path}/$storeName');

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return folder;
  }

  /// Returns the [File] reference for given [key] in cache
  Future<File> _getEncodedFile(String key) async {
    final cacheDir = await _getCacheDir();
    final filePathBytes = utf8.encode(key);
    final filePath = sha256.convert(filePathBytes).toString();

    return File('${cacheDir.path}/$filePath');
  }

  @override
  Future<void> set(String key, Uint8List value) async {
    final file = await _getEncodedFile(key);
    final data = await encryption.encrypt(value);

    await file.writeAsBytes(data);
  }

  @override
  Future<Uint8List> get(String key) async {
    final file = await _getEncodedFile(key);

    if (await file.exists()) {
      return encryption.decrypt(
        await file.readAsBytes(),
      );
    }

    throw FileSystemException('File not found', file.path);
  }

  @override
  Future<bool> contains(String key) async {
    final file = await _getEncodedFile(key);
    return file.exists();
  }

  @override
  Future<void> renameKey(String key, String newKey) async {
    if (key == newKey) return;

    final file = await _getEncodedFile(key);

    if (await file.exists()) {
      final newFile = await _getEncodedFile(newKey);
      await file.rename(newFile.path);
      return;
    }

    throw FileSystemException('File not found', file.path);
  }

  @override
  Future<void> delete(String key) async {
    final file = await _getEncodedFile(key);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> deleteAll() async {
    final folder = await _getCacheDir();
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  @override
  void dispose() {}
}
