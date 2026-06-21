import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

/// No encryption
/// Extend this class to create your own encryption system
class BaseCacheEncryption {
  const BaseCacheEncryption();

  Future<Uint8List> encrypt(Uint8List input) async => input;
  Future<Uint8List> decrypt(Uint8List input) async => input;

  void dispose() {}
}

class PasswordEncryption extends BaseCacheEncryption {
  PasswordEncryption({required this.seed}) : _key = SecretKey(sha256.convert(utf8.encode(seed)).bytes);

  final String seed;
  final SecretKey _key;
  final _cipher = AesGcm.with256bits();

  @override
  Future<Uint8List> encrypt(Uint8List input) async {
    final box = await _cipher.encrypt(input, secretKey: _key);
    return box.concatenation();
  }

  @override
  Future<Uint8List> decrypt(Uint8List input) async {
    final box = SecretBox.fromConcatenation(
      input,
      nonceLength: _cipher.nonceLength,
      macLength: _cipher.macAlgorithm.macLength,
      copy: false,
    );
    return Uint8List.fromList(await _cipher.decrypt(box, secretKey: _key));
  }

  @override
  dispose() {
    _key.destroy();
  }
}
