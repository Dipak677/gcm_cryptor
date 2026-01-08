import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gcm_cryptor/gcm_cryptor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "GCM Cryptor Example",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: "GCM Cryptor Example"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Controllers
  final TextEditingController _masterKeyController = TextEditingController(
    text: "MySecretMasterKey",
  );

  final TextEditingController _timestampController = TextEditingController();

  final TextEditingController _plaintextController = TextEditingController(
    text: "{\"message\": \"Hello World\"}",
  );

  final TextEditingController _nonceController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _encryptedPayloadController =
      TextEditingController();
  final TextEditingController _generatedKeyController = TextEditingController();

  // State values
  String _generatedKey = "";
  String _decryptedText = "";
  String _checksum = "";
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _timestampController.text = DateTime.now().millisecondsSinceEpoch
        .toString();
  }

  @override
  void dispose() {
    _masterKeyController.dispose();
    _timestampController.dispose();
    _plaintextController.dispose();
    _nonceController.dispose();
    _tagController.dispose();
    _encryptedPayloadController.dispose();
    _generatedKeyController.dispose();
    super.dispose();
  }

  void _generateKey() {
    try {
      final String masterKey = _masterKeyController.text;
      final String timestamp = _timestampController.text;

      if (masterKey.isEmpty || timestamp.isEmpty) {
        setState(() {
          _statusMessage = "Master Key and Timestamp are required.";
        });
        return;
      }

      final List<int> keyBytes = GcmCryptor.instance.generateAESKey(
        masterKey,
        timestamp,
      );

      setState(() {
        _generatedKey = base64Encode(keyBytes);
        _generatedKeyController.text = _generatedKey;
        _statusMessage = "Key Generated Successfully!";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error generating key: $e";
      });
    }
  }

  void _encrypt() {
    if (_generatedKey.isEmpty) {
      setState(() {
        _statusMessage = "Please generate a key first.";
      });
      return;
    }

    try {
      final String plaintext = _plaintextController.text;

      final CryptoDto cryptoDto = GcmCryptor.instance.encrypt(
        plaintext,
        _generatedKey,
      );

      setState(() {
        _encryptedPayloadController.text = cryptoDto.payLoad;
        _nonceController.text = cryptoDto.nonce;
        _tagController.text = cryptoDto.tag;
        _checksum = GcmCryptor.instance.calculateChecksum(
          utf8.encode(plaintext),
        );
        _statusMessage = "Encryption Successful!";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error encrypting: $e";
      });
    }
  }

  void _decrypt() {
    if (_generatedKey.isEmpty) {
      setState(() {
        _statusMessage = "Please generate a key first.";
      });
      return;
    }

    try {
      final String encryptedPayload = _encryptedPayloadController.text;
      final String nonce = _nonceController.text;
      final String tag = _tagController.text;

      final String decryptedText = GcmCryptor.instance.decrypt(
        encryptedPayload,
        _generatedKey,
        nonce,
        tag,
      );

      setState(() {
        _decryptedText = decryptedText;
        _statusMessage = "Decryption Successful!";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error decrypting: $e";
        _decryptedText = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              "1. Generate Key",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _masterKeyController,
              decoration: const InputDecoration(labelText: "Master Key"),
            ),
            TextField(
              controller: _timestampController,
              decoration: const InputDecoration(labelText: "Timestamp"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _generateKey,
              child: const Text("Generate AES Key"),
            ),
            if (_generatedKey.isNotEmpty)
              SelectableText(
                "Generated Key (Base64): $_generatedKey",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            const Divider(height: 30),

            const Text(
              "2. Encrypt",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _plaintextController,
              decoration: const InputDecoration(
                labelText: "Plaintext (JSON or String)",
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _encrypt, child: const Text("Encrypt")),
            if (_encryptedPayloadController.text.isNotEmpty) ...<Widget>[
              _readOnlyField("Payload (Base64)", _encryptedPayloadController),
              _readOnlyField("Nonce (Base64)", _nonceController),
              _readOnlyField("Tag (Base64)", _tagController),
              if (_checksum.isNotEmpty) Text("Checksum: $_checksum"),
            ],

            const Divider(height: 30),

            const Text(
              "3. Decrypt",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(onPressed: _decrypt, child: const Text("Decrypt")),
            if (_decryptedText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.greenAccent,
                child: Text("Decrypted Text: $_decryptedText"),
              ),

            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        readOnly: false,
      ),
    );
  }
}
