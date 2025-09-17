import "dart:async";

import "package:bip32_ed25519/bip32_ed25519.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";

import "../../cardano_flutter_sdk.dart";
import "../../workers/wallet_tasks.dart";

const xPubBech32Hrp = "xpub";

class CardanoWalletImpl extends CardanoWallet {
  final HdWallet hdWallet;
  @override
  final int accountIndex;
  @override
  final NetworkId networkId;
  @override
  final CardanoAddress stakeAddress;
  @override
  final CardanoAddress firstAddress;

  @override
  Lazy<CardanoDerivedAddress> get stakeDerivation => Lazy(
    () => CardanoDerivedAddress(
      type: AddressType.reward,
      bytes: hdWallet.stakeKeys.value.verifyKey.rawKey,
    ),
  );
  // Using `verifyKey.rawKey` to get only the key bytes without chain code (the suffix)
  @override
  late final Lazy<DRepDerivation> drepId = Lazy(
    () => DRepDerivation(bytes: hdWallet.drepCredentialKeys.value.verifyKey.rawKey),
  );
  // Using `verifyKey.rawKey` to get only the key bytes without chain code (the suffix)
  @override
  late final Lazy<ConstitutionalCommiteeCold> constitutionalCommiteeCold = Lazy(
    () => ConstitutionalCommiteeCold(bytes: hdWallet.constitutionalCommitteeColdKeys.value.verifyKey.rawKey),
  );
  // Using `verifyKey.rawKey` to get only the key bytes without chain code (the suffix)
  @override
  late final Lazy<ConstitutionalCommiteeHot> constitutionalCommiteeHot = Lazy(
    () => ConstitutionalCommiteeHot(bytes: hdWallet.constitutionalCommitteeHotKeys.value.verifyKey.rawKey),
  );

  @override
  late final String xPubBech32 = hdWallet.accountPublicKey.bech32Encode(xPubBech32Hrp);

  CardanoWalletImpl({
    required this.firstAddress,
    required this.stakeAddress,
    required this.hdWallet,
    this.accountIndex = 0,
  }) : networkId = stakeAddress.bech32Encoded.startsWith("stake_test") ? NetworkId.testnet : NetworkId.mainnet;

  @override
  Uint8List marshal() {
    final BinaryWriterImpl writer = BinaryWriterImpl();
    writer.writeByteList(hdWallet.marshal());
    writer.writeInt(accountIndex);
    writer.writeString(stakeAddress.marshal());
    writer.writeString(firstAddress.marshal());
    return writer.toBytes();
  }

  factory CardanoWalletImpl.unmarshal(Uint8List bytes) {
    final BinaryReader reader = BinaryReaderImpl(bytes);
    final hdWallet = HdWallet.unmarshal(reader.readByteList());
    final accountIndex = reader.readInt();
    final stakeAddress = CardanoAddress.unmarshal(reader.readString());
    final firstAddress = CardanoAddress.unmarshal(reader.readString());
    return CardanoWalletImpl(
      hdWallet: hdWallet,
      accountIndex: accountIndex,
      firstAddress: firstAddress,
      stakeAddress: stakeAddress,
    );
  }

  // WalletId get walletId => stakeAddress.bech32Encoded;

  @override
  String toString() => "CardanoWalletImpl(stake_address: ${stakeAddress.bech32Encoded})";

  @override
  Future<CardanoAddressKit> getPaymentAddressKit({required int addressIndex}) =>
      cardanoWorker.deriveAddressKit(hdWallet, networkId, addressIndex, Bip32KeyRole.payment);

  @override
  Future<CardanoAddressKit> getChangeAddressKit({required int addressIndex}) =>
      cardanoWorker.deriveAddressKit(hdWallet, networkId, addressIndex, Bip32KeyRole.change);

  @override
  Bip32KeyPair rootKeyPair() => Bip32KeyPair(signingKey: hdWallet.rootSigningKey, verifyKey: hdWallet.rootVerifyKey);

  @override
  ByteList get seed => hdWallet.rootSigningKey;

  @override
  Future<WitnessSet> signTransaction({
    required CardanoTransaction tx,
    required Set<String> witnessBech32Addresses,
    int deriveMaxAddressCount = 1000,
  }) => cardanoWorker
      .signTransactionsBundle(
        this,
        TxSigningBundle(
          txsData: [
            TxPreparedForSigning(
              tx: tx,
              txDiff: TxDiff(
                diff: Value.v0(lovelace: BigInt.zero),
                usedUtxos: [],
                dRepDeregistration: false,
                stakeDeregistration: false,
                stakeDelegationPoolId: null,
                authorizeConstitutionalCommitteeHot: null,
                dRepDelegation: null,
                dRepRegistration: null,
                dRepUpdate: null,
                resignConstitutionalCommitteeCold: null,
                votes: const [],
                proposals: const [],
              ),
              utxosBeforeTx: [],
              signingAddressesRequired: witnessBech32Addresses,
            ),
          ],
          receiveAddressBech32: firstAddress.bech32Encoded,
          networkId: networkId,
          totalDiff: Value.v0(lovelace: BigInt.zero),
          dRepDeregistration: false,
          stakeDeregistration: false,
          stakeDelegationPoolId: null,
          authorizeConstitutionalCommitteeHot: null,
          dRepDelegation: null,
          dRepRegistration: null,
          dRepUpdate: null,
          resignConstitutionalCommitteeCold: null,
          votes: const [],
          proposals: const [],
        ),
        deriveMaxAddressCount,
      )
      .then((e) => e.txsData[0].nweSignatures);

  @override
  Future<TxSignedBundle> signTransactionsBundle(
    TxSigningBundle bundle, {
    int deriveMaxAddressCount = 1000,
  }) {
    if (firstAddress.bech32Encoded != bundle.receiveAddressBech32) {
      throw InvalidWalletUsedForSigningException(
        expectedWalletAddress: bundle.receiveAddressBech32,
        actualWalletAddress: firstAddress.bech32Encoded,
      );
    }
    if (networkId != bundle.networkId) {
      throw InvalidWalletNetworkForSigningException(
        expectedWalletNetwork: bundle.networkId,
        actualWalletNetwork: networkId,
      );
    }

    return cardanoWorker.signTransactionsBundle(this, bundle, deriveMaxAddressCount);
  }

  @override
  Future<DataSignature> signData({
    required String payloadHex,
    required String requestedSignerRaw,
    int deriveMaxAddressCount = 1000,
  }) => cardanoWorker.signData(this, payloadHex, requestedSignerRaw, deriveMaxAddressCount);

  // Contains root public key that can derive all payment/change/stake public keys / addresses
  @override
  Future<CardanoPubAccount> cardanoPubAccount() =>
      CardanoPubAccountWorkerFactory.instance.fromAccountKey(hdWallet.accountPublicKey);
}
