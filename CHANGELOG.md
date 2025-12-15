## 3.2.0

Web workers built with Flutter 3.38.5 and cardano_dart_types 2.12.0

### Added

- Enterprise address signing support in `signData()` - can now sign with enterprise addresses using payment credentials

### Changed

- Updated Flutter to 3.38.5
- Updated cardano_dart_types to 2.12.0
- Re-generated web workers

## 3.1.1

Web workers built with Flutter 3.38.3 and cardano_dart_types 2.11.2

### Bug Fixes
- Re-serializing transactions with non-asc order for the TX Body CBOR entries now works correctly (original order is retained instead of serializing with ascending order for the keys)
- Re-serializing correctly retains empty metadata hash in tx body

## 3.1.0

Web workers built with Flutter 3.38.3 and cardano_dart_types 2.11.0

### Bug Fixes

- Some inconsistency where web could generate invalid tx signatures while mobile would generate a valid signature (for the same transaction) - Fix coming from the updated cardano_dart_types version.

### 🔧 Changed

- Updated Flutter to 3.38.3
- Updated cardano_dart_types to 2.11.0
- Updated Squadron to 7.4.0
- Updated Squadron Builder to 9.0.0+1
- Re-generated web workers

## 3.0.0

Web workers Built with Flutter 3.35.7

### ⚠️ BREAKING CHANGES

- **API Change**: `prepareTxsForSigning()` moved to `SigningUtils.prepareTxsForSigning()`

  ```dart
  // Before
  await prepareTxsForSigning(txs: [...], ...);
  // After
  await SigningUtils.prepareTxsForSigning(txs: [...], ...);
  ```

- **Minimum Dart SDK increased to 3.9.0** (from 3.6.0)

### ✨ Added

- New `CardanoSigner` model for managing signing operations
- New `SigningUtils` helper methods: `prepareCoseHeaders()`, `prepareBytesToSign()`, `prepareDataSignature()`
- Improved `signData()` with better address/credential matching (legacy mode available via `useLegacy: true` if needed)
- Chrome Extension Manifest V3 compatibility (web workers now work in browser extensions)

### 🔧 Changed

- Updated Squadron to 7.2.0
- Updated cardano_dart_types to 2.10.0

### 🐛 Fixed

- Fixed enterprise address matching in signing operations
- Fixed DRep credential handling
- Fixed `accountIndex` serialization in `CardanoWalletImpl`

## 2.5.4

Web workers Built with Flutter 3.32.8

Changes

- [CHORE] Updated Flutter version
- [CHORE] Updated Cardano Dart Types version

## 2.5.3

- [Web workers] Built with Flutter 3.32.5
- Exposed blake2b hashing utils
- Updated cardano dart types version

## 2.5.2

Flutter 3.32.5

- Updated squadron major version
- Removed freezed deps

## [2.5.1+1] - May 6, 2025

Flutter 3.32.5

- Updated flutter version
- Re-generated JS files with latest flutter/dart
- Improved readme

## [2.5.1] - May 6, 2025

Flutter 3.29.3

New

- signData also works with old dRep id (creds without the header byte)

## [2.5.0] - April 20, 2025

Flutter 3.29.3

New

- signData also works with dRep keys
- signData now accepts both hex and bech32 encoding for requested signer

Breaking Changes

- signData has some re-named args

Important Changes

- Message signing no longer adds keyId to the protected headers

## [2.4.14] - January 3, 2025

Flutter 3.27.1

Changes

- Updated and fixed lints
- Updated types

## [2.4.13] - 9th of December, 2024

Flutter 3.27.0-0.2.pre

# Changes

- Fixed some issue with signData not checking if the rewards account matches expected one

## [2.4.12] - 20th of November, 2024

Flutter 3.27.0-0.2.pre

# Changes

- Updated min squadron dependency (older version not working)

## [2.4.11] - 19th of November, 2024

Flutter 3.27.0-0.2.pre

# Changes

- Updated cardano types dependency (fixing some tx parsing)

## [2.4.10] - 17th of November, 2024

Flutter 3.27.0-0.1.pre

# Changes

- Updated cardano types dependency (added xpub in [CardanoWallet])
- Updated squadron

## [2.4.9] - 5th of November, 2024

Flutter 3.27.0-0.1.pre

# Changes

- Updated cardano types dependency
- Updated squadron

## [2.4.8] - 29th of October, 2024

Flutter 3.27.0-0.1.pre

# Changes

- Updated cardano types dependency

## [2.4.7] - 7th of October, 2024

Flutter 3.26.0-0.1.pre

