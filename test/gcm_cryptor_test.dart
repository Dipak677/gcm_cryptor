import 'package:flutter_test/flutter_test.dart';

import 'package:gcm_cryptor/gcm_cryptor.dart';

void main() {
  test('GcmCryptor instance is not null', () {
    final cryptor = GcmCryptor.instance;
    expect(cryptor, isNotNull);
  });
}
