import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart' as crypto_hash;
import 'package:cryptography/cryptography.dart' as crypto_lib;
import 'package:pointycastle/export.dart';

/// M1.2 - Asymmetric Key Pair Provisioning
///
/// Generates and manages Ed25519 or RSA-2048 key pairs per device.
/// Private key NEVER leaves the device (stored in secure enclave/keystore).
/// Public key is registered with server via POST /api/auth/keys/provision.
///
/// Used for:
/// - M3.3: Mesh E2E encryption
/// - M5.1: Proof-of-Delivery signature verification
class KeyPairManager {
  /// Generates an Ed25519 key pair (recommended - faster, smaller)
  ///
  /// Ed25519 provides:
  /// - 128-bit security level
  /// - Fast signature generation
  /// - Small key size (32 bytes)
  /// - Deterministic signatures
  ///
  /// Returns a Map with:
  /// - 'publicKey': Base64-encoded public key
  /// - 'privateKey': Base64-encoded private key (MUST be stored securely)
  /// - 'keyType': 'ed25519'
  static Future<Map<String, String>> generateEd25519KeyPair() async {
    final algorithm = crypto_lib.Ed25519();
    final keyPair = await algorithm.newKeyPair();

    final publicKeyBytes = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    return {
      'publicKey': base64Encode(publicKeyBytes.bytes),
      'privateKey': base64Encode(privateKeyBytes),
      'keyType': 'ed25519',
    };
  }

