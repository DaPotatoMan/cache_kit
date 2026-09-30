import 'dart:async';
import 'dart:ui' as ui;

import 'package:cache_kit/cache_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

// Method signature for _loadAsync decode callbacks.
typedef _SimpleDecoderCallback = Future<ui.Codec> Function(ui.ImmutableBuffer buffer);

/// Resolves the HTTP headers for an image request.
///
/// The resolver is called immediately before CacheKit starts a download. It
/// can return headers synchronously or asynchronously, which is useful for
/// refreshing an access token or creating request signatures.
typedef ImageHeadersResolver = FutureOr<Map<String, String>?> Function(Uri url);

/// An [ImageProvider] that fetches an image from a URL using [CacheKit].
/// Copied from Flutter's [NetworkImage] class.
///
/// This provider integrates with [CacheKit] to download the image data,
/// store it in the cache, and then load it for display.
/// It also handles reporting chunk events for download progress.
@immutable
class CachedNetworkImage extends ImageProvider<NetworkImage> implements NetworkImage {
  /// Creates an object that fetches the image at the given URL.
  const CachedNetworkImage(
    this.url,
    this.cache, {
    this.scale = 1.0,
    this.headers,
    this.headersResolver,
    this.webHtmlElementStrategy = WebHtmlElementStrategy.never,
  }) : assert(
         headers == null || headersResolver == null,
         'Specify either headers or headersResolver, not both.',
       );

  /// The URL from which the image will be fetched.
  @override
  final String url;

  /// The [CacheKit] instance used for downloading and caching the image.
  final CacheKit cache;

  /// The scale factor for the image.
  @override
  final double scale;

  /// HTTP headers to be included in the image request.
  @override
  final Map<String, String>? headers;

  /// Resolves HTTP headers immediately before an image is downloaded.
  ///
  /// This is mutually exclusive with [headers]. It is not invoked when the
  /// image is served from CacheKit's cache.
  final ImageHeadersResolver? headersResolver;

  /// Strategy for handling HTML elements when running on the web.
  /// See [WebHtmlElementStrategy].
  @override
  final WebHtmlElementStrategy webHtmlElementStrategy;

  @override
  Future<NetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<NetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    NetworkImage key,
    ImageDecoderCallback decode,
  ) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode: decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<NetworkImage>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    NetworkImage key,
    StreamController<ImageChunkEvent> chunkEvents, {
    required _SimpleDecoderCallback decode,
  }) async {
    try {
      assert(key == this);

      final requestHeaders = await headersResolver?.call(Uri.parse(key.url)) ?? headers;

      final task = cache.download(
        Uri.parse(key.url),
        params: .new(
          headers: requestHeaders,
          onProgress: (cumulative, total, _) {
            chunkEvents.add(
              ImageChunkEvent(
                cumulativeBytesLoaded: cumulative,
                expectedTotalBytes: total <= 0 ? null : total,
              ),
            );
          },
        ),
      );

      final bytes = await task.result;

      if (bytes.lengthInBytes == 0) {
        throw Exception('CachedNetworkImage is an empty file: ${key.url}');
      }

      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (e) {
      // Depending on where the exception was thrown, the image cache may not
      // have had a chance to track the key in the cache at all.
      // Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      await chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CachedNetworkImage && other.url == url && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'CachedNetworkImage')}("$url", scale: ${scale.toStringAsFixed(1)})';
}
