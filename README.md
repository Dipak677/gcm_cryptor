# GcmCryptor

[![Pub Version](https://img.shields.io/pub/v/gcm_cryptor.svg)](https://pub.dev/packages/gcm_cryptor)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A powerful and easy-to-use Flutter package for AES-GCM encryption and decryption. This package acts as a convenient wrapper around `pointycastle`, providing secure key generation, encryption, and decryption capabilities with authentication tags and checksums.

## Features

- **AES-GCM Encryption**: Securely encrypt data using AES in Galois/Counter Mode (GCM).
- **AES-GCM Decryption**: Decrypt data and verify its integrity using the authentication tag.
- **Secure Key Generation**: Generate 128-bit AES keys using SHA-256 hashing of a master key and timestamp.
- **Base64 Support**: input and output handling for easy storage and transmission.
- **Checksum Calculation**: Utilities to calculate SHA-256 checksums of payloads.

## Getting started

Add `gcm_cryptor` to your `pubspec.yaml`:

```yaml
dependencies:
  gcm_cryptor: ^1.0.0
```

Run `flutter pub get` to install the package.

## Usage

Import the package in your Dart code:

```dart
import 'package:gcm_cryptor/gcm_cryptor.dart';
```

### 1. Key Generation

Generate a secure AES key using a master key and a unique timestamp (or salt).

```dart
final String masterKey = "MySuperSecretMasterKey";
final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

try {
  // Generates a 128-bit key (16 bytes)
  final List<int> keyBytes = GcmCryptor.instance.generateAESKey(masterKey, timestamp);

  // Convert to Base64 for storage or use in encryption
  final String keyBase64 = base64Encode(keyBytes);
  print("Generated Key: $keyBase64");
} catch (e) {
  print("Error generating key: $e");
}
```

### 2. Encryption

Encrypt a plaintext message.

```dart
final String plaintext = '{"message": "Hello, World!"}';
// Ensure you have your Base64 encoded key from the previous step
final String keyBase64 = ...;

try {
  // Encrypt returns a CryptoDto containing payload, nonce, and tag (all Base64)
  final CryptoDto encrypted = GcmCryptor.instance.encrypt(plaintext, keyBase64);

  print("Encrypted Payload: ${encrypted.payLoad}");
  print("Nonce: ${encrypted.nonce}");
  print("Tag: ${encrypted.tag}");
} catch (e) {
  print("Encryption failed: $e");
}
```

### 3. Decryption

Decrypt the payload using the key, nonce, and tag. All inputs should be Base64 encoded strings.

```dart
try {
  final String decryptedText = GcmCryptor.instance.decrypt(
    encrypted.payLoad, // Encrypted string
    keyBase64,         // The key used for encryption
    encrypted.nonce,   // The nonce used for encryption
    encrypted.tag      // The authentication tag
  );

  print("Decrypted: $decryptedText"); // Output: {"message": "Hello, World!"}
} catch (e) {
  print("Decryption failed: $e");
}
```

## Additional Information

This package ensures data integrity and confidentiality using industry-standard AES-GCM.
Always ensure your `Master Key` is kept secure.

**License**: This package is released under the MIT License. See [LICENSE](LICENSE) file for details.