# Changes

- Updated types to fix redeemer as map (conway era)

## [2.4.6] - 3rd of October, 2024

Flutter 3.26.0-0.1.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision ee624bc4fd (3 weeks ago) • 2024-09-10 17:41:06 -0500
Engine • revision 059e4e6d8f
Tools • Dart 3.6.0 (build 3.6.0-216.1.beta) • DevTools 2.39.0

# Changes

- Updated types to fix some compile-time bug

## [2.4.5] - 3rd of October, 2024

Flutter 3.26.0-0.1.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision ee624bc4fd (3 weeks ago) • 2024-09-10 17:41:06 -0500
Engine • revision 059e4e6d8f
Tools • Dart 3.6.0 (build 3.6.0-216.1.beta) • DevTools 2.39.0

# Changes

- Updated types to fix an encoding bug

## [2.4.4] - 3rd of October, 2024

Flutter 3.26.0-0.1.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision ee624bc4fd (3 weeks ago) • 2024-09-10 17:41:06 -0500
Engine • revision 059e4e6d8f
Tools • Dart 3.6.0 (build 3.6.0-216.1.beta) • DevTools 2.39.0

# Changes

- Fixed a bug with worker pool causing deadlock | hanging requests

## [2.4.3] - 3rd of October, 2024

Flutter 3.26.0-0.1.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision ee624bc4fd (3 weeks ago) • 2024-09-10 17:41:06 -0500
Engine • revision 059e4e6d8f
Tools • Dart 3.6.0 (build 3.6.0-216.1.beta) • DevTools 2.39.0

# Changes

- Updated types to fix some serialization issue

## [2.4.2] - 29th of September, 2024

Flutter 3.26.0-0.1.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision ee624bc4fd (3 weeks ago) • 2024-09-10 17:41:06 -0500
Engine • revision 059e4e6d8f
Tools • Dart 3.6.0 (build 3.6.0-216.1.beta) • DevTools 2.39.0

# Changes

- Updated squadron builder

## [2.4.1] - 29th of September, 2024

Flutter 3.26.0-0.1.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision ee624bc4fd (3 weeks ago) • 2024-09-10 17:41:06 -0500
Engine • revision 059e4e6d8f
Tools • Dart 3.6.0 (build 3.6.0-216.1.beta) • DevTools 2.39.0

# Changes

- Changed squadron worker pool to automatically decide whether to use js or wasm for worker(s)

## [2.4.0] - 29th of September, 2024

Flutter 3.26.0-0.1.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision ee624bc4fd (3 weeks ago) • 2024-09-10 17:41:06 -0500
Engine • revision 059e4e6d8f
Tools • Dart 3.6.0 (build 3.6.0-216.1.beta) • DevTools 2.39.0

# Changes

- Updated squadron to v6 and moved web workers to wasm

## [2.3.0] - 26th of September, 2024

Flutter 3.24.3 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 2663184aa7 (2 weeks ago) • 2024-09-11 16:27:48 -0500
Engine • revision 36335019a8
Tools • Dart 3.5.3 • DevTools 2.37.3

# Changes

- Updated cardano_dart_types to 2.6.0

## [2.2.0] - 4th of September, 2024

Flutter 3.24.1 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 5874a72aa4 (5 days ago) • 2024-08-20 16:46:00 -0500
Engine • revision c9b9d5780d
Tools • Dart 3.5.1 • DevTools 2.37.2

# Changes

- Updated cardano_dart_types to 2.5.1

## [2.1.2] - 4th of September, 2024

Flutter 3.24.1 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 5874a72aa4 (5 days ago) • 2024-08-20 16:46:00 -0500
Engine • revision c9b9d5780d
Tools • Dart 3.5.1 • DevTools 2.37.2

# Changes

- Updated cardano_dart_types to 2.4.5

## [2.1.1] - 4th of September, 2024

Flutter 3.24.1 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 5874a72aa4 (5 days ago) • 2024-08-20 16:46:00 -0500
Engine • revision c9b9d5780d
Tools • Dart 3.5.1 • DevTools 2.37.2

# Changes

- Updated cardano_dart_types to 2.4.4

## [2.1.0] - 30th of August, 2024

Flutter 3.24.1 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 5874a72aa4 (5 days ago) • 2024-08-20 16:46:00 -0500
Engine • revision c9b9d5780d
Tools • Dart 3.5.1 • DevTools 2.37.2

# Breaking Changes

- Updated cardano_dart_types to 2.4.3 which has causes breaking changes

# Changes

