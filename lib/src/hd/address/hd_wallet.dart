// ignore_for_file: omit_local_variable_types

import "package:bip32_ed25519/bip32_ed25519.dart";
import "package:bip39_plus/bip39_plus.dart" as bip39;
import "package:cardano_dart_types/cardano_dart_types.dart";
import "../../utils/derivation_utils.dart";

///
/// This class implements a hierarchical deterministic wallet that generates cryptographic keys and
/// addresses given a root signing key. It also supports the creation/restoration of the root signing
/// key from a set of nmemonic BIP-39 words.
/// Cardano Shelley addresses are supported by default, but the code is general enough to support any
/// wallet based on the BIP32-ED25519 standard.
///
/// This code builds on following standards:
///
/// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki - HD wallets
/// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki - mnemonic words
/// https://github.com/bitcoin/bips/blob/master/bip-0043.mediawiki - Bitcoin purpose
/// https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki - multi-acct wallets
/// https://cips.cardano.org/cips/cip3/       - key generation
/// https://cips.cardano.org/cips/cip5/       - Bech32 prefixes
/// https://cips.cardano.org/cips/cip11/      - staking key
/// https://cips.cardano.org/cips/cip16/      - key serialisation
/// https://cips.cardano.org/cips/cip19/      - address structure
/// https://cips.cardano.org/cips/cip1852/    - 1852 purpose field
/// https://cips.cardano.org/cips/cip1855/    - forging keys
/// https://github.com/cardano-foundation/CIPs/tree/master/CIP-0105 - Conway drep/comittee derivations
/// https://raw.githubusercontent.com/input-output-hk/adrestia/master/user-guide/static/Ed25519_BIP.pdf
///
///
/// BIP-44 path:
///     m / purpose' / coin_type' / account_ix' / change_chain / address_ix
///
/// Cardano adoption:
///     m / 1852' / 1851' / account' / role / index
///
///
///  BIP-44 Wallets Key Hierarchy - Cardano derivation:
/// +--------------------------------------------------------------------------------+
/// |                BIP-39 Encoded Seed with CRC a.k.a Mnemonic Words               |
/// |                                                                                |
/// |    squirrel material silly twice direct ... razor become junk kingdom flee     |
/// |                                                                                |
/// +--------------------------------------------------------------------------------+
///        |
///        |
///        v
/// +--------------------------+    +-----------------------+
/// |    Wallet Private Key    |--->|   Wallet Public Key   |
/// +--------------------------+    +-----------------------+
///        |
///        | purpose (e.g. 1852')
///        |
///        v
/// +--------------------------+
/// |   Purpose Private Key    |
/// +--------------------------+
///        |
///        | coin type (e.g. 1815' for ADA)
///        v
/// +--------------------------+
/// |  Coin Type Private Key   |
/// +--------------------------+
///        |
///        | account ix (e.g. 0')
///        v
/// +--------------------------+    +-----------------------+
/// |   Account Private Key    |--->|   Account Public Key  |
/// +--------------------------+    +-----------------------+
///        |                                          |
///        | role   (e.g. 0=external/payments,        |
///        |         1=internal/change, 2=staking,    |
///        |         3 = drep creds,                  |
///        |         4 = const committee cold,        |
///        |         5 = const committee hot)         |
///        v                                          v
/// +--------------------------+    +-----------------------+
/// |    Role Private Key      |--->|    Role Public Key    |
/// +--------------------------+    +-----------------------+
///        |                                          |
///        | index (e.g. 0)                           |
///        v                                          v
/// +--------------------------+    +-----------------------+
/// |   Address Private Key    |--->|   Address Public Key  |
/// +--------------------------+    +-----------------------+
///
///
class HdWallet {
  final Bip32SigningKey rootSigningKey;
  final int accountIndex;
  late final Bip32SigningKey _purposeSKey;
  late final Bip32SigningKey _coinSKey;
  late final Bip32SigningKey _accountSKey;

  late final Lazy<Bip32KeyPair> _paymentRoleKeysDerivator = Lazy(
    () => DerivationUtils.derive(
      sKey: _accountSKey,
      index: Bip32KeyRole.payment.derivationIndex,
    ),
  ); // role 0
  late final Lazy<Bip32KeyPair> _changeRoleKeysDerivator = Lazy(
    () => DerivationUtils.derive(
      sKey: _accountSKey,
      index: Bip32KeyRole.change.derivationIndex,
    ),
  ); // role 1
  late final Lazy<Bip32KeyPair> _stakeRoleKeysDerivator = Lazy(
    () => DerivationUtils.derive(
      sKey: _accountSKey,
      index: Bip32KeyRole.staking.derivationIndex,
    ),
  ); // role 2
  late final Lazy<Bip32KeyPair> _drepCredentialRoleKeysDerivator = Lazy(
    () => DerivationUtils.derive(
      sKey: _accountSKey,
      index: Bip32KeyRole.drepCredential.derivationIndex,
    ),
  ); // role 3
  late final Lazy<Bip32KeyPair> _constitutionalCommitteeColdRoleKeysDerivator = Lazy(
    () => DerivationUtils.derive(
      sKey: _accountSKey,
      index: Bip32KeyRole.constitutionalCommitteeCold.derivationIndex,
    ),
  ); // role 4
  late final Lazy<Bip32KeyPair> _constitutionalCommitteeHotRoleKeysDerivator = Lazy(
    () => DerivationUtils.derive(
      sKey: _accountSKey,
      index: Bip32KeyRole.constitutionalCommitteeHot.derivationIndex,
    ),
  ); // role 5

