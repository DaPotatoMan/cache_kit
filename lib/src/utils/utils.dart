import 'dart:async';

import 'package:cache_kit/src/cache/stub.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DownloadTaskParams {
  DownloadTaskParams({
    this.headers,
    this.onProgress,
    CancelToken? cancelToken,
  }) : cancelToken = cancelToken ?? CancelToken();

  final Map<String, dynamic>? headers;
  final CancelToken cancelToken;
  final void Function(int count, int total, int progress)? onProgress;
}

class DownloadTask extends ChangeNotifier {
  @internal
  DownloadTask({
    required this.uri,
    required this.params,
    required this._cache,
  }) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }

    _init();
  }

  final BaseCache _cache;
  final Uri uri;
  final DownloadTaskParams params;
  final Completer<Uint8List> _result = Completer<Uint8List>();

  // Internal
  int _progress = 0;
  bool _isCanceled = false;
  bool _isDisposed = false;

  // Getters
  int get progress => _progress;
  Future<Uint8List> get result => _result.future;

  void cancel() {
    if (_isCanceled) return;

    _isCanceled = true;
    params.cancelToken.cancel('Cancelled by user');
    _completeError(StateError('Cancelled by user'), .current);
  }

  void _setProgress(int count, int total) {
    if (_isDisposed || total <= 0) return;

    final progress = ((count / total) * 100).clamp(0, 100).toInt();
    if (progress != _progress) _progress = progress;

    params.onProgress?.call(count, total, progress);
    notifyListeners();
  }

  Future<void> _init() async {
    try {
      final url = uri.toString();
      Uint8List bytes;

      // Return from cache
      if (await _cache.contains(url)) {
        _throwIfCanceled();

        bytes = await _cache.get(url);
        _setProgress(1, 1);
      }
      // Download from url
      else {
        bytes = await switch (uri.scheme) {
          'https' || 'http' || 'blob' => _downloadFromURL(url),
          _ => throw Exception('CacheKit: Invalid source was provided. Only http/blob urls are supported'),
        };

        // Store in cache
        _throwIfCanceled();
        await _cache.set(url, bytes);
      }

      _throwIfCanceled();
      _complete(bytes);
    } catch (error, trace) {
      _completeError(error, trace);
    }
  }

  Future<Uint8List> _downloadFromURL(String url) async {
    final dio = Dio();

    try {
      final response = await dio.get(
        url,
        cancelToken: params.cancelToken,
        onReceiveProgress: _setProgress,
        options: Options(headers: params.headers, responseType: ResponseType.bytes),
      );

      if (response.data case final Uint8List bytes) return bytes;
      throw Exception('Downloaded data type is not Uint8List');
    } finally {
      dio.close(force: true);
    }
  }

  void _throwIfCanceled() {
    if (_isCanceled) throw StateError('Cancelled by user');
  }

  void _complete(Uint8List bytes) {
    if (!_result.isCompleted) _result.complete(bytes);
  }

  void _completeError(Object error, StackTrace trace) {
    if (!_result.isCompleted) _result.completeError(error, trace);
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    cancel();
    _isDisposed = true;
    super.dispose();
  }
}
