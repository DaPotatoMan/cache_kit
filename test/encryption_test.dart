import 'dart:typed_data';

import 'package:cache_kit/src/encryption/encryption.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaseCacheEncryption', () {
    test('passes bytes through unchanged', () async {
      const encryption = BaseCacheEncryption();
      final input = Uint8List.fromList([1, 2, 3]);

      expect(await encryption.encrypt(input), input);
      expect(await encryption.decrypt(input), input);
    });
  });

  group('PasswordEncryption', () {
    test('round trips bytes', () async {
      final encryption = PasswordEncryption(seed: 'test-password');
      final input = Uint8List.fromList(List<int>.generate(1024, (i) => i % 256));

      final encrypted = await encryption.encrypt(input);
      final decrypted = await encryption.decrypt(encrypted);

      expect(decrypted, input);
      expect(encrypted, isNot(input));
    });

    test('uses a fresh nonce for each encryption', () async {
      final encryption = PasswordEncryption(seed: 'test-password');
      final input = Uint8List.fromList([1, 2, 3, 4]);

      final first = await encryption.encrypt(input);
      final second = await encryption.encrypt(input);

      expect(first, isNot(second));
    });

    test('rejects tampered payloads', () async {
      final encryption = PasswordEncryption(seed: 'test-password');
      final encrypted = await encryption.encrypt(Uint8List.fromList([1, 2, 3]));

      encrypted[encrypted.length - 1] ^= 1;

      expect(
        () => encryption.decrypt(encrypted),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('rejects the wrong seed', () async {
      final encrypted = await PasswordEncryption(seed: 'test-password').encrypt(
        Uint8List.fromList([1, 2, 3]),
      );

      expect(
        () => PasswordEncryption(seed: 'wrong-password').decrypt(encrypted),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });
}