  late final Lazy<Bip32KeyPair> stakeKeys = Lazy(
    () => DerivationUtils.derive(
      sKey: _stakeRoleKeysDerivator.value.signingKey,
      index: 0,
    ),
  );
  late final Lazy<Bip32KeyPair> drepCredentialKeys = Lazy(
    () => DerivationUtils.derive(
      sKey: _drepCredentialRoleKeysDerivator.value.signingKey,
      index: 0,
    ),
  );
  late final Lazy<Bip32KeyPair> constitutionalCommitteeColdKeys = Lazy(
    () => DerivationUtils.derive(
      sKey: _constitutionalCommitteeColdRoleKeysDerivator.value.signingKey,
      index: 0,
    ),
  );
  late final Lazy<Bip32KeyPair> constitutionalCommitteeHotKeys = Lazy(
    () => DerivationUtils.derive(
      sKey: _constitutionalCommitteeHotRoleKeysDerivator.value.signingKey,
      index: 0,
    ),
  );

  late final Bip32PublicKey accountPublicKey = _accountSKey.publicKey;

  /// root constructor taking a root signing key
  HdWallet({required this.rootSigningKey, required this.accountIndex}) {
    _purposeSKey = DerivationUtils.deriveHardened(signingKey: rootSigningKey, hardenedIndex: defaultPurpose);
    _coinSKey = DerivationUtils.deriveHardened(signingKey: _purposeSKey, hardenedIndex: defaultCoinType);
    _accountSKey = DerivationUtils.deriveHardened(signingKey: _coinSKey, hardenedIndex: accountIndex | hardenedOffset);

    // verify key that could derive all other public keys
    // print("xpub is ${Bech32Encoder(hrp: "xpub").encode(_accountSKey.verifyKey.toList())}");
  }

  Uint8List marshal() {
    final BinaryWriter writer = BinaryWriter();
    writer.writeByteList(rootSigningKey.asTypedList);
    writer.writeInt(accountIndex);

    return writer.toBytes();
  }

  factory HdWallet.unmarshal(Uint8List bytes) {
    final BinaryReader reader = BinaryReader(bytes);
    return HdWallet(
      rootSigningKey: Bip32SigningKey(reader.readByteList()),
      accountIndex: reader.readInt(),
    );
  }

  /// Create HdWallet from seed
  factory HdWallet.fromSeed(Uint8List seed, {int accountIndex = defaultAccountIndex}) => HdWallet(
    rootSigningKey: DerivationUtils.seedToBip32signingKey(seed),
    accountIndex: accountIndex,
  );

  factory HdWallet.fromHexEntropy(String hexEntropy, {int accountIndex = defaultAccountIndex}) => HdWallet(
    rootSigningKey: DerivationUtils.seedToBip32signingKey(hexEntropy.hexDecode().toUint8List()),
    accountIndex: accountIndex,
  );

  factory HdWallet.fromMnemonic(String mnemonic, {int accountIndex = defaultAccountIndex}) =>
      HdWallet.fromHexEntropy(bip39.mnemonicToEntropy(mnemonic.trim()), accountIndex: accountIndex);

  Bip32KeyPair _roleDerivationKeys(Bip32KeyRole role) => switch (role) {
    Bip32KeyRole.payment => _paymentRoleKeysDerivator.value,
    Bip32KeyRole.change => _changeRoleKeysDerivator.value,
    Bip32KeyRole.staking => _stakeRoleKeysDerivator.value,
    Bip32KeyRole.drepCredential => _drepCredentialRoleKeysDerivator.value,
    Bip32KeyRole.constitutionalCommitteeCold => _constitutionalCommitteeColdRoleKeysDerivator.value,
    Bip32KeyRole.constitutionalCommitteeHot => _constitutionalCommitteeHotRoleKeysDerivator.value,
  };

  /// return the root signing key
  Bip32VerifyKey get rootVerifyKey => rootSigningKey.verifyKey;

  /// run down the 5 level hierarchical chain to derive a new address key pair.
  Bip32KeyPair deriveAddressKeys({
    required Bip32KeyRole role,
    required int index,
  }) {
    final spendRoleKeys = _roleDerivationKeys(role);
    final addressKeys = DerivationUtils.derive(sKey: spendRoleKeys.signingKey, index: index);
    return addressKeys;
  }

  /// iterate key chain until an unused address is found, then return keys and address.
  CardanoAddressKit deriveBaseAddressKit({
    Bip32KeyRole role = Bip32KeyRole.payment,
    required int index,
    required NetworkId networkId,
  }) {
    assert(role == Bip32KeyRole.payment || role == Bip32KeyRole.change);

    final roleKeys = _roleDerivationKeys(role);

    final Bip32KeyPair keyPair = DerivationUtils.derive(sKey: roleKeys.signingKey, index: index);
    final CardanoAddress addr = toBaseAddress(spendVerifyKey: keyPair.verifyKey, networkId: networkId);

    return CardanoAddressKit(
      account: accountIndex,
      role: role,
      index: index,
      signingKey: keyPair.signingKey,
      verifyKey: keyPair.verifyKey,
      address: addr,
    );
  }

  /// construct a Shelley base address give a public spend key, public stake key and networkId
  CardanoAddress toBaseAddress({
    required Bip32PublicKey spendVerifyKey,
    required NetworkId networkId,
  }) => CardanoAddress.toBaseAddress(
    spend: spendVerifyKey,
    stake: stakeKeys.value.verifyKey,
    networkId: networkId,
  );

  /// construct a Shelley staking address give a public spend key and networkId
  CardanoAddress toRewardAddress({
    required NetworkId networkId,
  }) => CardanoAddress.toRewardAddress(
    spend: stakeKeys.value.verifyKey,
    networkId: networkId,
  );
}
