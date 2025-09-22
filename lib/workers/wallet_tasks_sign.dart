import "dart:async";

import "package:cardano_dart_types/cardano_dart_types.dart";

import "../src/hd/address/cardano_pub_account_x.dart";
import "../src/hd/cardano_wallet.dart";
import "../src/models/cardano_signer.dart";

const _unknownAccountIndex = -1;

class WalletTasksSign {
  const WalletTasksSign._();

  // This is a synchronous operation, but it's heavy compute
  static FutureOr<Bip32KeyPair> signerToSigningKeyPair({
    required CardanoWalletImpl wallet,
    required CardanoSigner signer,
  }) => wallet.hdWallet.deriveAddressKeys(
    role: signer.path.role,
    index: signer.path.address,
  );

  static Future<CardanoSigner> findCardanoSigner({
    required CardanoPubAccount pubAccount,
    required String requestedSignerRaw, // hex or bech32
    required int deriveMaxAddressCount, // max number of addresses to derive for payment and change
  }) async {
    // if it's a bech32, convert it to hex
    final requestedSignerHex = ["addr", "stake", "drep", "cc_hot", "cc_cold"].any(requestedSignerRaw.startsWith)
        ? requestedSignerRaw.bech32ToHex()
        : requestedSignerRaw;

    final FutureOr<CardanoSigner> data = switch (requestedSignerHex.length) {
      // This is used for dRep (CIP-95)
      //
      // NOTE: In the future, we can maybe also check against any other payment/change/stake/cc credentials
      //   (since the 56 bytes creds do not include the header which tells us the creds type)
      56 => _dataFromDrepIdOrDrepCreds(
        drepIdOrCredsHex: requestedSignerHex,
        pubAccount: pubAccount,
        deriveMaxAddressCount: deriveMaxAddressCount,
        requestedSignerHex: requestedSignerHex,
      ),
      // 58 or 114 is the length of the stake or receive address hex
      58 => () {
        final requestedSignerBytes = requestedSignerHex.hexDecode();
        final headerBytes = requestedSignerBytes[0];
        return headerBytes & 0x0f > 1
            ? _dataFromDrepIdOrDrepCreds(
                drepIdOrCredsHex: requestedSignerHex,
                pubAccount: pubAccount,
                deriveMaxAddressCount: deriveMaxAddressCount,
                requestedSignerHex: requestedSignerHex,
              )
            : _dataFromAddress(
                requestedSigningAddress: CardanoAddress.fromHexString(requestedSignerHex),
                pubAccount: pubAccount,
                deriveMaxAddressCount: deriveMaxAddressCount,
                requestedSignerHex: requestedSignerHex,
              );
      }(),
      114 => _dataFromAddress(
        requestedSigningAddress: CardanoAddress.fromHexString(requestedSignerHex),
        pubAccount: pubAccount,
        deriveMaxAddressCount: deriveMaxAddressCount,
        requestedSignerHex: requestedSignerHex,
      ),
      _ => throw SigningAddressNotValidException(
        hexInvalidAddressOrCredential: requestedSignerHex,
        signingContext: "When signing payload message",
      ),
    };

    return await data;
  }
}

FutureOr<CardanoSigner> _dataFromDrepIdOrDrepCreds({
  required String drepIdOrCredsHex,
  required CardanoPubAccount pubAccount,
  required int deriveMaxAddressCount,
  required String requestedSignerHex,
}) {
  final walletDRepDerivation = pubAccount.dRepDerivation.value;
  final walletDrepCredentials = walletDRepDerivation.credentialsHex;
  if (!drepIdOrCredsHex.endsWith(walletDrepCredentials)) {
    throw SigningAddressNotFoundException(
      missingAddresses: {requestedSignerHex},
      searchedAddressesCount: 1,
    );
  }

  return CardanoSigner(
    publicKeyBytes: walletDRepDerivation.bytes,
    // requeste signer bytes are the wallet drep credentials
    // for any drep format (old/new) or encoding (hex/bech32)
    requestedSignerBytes: walletDrepCredentials.hexDecode(),
    path: CardanoSigningPath_Shelley(
      account: _unknownAccountIndex,
      address: 0,
      role: Bip32KeyRole.drepCredential,
    ),
  );
}

FutureOr<CardanoSigner> _dataFromAddress({
  required CardanoPubAccount pubAccount,
  required CardanoAddress requestedSigningAddress,
  required int deriveMaxAddressCount,
  required String requestedSignerHex,
}) async => switch (requestedSigningAddress.addressType) {
  AddressType.reward => () {
    if (requestedSigningAddress.credentials == pubAccount.stakeDerivation.value.credentialsHex) {
      return CardanoSigner(
        publicKeyBytes: pubAccount.stakeDerivation.value.bytes,
        requestedSignerBytes: requestedSignerHex.hexDecode(),
        path: CardanoSigningPath_Shelley(account: _unknownAccountIndex, address: 0, role: Bip32KeyRole.staking),
      );
    } else {
      throw SigningAddressNotFoundException(
        missingAddresses: {requestedSigningAddress.bech32Encoded},
        searchedAddressesCount: 1,
      );
    }
  }(),
  AddressType.base => () async {
    for (int i = 0; i < deriveMaxAddressCount; i++) {
      final paymentAddrForIndex = pubAccount.paymentAddress(
        i,
        requestedSigningAddress.networkId,
      );
      final changeAddrForIndex = pubAccount.changeAddress(
        i,
        requestedSigningAddress.networkId,
      );
      if ((await paymentAddrForIndex) == requestedSigningAddress) {
        return CardanoSigner(
          publicKeyBytes: (await pubAccount.paymentPublicKey(i)).rawKey,
          requestedSignerBytes: requestedSignerHex.hexDecode(),
          path: CardanoSigningPath_Shelley(account: _unknownAccountIndex, address: i, role: Bip32KeyRole.payment),
        );
      } else if ((await changeAddrForIndex) == requestedSigningAddress) {
        return CardanoSigner(
          publicKeyBytes: (await pubAccount.changePublicKey(i)).rawKey,
          requestedSignerBytes: requestedSignerHex.hexDecode(),
          path: CardanoSigningPath_Shelley(account: _unknownAccountIndex, address: i, role: Bip32KeyRole.change),
        );
      }
    }

    // if not found in for loop, throw
    throw SigningAddressNotFoundException(
      missingAddresses: {requestedSigningAddress.bech32Encoded},
      searchedAddressesCount: deriveMaxAddressCount,
    );
  }(),
  AddressType.pointer || AddressType.enterprise || AddressType.byron => throw UnexpectedSigningAddressTypeException(
    hexAddress: requestedSignerHex,
    type: requestedSigningAddress.addressType,
    signingContext: "When signing payload message",
  ),
};
