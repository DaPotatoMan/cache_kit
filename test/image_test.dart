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

    test('accepts asynchronously resolved headers', () async {
      final provider = CachedNetworkImage(
        'https://example.com/image.png',
        CacheKit(),
        headersResolver: (url) async {
          expect(url, Uri.parse('https://example.com/image.png'));
          return const {'Authorization': 'Bearer token'};
        },
      );

      expect(
        await provider.headersResolver!(Uri.parse(provider.url)),
        const {'Authorization': 'Bearer token'},
      );
    });

    test('does not allow static and resolved headers together', () {
      expect(
        () => CachedNetworkImage(
          'https://example.com/image.png',
          CacheKit(),
          headers: const {'Accept': 'image/*'},
          headersResolver: (_) => const {'Authorization': 'Bearer token'},
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