- Sign TX with drep/committee keys if vote(s) and proposal(s) require it

## [2.0.0] - 26th of August, 2024

Flutter 3.24.1 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 5874a72aa4 (5 days ago) • 2024-08-20 16:46:00 -0500
Engine • revision c9b9d5780d
Tools • Dart 3.5.1 • DevTools 2.37.2

# Changes

- Bumped version to 2.x.y so it aligns with cardano types
- Updated cardano_dart_types to 2.1.0 which has some small breaking changes

## [1.9.7] - 25th of August, 2024

Flutter 3.24.1 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 5874a72aa4 (5 days ago) • 2024-08-20 16:46:00 -0500
Engine • revision c9b9d5780d
Tools • Dart 3.5.1 • DevTools 2.37.2

# Changes

- Updated to cardano_dart_types 2.0.1

## [1.9.6] - 12th of August, 2024

Flutter 3.24.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 80c2e84975 (10 days ago) • 2024-07-30 23:06:49 +0700
Engine • revision b8800d88be
Tools • Dart 3.5.0 • DevTools 2.37.2

# Changes

- Updated to cardano_dart_types 2.0.0

## [1.9.5] - 12th of August, 2024

Flutter 3.24.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 80c2e84975 (10 days ago) • 2024-07-30 23:06:49 +0700
Engine • revision b8800d88be
Tools • Dart 3.5.0 • DevTools 2.37.2

# Changes

- Added more functionality to CardanoPubAccount extension

## [1.9.4] - 10th of August, 2024

Flutter 3.24.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 80c2e84975 (10 days ago) • 2024-07-30 23:06:49 +0700
Engine • revision b8800d88be
Tools • Dart 3.5.0 • DevTools 2.37.2

# Fixes

- Fixed hexCredentialsDerivation background task

## [1.9.2 and 1.9.3] - 10th of August, 2024

Flutter 3.24.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 80c2e84975 (10 days ago) • 2024-07-30 23:06:49 +0700
Engine • revision b8800d88be
Tools • Dart 3.5.0 • DevTools 2.37.2

# Changes

- Changes in CardanoPubAccount extension methods

## [1.9.1] - 9th of August, 2024

Flutter 3.24.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 80c2e84975 (10 days ago) • 2024-07-30 23:06:49 +0700
Engine • revision b8800d88be
Tools • Dart 3.5.0 • DevTools 2.37.2

# Changes

- Corrected bug not allowing legacy addresses in required signers

## [1.9.0] - 9th of August, 2024

Flutter 3.24.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 80c2e84975 (10 days ago) • 2024-07-30 23:06:49 +0700
Engine • revision b8800d88be
Tools • Dart 3.5.0 • DevTools 2.37.2

# Changes

- Added deriveCredentialsHex for CardanoPubAccount extensions
- Updated to Flutter 3.24.0 and re-ran code gen

## [1.8.13] - 23rd of July, 2024

Flutter 3.24.0-0.2.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision 7c6b7e9ca4 (8 days ago) • 2024-07-30 14:26:44 +0700
Engine • revision 6e4deceb38
Tools • Dart 3.5.0 (build 3.5.0-323.2.beta) • DevTools 2.37.2

# Changes

- Changed to use hosted dependency for types

## [1.8.12] - 23rd of July, 2024

Flutter 3.24.0-0.2.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision 7c6b7e9ca4 (8 days ago) • 2024-07-30 14:26:44 +0700
Engine • revision 6e4deceb38
Tools • Dart 3.5.0 (build 3.5.0-323.2.beta) • DevTools 2.37.2

# Changes

- Updated cardano_dart_types dep
- Updated flutter/dart version and re-ran code gen

## [1.8.11] - 23rd of July, 2024

Flutter 3.23.0-0.1.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision 2feea7a407 (7 weeks ago) • 2024-06-06 10:19:10 +0700
Engine • revision bb10c54666
Tools • Dart 3.5.0 (build 3.5.0-180.3.beta) • DevTools 2.36.0

# Changes

- Pointing again to latest CBOR library version

## [1.8.10] - 18th of July, 2024

Dart SDK version: 3.5.0-180.3.beta (beta) (Wed Jun 5 15:06:15 2024 +0000) on "macos_arm64"

# BugFix

- Updated to cbor fork fixing JS web worker issues

## [1.8.9] - 18th of July, 2024

Dart SDK version: 3.5.0-180.3.beta (beta) (Wed Jun 5 15:06:15 2024 +0000) on "macos_arm64"

# BugFix

- Fixed wrong marshalers being used