  /// Generates an RSA-2048 key pair (alternative option)
  ///
  /// RSA-2048 provides:
  /// - 112-bit security level
  /// - Wider compatibility
  /// - Larger key size (256 bytes)
  ///
  /// Returns a Map with:
  /// - 'publicKey': PEM-encoded public key
  /// - 'privateKey': PEM-encoded private key (MUST be stored securely)
  /// - 'keyType': 'rsa2048'
  static Map<String, String> generateRSA2048KeyPair() {
    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(
            BigInt.parse('65537'), // Standard public exponent
            2048, // Key size in bits
            64, // Certainty for prime generation
          ),
          FortunaRandom()..seed(KeyParameter(_generateRandomSeed(32))),
        ),
      );

    final keyPair = keyGen.generateKeyPair();
    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;

    return {
      'publicKey': _encodeRSAPublicKeyToPem(publicKey),
      'privateKey': _encodeRSAPrivateKeyToPem(privateKey),
      'keyType': 'rsa2048',
    };
  }

  /// Signs a message using Ed25519 private key
  ///
  /// [message] Message to sign (e.g., delivery_id for PoD)
  /// [privateKeyBase64] Base64-encoded Ed25519 private key
  ///
  /// Returns Base64-encoded signature
  static Future<String> signWithEd25519({
    required String message,
    required String privateKeyBase64,
  }) async {
    final algorithm = crypto_lib.Ed25519();
    final privateKeyBytes = base64Decode(privateKeyBase64);

    final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
    final signature = await algorithm.sign(
      utf8.encode(message),
      keyPair: keyPair,
    );

    return base64Encode(signature.bytes);
  }

  /// Verifies an Ed25519 signature
  ///
  /// [message] Original message
  /// [signatureBase64] Base64-encoded signature
  /// [publicKeyBase64] Base64-encoded Ed25519 public key
  ///
  /// Returns true if signature is valid
  static Future<bool> verifyEd25519Signature({
    required String message,
    required String signatureBase64,
    required String publicKeyBase64,
  }) async {
    final algorithm = crypto_lib.Ed25519();
    final publicKeyBytes = base64Decode(publicKeyBase64);
    final signatureBytes = base64Decode(signatureBase64);

    final publicKey = crypto_lib.SimplePublicKey(
      publicKeyBytes,
      type: crypto_lib.KeyPairType.ed25519,
    );

    final signature = crypto_lib.Signature(
      signatureBytes,
      publicKey: publicKey,
    );

    final isValid = await algorithm.verify(
      utf8.encode(message),
      signature: signature,
    );

    return isValid;
  }

  /// Encrypts a message using recipient's Ed25519 public key
  ///
  /// [message] Message to encrypt
  /// [recipientPublicKeyBase64] Base64-encoded Ed25519 public key
  ///
  /// Returns Base64-encoded encrypted message
  static Future<String> encryptWithEd25519({
    required String message,
    required String recipientPublicKeyBase64,
  }) async {
    // Use X25519 (ECDH on Curve25519) for encryption
    final algorithm = crypto_lib.X25519();
    final ephemeralKeyPair = await algorithm.newKeyPair();

    final recipientPublicKey = crypto_lib.SimplePublicKey(
      base64Decode(recipientPublicKeyBase64).sublist(0, 32),
      type: crypto_lib.KeyPairType.x25519,
    );

    // Derive shared secret
    final sharedSecret = await algorithm.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: recipientPublicKey,
    );

    // Encrypt with AES-256-GCM (as per C5 constraint)
    final aesGcm = crypto_lib.AesGcm.with256bits();
    final secretBox = await aesGcm.encrypt(
      utf8.encode(message),
      secretKey: sharedSecret,
    );

    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

    // Package: ephemeral_public_key || nonce || ciphertext || mac
    final package = {
      'ephemeral_pk': base64Encode(ephemeralPublicKey.bytes),
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    return base64Encode(utf8.encode(jsonEncode(package)));
  }

  /// Decrypts a message using own Ed25519 private key
  ///
  /// [encryptedMessageBase64] Base64-encoded encrypted package
  /// [privateKeyBase64] Base64-encoded Ed25519 private key
  ///
  /// Returns decrypted message
  static Future<String> decryptWithEd25519({
    required String encryptedMessageBase64,
    required String privateKeyBase64,
  }) async {
    final packageJson = jsonDecode(
      utf8.decode(base64Decode(encryptedMessageBase64)),
    );

    final ephemeralPublicKeyBytes = base64Decode(packageJson['ephemeral_pk']);
    final nonce = base64Decode(packageJson['nonce']);
    final ciphertext = base64Decode(packageJson['ciphertext']);
    final mac = base64Decode(packageJson['mac']);

    // Derive shared secret using our private key and ephemeral public key
    final algorithm = crypto_lib.X25519();
    final privateKeyBytes = base64Decode(privateKeyBase64).sublist(0, 32);
    final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);

    final ephemeralPublicKey = crypto_lib.SimplePublicKey(
      ephemeralPublicKeyBytes,
      type: crypto_lib.KeyPairType.x25519,
    );

    final sharedSecret = await algorithm.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: ephemeralPublicKey,
    );

    // Decrypt with AES-256-GCM
    final aesGcm = crypto_lib.AesGcm.with256bits();
    final secretBox = crypto_lib.SecretBox(
      ciphertext,
      nonce: nonce,
      mac: crypto_lib.Mac(mac),
    );

    final decryptedBytes = await aesGcm.decrypt(
      secretBox,
      secretKey: sharedSecret,
    );

    return utf8.decode(decryptedBytes);
  }

  /// Generates a SHA-256 hash of data (used for audit trail in M1.4)
  ///
  /// [data] Data to hash
  /// Returns hex-encoded hash
  static String sha256Hash(String data) {
    final bytes = utf8.encode(data);
    final digest = crypto_hash.sha256.convert(bytes);
    return digest.toString();
  }

  // ── Private Helper Methods ──────────────────────────────────────────

  static Uint8List _generateRandomSeed(int length) {
    final random = FortunaRandom();
    final seedSource = Uint8List.fromList(
      List<int>.generate(
        length,
        (i) => DateTime.now().millisecondsSinceEpoch % 256,
      ),
    );
    random.seed(KeyParameter(seedSource));
    return random.nextBytes(length);
  }

  static String _encodeRSAPublicKeyToPem(RSAPublicKey publicKey) {
    final algorithmSeq = ASN1Sequence();
    final algorithmAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList([
        0x06,
        0x09,
        0x2a,
        0x86,
        0x48,
        0x86,
        0xf7,
        0x0d,
        0x01,
        0x01,
        0x01,
      ]),
    );
    final paramsAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList([0x05, 0x00]),
    );
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    final publicKeySeq = ASN1Sequence();
    publicKeySeq.add(ASN1Integer(publicKey.modulus!));
    publicKeySeq.add(ASN1Integer(publicKey.exponent!));
    final publicKeySeqBitString = ASN1BitString(
      Uint8List.fromList(publicKeySeq.encodedBytes),
    );

    final topLevelSeq = ASN1Sequence();
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqBitString);
    final dataBase64 = base64Encode(topLevelSeq.encodedBytes);

    return '-----BEGIN PUBLIC KEY-----\n$dataBase64\n-----END PUBLIC KEY-----';
  }

  static String _encodeRSAPrivateKeyToPem(RSAPrivateKey privateKey) {
    final version = ASN1Integer(BigInt.from(0));
    final modulus = ASN1Integer(privateKey.n!);
    final publicExponent = ASN1Integer(privateKey.exponent!);
    final privateExponent = ASN1Integer(privateKey.d!);
    final p = ASN1Integer(privateKey.p!);
    final q = ASN1Integer(privateKey.q!);
    final dP = privateKey.d! % (privateKey.p! - BigInt.one);
    final dQ = privateKey.d! % (privateKey.q! - BigInt.one);
    final qInv = privateKey.q!.modInverse(privateKey.p!);

    final seq = ASN1Sequence();
    seq.add(version);
    seq.add(modulus);
    seq.add(publicExponent);
    seq.add(privateExponent);
    seq.add(p);
    seq.add(q);
    seq.add(ASN1Integer(dP));
    seq.add(ASN1Integer(dQ));
    seq.add(ASN1Integer(qInv));

    final dataBase64 = base64Encode(seq.encodedBytes);
    return '-----BEGIN RSA PRIVATE KEY-----\n$dataBase64\n-----END RSA PRIVATE KEY-----';
  }
}
