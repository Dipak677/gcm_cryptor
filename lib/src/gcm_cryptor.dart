import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:gcm_cryptor/src/crypto_dto.dart';
import 'package:pointycastle/export.dart';

/// A utility class for AES-GCM encryption and decryption operations.
///
/// This class provides methods to generate secure keys, encrypt messages into
/// [CryptoDto] objects containing the payload, nonce, and tag, and decrypt
/// them back to the original message.
///
/// Use [GcmCryptor.instance] to access the singleton instance.
class GcmCryptor {
  GcmCryptor._();

  static final GcmCryptor _instance = GcmCryptor._();

  /// Returns the singleton instance of [GcmCryptor].
  static GcmCryptor get instance => _instance;

  final int _nonceLength = 12;
  final int _tagLength = 16;
  final int _keyLength = 16;

  /// Generates a 128-bit AES key using SHA-256 hashing.
  ///
  /// The key is derived by concatenating the [masterKey] and [timestamp]
  /// and taking the first 16 bytes of the SHA-256 hash.
  ///
  /// Throws an [Exception] if the generated hash is unexpectedly short.
  Uint8List generateAESKey(String? masterKey, String? timestamp) {
    final concatenatedString = '$masterKey$timestamp';

    final concatenatedBytes = utf8.encode(concatenatedString);

    final digest = crypto.sha256.convert(concatenatedBytes);
    final hashBytes = Uint8List.fromList(digest.bytes);

    if (hashBytes.length < _keyLength) {
      throw Exception("SHA-256 hash is unexpectedly short.");
    }
    return hashBytes.sublist(0, _keyLength);
  }

  /// Encodes a list of bytes into a Base64 string.
  String base64Encode(List<int> bytes) {
    return base64.encode(bytes);
  }

  Uint8List _getSecureRandomBytes(int length) {
    final secureRandom = SecureRandom('Fortuna');

    final seedSource = math.Random.secure();

    final seed = Uint8List.fromList(
      List<int>.generate(32, (_) => seedSource.nextInt(256)),
    );

    secureRandom.seed(KeyParameter(seed));

    return secureRandom.nextBytes(length);
  }

  /// Calculates the SHA-256 checksum of the given [data].
  ///
  /// Returns the hex string representation of the hash.
  String calculateChecksum(Uint8List data) {
    final digest = crypto.sha256.convert(data);
    return bytesToHex(digest.bytes);
  }

  /// Converts a list of bytes to a hexadecimal string.
  String bytesToHex(List<int> bytes) {
    return hex.encode(bytes);
  }

  /// Encrypts a [message] using AES-GCM with the provided [key].
  ///
  /// The [key] should be a Base64 encoded string representing the 128-bit key.
  /// (Note: Current implementation performs `utf8.encode(key)`, which suggests the key
  /// parameter acts as a seed or passphrase if not already bytes, or expects Base64 string characters).
  ///
  /// Returns a [CryptoDto] containing the Base64 encoded encrypted payload,
  /// nonce, and authentication tag.
  CryptoDto encrypt(String message, String key) {
    final keyBytes = utf8.encode(key);
    final plainTextBytes = utf8.encode(message);

    final nonce = _getSecureRandomBytes(_nonceLength);

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(keyBytes),
      _tagLength * 8,
      nonce,
      Uint8List(0),
    );
    cipher.init(true, params);

    final outputBuffer = Uint8List(plainTextBytes.length + _tagLength);

    int len = cipher.processBytes(
      plainTextBytes,
      0,
      plainTextBytes.length,
      outputBuffer,
      0,
    );

    len += cipher.doFinal(outputBuffer, len);

    final encryptedBytes = outputBuffer.sublist(0, plainTextBytes.length);
    final tag = outputBuffer.sublist(plainTextBytes.length, len);

    return CryptoDto(
      payLoad: base64Encode(encryptedBytes),
      nonce: base64Encode(nonce),
      tag: base64Encode(tag),
    );
  }

  /// Decrypts an [encryptedStr] using AES-GCM.
  ///
  /// Requires the [key], [nonce], and authentication [tag] (all Base64 encoded strings).
  ///
  /// Returns the original plaintext string if decryption and authentication succeed.
  ///
  /// Throws an [Exception] if decryption fails (e.g. invalid tag, corrupted data).
  String decrypt(String encryptedStr, String key, String nonce, String tag) {
    final keyBytes = utf8.encode(key);
    final nonceBytes = base64Decode(nonce);
    final encryptedBytes = base64Decode(encryptedStr);
    final tagBytes = base64Decode(tag);

    final combinedCipherText = Uint8List.fromList([
      ...encryptedBytes,
      ...tagBytes,
    ]);

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(keyBytes),
      _tagLength * 8,
      nonceBytes,
      Uint8List(0),
    );
    cipher.init(false, params);

    try {
      final decryptedBytes = cipher.process(combinedCipherText);
      return utf8.decode(decryptedBytes);
    } on InvalidCipherTextException {
      throw Exception(
        "Decryption Failed: Invalid authentication tag (checksum mismatch)",
      );
    } catch (e) {
      throw Exception("Decryption Failed: ${e.toString()}");
    }
  }
}