## [1.8.8] - 10th of July, 2024

# BugFix

- Re-ran code-gen for web workers to fix cbor int parsing

## [1.8.7] - 10th of July, 2024

# BugFix

- Updated min cbor version to the one without Int parsing bug

## [1.8.6] - 8th of July, 2024

# BugFix

- Fixed squadron web workers type issue

## [1.8.3] - 27 / 06 / 2024

# Changes

- Updated cardano types version

## [1.8.2] - 27 / 06 / 2024

# Changes

- Re-generated web workers

# WIP - Conway era

- We don't currently attempt to find the keys to sign voting_procedure, proposal_procedure, treasury_value and treasury_donation

## [1.8.1] - 27 / 06 / 2024

# NOTE : Contains breaking changes

# Changes

- Updated cardano_dart_types to 1.8.1 to add conway era support
- Now signing using constitutional committee cold creds and drep id creds

# WIP - Conway era

- We don't currently attempt to find the keys to sign voting_procedure, proposal_procedure, treasury_value and treasury_donation

## [1.7.4] - 03 / 06 / 2024

# Changes

- Updated ShelleyTransactionOutput to give visibility for PreAlonzo and PostAlonzo (useful for switch statements)

## [1.7.3] - 21 / 05 / 2024

# Changes

- Added optional accountIndex for WalletFactory.fromMnemonics

# BugFix

- Fixed bug where HdWallet was expecting accountIndex to be passed as hardened

## [1.7.2] - 20 / 05 / 2024

# BugFix

- Fixed bug where CBOR -> TX -> CBOR was generating a different result when the keys in TxBody's CborMap were not ascending order

# Technical/Internal Changes

- Added some extensions to make the serialization of some tx data more readable

## [1.7.1] - 14 / 05 / 2024

# Changes

- Exported `Lazy`

# BugFix

- Fixed `Lazy` implementation (was throwing on nullable type resolving to null)

## [1.7.0] - 27 / 04 / 2024

# Changes

- Migrated to use dart3 switch instead of the deprecated `.map` generated by freezed
- Conway Part 1: Exposing dRep and constitutional committee keys

# Breaking Changes

- ShelleyAddress is now CardanoAddress

## [1.6.2] - 14 / 01 / 2024

# Changes

- Updated bip39 to a fork (original lib was not maintained and uses old deps)
- Made a small fix for json generated code to use anyMap (to work with web workers)
- Minor fix to squadron to automatically generate corect path for js worker file

## [1.6.1] - 10 / 12 / 2023

# New

- Added web support using web workers

# Changes

- Refactored all usage of compute/isolates to squadron to add web support

## [1.6.0] - 13 / 11 / 2023

# Breaking

- Renamed bech32Encode to addressBech32Encode
- Added generic bech32Encode taking hrp

# New

- Added return for bech32 credentials to ShelleyAddress

## [1.5.0] - 07 / 11 / 2023

- Added support for multi-tx signingd
- Added APIs for calculating the TX diff to show summary of what user agrees to sign

## [1.4.0] - 30 / 10 / 2023

- Changed ShelleyValue and ShelleyMultiAsset equality/hashcode to ignore order of assets

## [1.3.2] - 30 / 10 / 2023

- Added deserializeHex for ShelleyTransactionOutput

## [1.3.1] - 30 / 10 / 2023

- Updated deps + re-ran all code gen
- Fixed all linting issues

## [1.3.0] - 16 / 08 / 2023

- Changed cbor to local fork to add dart 3.1 / flutter 3.13.0 support

## [1.2.9] - 3 / 08 / 2023

- When signing TXs, check against credentials instead of bech32 addresses (this would allow matching with enterprise/franken addresses)

## [1.2.8] - 3 / 08 / 2023

- Fixed transaction output serialization (was causing invalid txs to be created)
- forJson encoding now encodes vkeys as 'addr_vk' bech32 instead of hex

## [1.2.7] - 20 / 07 / 2023

- Fixed witness sets addition (maintain cbor length type when adding two witness sets) ; Not doing this was causing TXs to be rejected by the network

## [1.2.6] - 19 / 07 / 2023

- Don't add empty witnesses when encoding the witness set (was causing the tx cbor to become too big to submit for the estimated fee)

## [1.2.5] - 19 / 07 / 2023

- Changed how witnesses are deserialized / serialized to maintain equality pre and post serialization

## [1.2.4] - 14 / 07 / 2023

- Allow native scripts to request signature.

## [1.2.3] - 14 / 07 / 2023

