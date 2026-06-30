import 'package:cache_kit/cache_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CachedNetworkImage', () {
    test('uses the URL as the image key', () async {
      final provider = CachedNetworkImage(
        'https://example.com/image.png',
        CacheKit(),
        scale: 2,
      );

      final key = await provider.obtainKey(const ImageConfiguration());

      expect(key.url, 'https://example.com/image.png');
      expect(key.scale, 2);
    });
  });
}
