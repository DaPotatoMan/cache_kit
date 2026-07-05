import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  static void register() {
    setUp(() {
      PathProviderPlatform.instance = FakePathProvider();
    });

    tearDownAll(cleanUp);
  }

  static const rootFolderName = '.cache/store';
  static Directory get _root => Directory(join(Directory.current.path, rootFolderName));

  /// Ensures [path] exists on disk and returns its path.
  static Future<String> _ensureDir(String path) async {
    final dir = Directory(join(_root.path, path));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir.path;
  }

  /// Removes the root directory
  static Future<void> cleanUp() async {
    if (await _root.exists()) await _root.delete(recursive: true);
  }

  @override
  getTemporaryPath() => _ensureDir('temp');

  @override
  getApplicationDocumentsPath() => _ensureDir('app_documents');

  @override
  getApplicationCachePath() => _ensureDir('app_cache');
}

void initTest() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FakePathProvider.register();
}