- Fixed bug where CBOR outputs were not serialized correctly if input was CborInt (lovelace only). This was leading to invalid tx signatures.

## [1.2.2] - 20 / 06 / 2023

- Started using ReusableIsolate and IsolatePool when signing TXs and deriving addresses to improve performance (tests now take half the time after this change)

## [1.2.1] - 18 / 06 / 2023

- Reverted to using cbor library instead of vespr-wallet/cbor fork (merged vespr changes to handle definite/indefinite lengths into main library)

## [1.2.0] - 17 / 06 / 2023

- Fixed UTxO parsing to use actual TransactionOuput instead of an incomplete version of the same thing

## [1.1.17] - 17 / 06 / 2023

- Fixed UTxO parsing when datum hash is present

## [1.1.16] - 15 / 06 / 2023

- Allowing full staking address in required signers

## [1.1.15] - 6 / 05 / 2023

- Updated so that address can also be legacy byron address (Ae2 and DdzFF)

## [1.1.14] - 23 / 04 / 2023

- Fixed hashing for CBORMetadata, causing tons of issues

## [1.1.13] - 15 / 04 / 2023

- Maintining length type (definite/indefinite) for plutus data when decoding and re-encoding
- Cross-reference for wallet's stake address when certificate is present before signing with stake address

## [1.1.12] - 23 / 02 / 2023

- Fixed equality check for CBORMetadata
- Made ShelleyTransactionBody CborEncodable
- Fixed serializing for cbor datum in outputs
- Enabled cbor to alternative when encoding/decoding
- Added tags to plutus bytes
- Fixed parsing/serializing for post alonzo output

## [1.1.11] - 17 / 02 / 2023

- Small cleanup for signing data
- Search for requested signers also in payment and change credentials

## [1.1.10] - 08 / 02 / 2023

- Small cleanup
- Added ShelleyAddress factory from payment and/or stake credentials

## [1.1.9] - 16 / 01 / 2023

- Made more classes CborEncodable
- Added extension to easily convert CborEncodable to json/hex
- Sign transaction now returns WitnessSet directly

## [1.1.8] - 16 / 01 / 2023

- Fixed rewards withdrawals cbor serialization

## [1.1.7] - 14 / 01 / 2023

- ShelleyAddress now exposes fields for credentials / stake credentials / stake bech32 address ( + added tests )
- Removed requirement of providing hrp when it can be derived
- Fixed native scripts parsing from cbor
- Take into consideration requested signers from transaction body

## [1.1.6] - 18 / 12 / 2022

- Fixed hex asset name for json encoding

## [1.1.5] - 28 / 11 / 2022

- Added option for mnemonics size on new wallets

## [1.1.4] - 26 / 11 / 2022

- Added wallet method to export account public key (can be used to derive all other public keys)
- Some style changes

## [1.1.3] - 04 / 11 / 2022

- Avoid altering body when deserializing from HEX

## [1.1.2] - 03 / 11 / 2022

- Added transformation to comput asset fingerprint

## [1.1.1] - 01 / 11 / 2022

- Added `+` and `-` operators for ShelleyValue
- Added tests for the new ShelleyValue operators

# [1.1.0] - 27 / 10 / 2022

- Added api to sign any data message (COSE standard)
- Minor api improvements for Wallet

## [1.0.8 - 1.0.9] - 19 / 10 / 2022

- Changed metadata to accept any cbor
- Moved more utils to transformations file
- Added clarifications for encoding on all strings
- Added bech32 hrp deriving from address bytes

## [1.0.7] - 16 / 10 / 2022

- Setup ShelleyValue parsing to/from hex
- Setup Transformations between hex<->utf8 and hex<->bech32

## [1.0.6] - 10 / 10 / 2022

- Cleaned up code and migrated most of it to freezed
- Added support for full parsing of cardano transactions CBOR (except for some pool specific actions)

## [1.0.5] - 24 / 09 / 2022

- Added bech32 string verification in cardano_sdk_utils
- Cleaned and validated all dependencies
- Removed logger

BREAKING CHANGES

- Renamed `addSignatures` to `copyWithAdditionalSignatures` for ShelleyTransaction to better reflect the action performed

## [1.0.4] - 06 / 09 / 2022

- Changed some readonly lists to be UnmodifiableListView to avoid confusion
- Added method to transaction to create a copy with extra signatures

## [1.0.3] - 05 / 09 / 2022

- Added support for rewards withdrawal
- Added unit tests for signing transactions

## [1.0.2] - 03 / 09 / 2022

- Inspected and updated dependencies
- Added certificate parsing for staking registration and delegation
