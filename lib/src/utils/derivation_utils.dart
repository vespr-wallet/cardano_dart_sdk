import "package:bip32_ed25519/api.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:pinenacl/key_derivation.dart";

class DerivationUtils {
  const DerivationUtils._();

  static const Bip32Ed25519KeyDerivation _derivator = Bip32Ed25519KeyDerivation.instance;

  static Bip32SigningKey deriveHardened({
    required Bip32SigningKey signingKey,
    required int hardenedIndex,
  }) {
    // computes a child extended private key from the parent extended private key.
    if (!isHardened(hardenedIndex)) {
      throw Exception("Bip32KeyPair deriveHardned: Illegal State index is not hardned");
    }

    return _derivator.ckdPriv(signingKey, hardenedIndex) as Bip32SigningKey;
  }

  static Bip32KeyPair derive({
    required Bip32SigningKey sKey,
    required int index,
  }) {
    if (isHardened(index)) {
      throw Exception("Bip32KeyPair derive: Illegal State index is hardned");
    }
    final Bip32SigningKey signingKey = _derivator.ckdPriv(sKey, index) as Bip32SigningKey;

    final Bip32VerifyKey verifyKey = _derivator.neuterPriv(signingKey) as Bip32VerifyKey;
    return Bip32KeyPair(signingKey: signingKey, verifyKey: verifyKey);
  }

  static Bip32PublicKey derivePublicKey({
    required Bip32PublicKey pubKey,
    required int index,
  }) {
    if (isHardened(index)) {
      throw Exception("Bip32PublicKey derivePublicKey: Illegal State index is hardned");
    }
    return _derivator.ckdPub(pubKey, index);
  }

  /// derive root signing key given a seed
  static Bip32SigningKey seedToBip32signingKey(Uint8List seed) {
    final rawMaster = PBKDF2.hmac_sha512(Uint8List(0), seed, 4096, cip16ExtendedSigningKeySize);
    final Bip32SigningKey rootXsk = Bip32SigningKey.normalizeBytes(rawMaster);
    return rootXsk;
  }

  /// Hardens index, meaning it won't have a public key
  static int harden(int index) => index | hardenedOffset;

  /// Returns true if index is hardened.
  static bool isHardened(int index) => index & hardenedOffset != 0;
}

/// Extended private key size in bytes
const cip16ExtendedSigningKeySize = 96;

/// Extended public key size in bytes
const cip16ExtendedVerificationKeySize = 64;
