import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:cardano_flutter_sdk/src/utils/iterable_extensions.dart";
import "package:test/test.dart";

import "test_utils/fixtures.dart";

Value simpleDiff({
  required Iterable<Utxo> inputs,
  required Iterable<CardanoTransactionOutput> returnOutputs,
  required BigInt withdrawnRewards,
}) {
  return returnOutputs.reduceSafe(
        combine: (agg, e) => agg + e.value,
        initialValue: Value.v0(lovelace: BigInt.zero),
      ) -
      inputs.reduceSafe(
        combine: (agg, e) => agg + e.content.value,
        initialValue: Value.v0(lovelace: withdrawnRewards),
      );
}

void main() async {
  const mnemonic =
      "chief fiber betray curve tissue output feature jungle adapt smile brown crane accuse gospel plate unlock pull arrow hard february tape soccer patrol fetch";

  final wallet = await WalletFactory.fromMnemonic(NetworkId.mainnet, mnemonic.split(" "));
  final walletStakeCredential = Credential(CredType.ADDR_KEY_HASH, wallet.stakeAddress.credentialsBytes);
  final walletDRepCredential = Credential(CredType.ADDR_KEY_HASH, wallet.drepId.value.credentialsBytes);
  final walletConstitutionalCommitteeColdCredential = Credential(
    CredType.ADDR_KEY_HASH,
    wallet.constitutionalCommiteeCold.value.credentialsBytes,
  );
  final walletConstitutionalCommitteeHotCredential = Credential(
    CredType.ADDR_KEY_HASH,
    wallet.constitutionalCommiteeHot.value.credentialsBytes,
  );

  final stakePoolId = StakePoolId.fromBech32PoolId("pool1qnrqc7zpwye2r9wtkayh2dryvfqs7unp99f2039duljrsaffq5c");
  final stakePoolId2 = StakePoolId.fromBech32PoolId("pool1sjwdmeme5zs042jzwmdvxshhv27kepxke0mr02f2yzacsyd4wtu");

  final randomCredential = Credential(CredType.ADDR_KEY_HASH, Uint8List.fromList(List.generate(28, (index) => index)));

  final walletUtxos = _utxos.map(Utxo.deserializeHex).toList();
  final otherWalletsUtxos = _otherWalletsUtxos.map(Utxo.deserializeHex).toList();

  List<CardanoTransactionOutput> genThisWalletOutputs(Iterable<Value> values) => values
      .map(
        (e) => CardanoTransactionOutput.postAlonzo(
          addressBytes: Uint8List.fromList(wallet.firstAddress.bytes),
          value: e,
          outDatum: null,
          scriptRef: null,
          lengthType: CborLengthType.definite,
        ),
      )
      .toList();

  List<CardanoTransactionOutput> genOtherWalletOutputs(Iterable<Value> values) => values
      .map(
        (e) => CardanoTransactionOutput.postAlonzo(
          addressBytes:
              "addr1q8l7hny7x96fadvq8cukyqkcfca5xmkrvfrrkt7hp76v3qvssm7fz9ajmtd58ksljgkyvqu6gl23hlcfgv7um5v0rn8qtnzlfk"
                  .bech32Decode(),
          value: e,
          outDatum: null,
          scriptRef: null,
          lengthType: CborLengthType.definite,
        ),
      )
      .toList();

  (CardanoTransaction, Value, Set<String>) gentx({
    required Iterable<Utxo> thisWalletUtxoInputs,
    required Iterable<Utxo> otherWalletUtxoInputs,
    required Iterable<CardanoTransactionOutput> thisWalletOutputs,
    required Iterable<CardanoTransactionOutput> otherWalletOutputs,
    required BigInt thisWalletRewards, // rewards to withdraw
    required BigInt otherWalletRewards, // rewards to withdraw
    required Certificates certs,
    required VotingProcedures? votingProcedures,
    required List<ProposalProcedure> proposalProcedures,
  }) {
    final expectedDiff = simpleDiff(
      inputs: thisWalletUtxoInputs,
      returnOutputs: thisWalletOutputs,
      withdrawnRewards: thisWalletRewards,
    );

    final tx = cardanoTx(
      body: txBody(
        inputs: CardanoTransactionInputs(
          data: [
            ...otherWalletUtxoInputs.map((e) => e.identifier),
            ...thisWalletUtxoInputs.map((e) => e.identifier),
          ],
          cborTags: [],
        ),
        outputs: [...thisWalletOutputs, ...otherWalletOutputs],
        withdrawals: thisWalletRewards != BigInt.zero || otherWalletRewards != BigInt.zero
            ? [
                if (thisWalletRewards != BigInt.zero) Withdraw(wallet.stakeAddress.bech32Encoded, thisWalletRewards),
                if (otherWalletRewards != BigInt.zero)
                  Withdraw(
                    "stake1uxggdly3z7ed4k6rmg0eytzxqwdy04gmluy5x0wd6x83ensq3rs22",
                    otherWalletRewards,
                  ),
              ]
            : null,
        certs: certs,
        votingProcedures: votingProcedures,
        proposalProcedures: proposalProcedures,
      ),
    );

    final signAddrs = thisWalletUtxoInputs.map((e) => e.content.addressBytes.addressBase58Orbech32Encode()).toSet();

    return (tx, expectedDiff, signAddrs);
  }

  group("Prepare sign txs", () {
    test(
      "cbor 3.2.1 and older - issue deserializing negative 33-bit amounts (including sign)",
      () async {
        const txCbor =
            "84a600838258203fc3758817c53993e22c8b87c8e96b3d9d6665da8484bfedf7827e58836f65ac018258207845e"
            "eb7745ee67fd8c5792f2c5f0f279ceef789c21839309249080fce4fbef301825820ad98ec1770a5f6594f7d4dfe"
            "d929e34fbc6e008058a31c2bad1673cef367c18302018383583911a65ca58a4e9c755fa830173d2a5caed458ac0c"
            "73f97db7faae2e7e3b52563c5410bff6a0d43ccebb7c37e1f69f5eb260552521adff33b9c2821a003cfb6fa1581c"
            "3ef4ec008dffd3ef3a516a2609be258861086c493020bf5bd26f7a69a145474f4e41441a9e51c5355820ac2cce351"
            "9a620964e4b79bb7080d4fe8b2be60bacd41626bb67b5fdedf5593e82583901ed49d9adbd06592290b9a16032375d6b7"
            "9d4df760cad0d9bca9555fc4199f66b16ce9eb5849ed96473face025b2e9bcbdf1e352ad43629811a0606bb6d82583901ed49"
            "d9adbd06592290b9a16032375d6b79d4df760cad0d9bca9555fc4199f66b16ce9eb5849ed96473face025b2e9bcbdf1e352ad4"
            "362981821a00352370ab581c9293316c91ff5143e3bc60d78d44dfb87edff59d61b99cf4c938d908a1444142544e01581ca02684"
            "b9ece84a4341585d2ae813163356ba0ca950091d1935bdb905a1514855534b59484f53544c4552313530313301581ca097df4102d"
            "7efd9ca6c5a3e508df50b5a8014193ba153d563a26584a153000de1404d6f6f6e20426c6f6220233334353401581ca7904896a247"
            "d3aa09478e856769b82d1f2e060028b6bda5543b699fa24d4343434f4c4c4142303838383901581c4375746543726561747572657"
            "343686164694e61737361723030303101581cae1b29e34cb98ca4e02011a2b2c465261ae9805a1e256c41647a9520a14572424f4f"
            "4b01581cc0ee29a85b13209423b10447d3c2e6a50641a15c57770e27cb9d5073a14a57696e675269646572731a00cdbc90581cce5"
            "b9e0f8a88255b65f2e4d065c6e716e9fa9a8a86dfb86423dd1ac0a14444494e471a08faf037581ce3ff4ab89245ede61b3e2beab0"
            "443dbcc7ea8ca2c017478e4e8990e2a549746170707930373734014974617070793135343601497461707079323633370149746170"
            "707933363233014974617070793438363101581ce4214b7cce62ac6fbba385d164df48e157eae5863521b4b67ca71d86a158206aa2"
            "153e1ae896a95539c9d62f76cedcdabdcdf144e564b8955f609d660cf6a21a0211e121581ce74862a09d17a9cb03174a6bd5fa305b"
            "8684475c4c36021591c606e0a1474450303237383501581cececc92aeaaac1f5b665f567b01baec8bc2771804b4c21716a87a4e3a1"
            "4653504c4153481a1e5596b2021a00035f39031a07b1110f0758201feb00f18fbe772cc375aa495da0b08d837a719671e68da62f8e"
            "d658915d8fd10b5820a2237cf6577f99d0dd2635798bfef65b3aebdaa46ec5c03a18a74840e83f4742a1049fd8799fd8799fd8799f"
            "581ced49d9adbd06592290b9a16032375d6b79d4df760cad0d9bca9555fcffd8799fd8799fd8799f581c4199f66b16ce9eb5849ed9"
            "6473face025b2e9bcbdf1e352ad4362981ffffffffd8799fd8799f581ced49d9adbd06592290b9a16032375d6b79d4df760cad0d9b"
            "ca9555fcffd8799fd8799fd8799f581c4199f66b16ce9eb5849ed96473face025b2e9bcbdf1e352ad4362981ffffffffd87a80d879"
            "9fd8799f4040ff1a0031552cff1a001e76ef1a001e8480fffff5a11902a2a1636d736781754d696e737761703a204d61726b657420"
            "4f72646572";
        final cborUtxos = [
          "82825820dd27eef5c821516521ba3cb263ffa8e31682288914da69214e72e493d0c4758f0182583901ed49d9adbd06592290b9a16032375d6b79d4df760cad0d9bca9555fc4199f66b16ce9eb5849ed96473face025b2e9bcbdf1e352ad43629811a00c29727",
          "828258203fc3758817c53993e22c8b87c8e96b3d9d6665da8484bfedf7827e58836f65ac0182583901ed49d9adbd06592290b9a16032375d6b79d4df760cad0d9bca9555fc4199f66b16ce9eb5849ed96473face025b2e9bcbdf1e352ad4362981821a001e8480a1581c3ef4ec008dffd3ef3a516a2609be258861086c493020bf5bd26f7a69a145474f4e41441a9e51c535",
          "828258206abc0dbf22ac4459fe11bfc8735f9ef0ed5c223c67f5e7a4a21cc23446a57fd90182583901ed49d9adbd06592290b9a16032375d6b79d4df760cad0d9bca9555fc4199f66b16ce9eb5849ed96473face025b2e9bcbdf1e352ad43629811a05c7dd13",
          "828258207845eeb7745ee67fd8c5792f2c5f0f279ceef789c21839309249080fce4fbef30182583901ed49d9adbd06592290b9a16032375d6b79d4df760cad0d9bca9555fc4199f66b16ce9eb5849ed96473face025b2e9bcbdf1e352ad4362981821a00352370ab581c9293316c91ff5143e3bc60d78d44dfb87edff59d61b99cf4c938d908a1444142544e01581ca02684b9ece84a4341585d2ae813163356ba0ca950091d1935bdb905a1514855534b59484f53544c4552313530313301581ca097df4102d7efd9ca6c5a3e508df50b5a8014193ba153d563a26584a153000de1404d6f6f6e20426c6f6220233334353401581ca7904896a247d3aa09478e856769b82d1f2e060028b6bda5543b699fa24d4343434f4c4c4142303838383901581c4375746543726561747572657343686164694e61737361723030303101581cae1b29e34cb98ca4e02011a2b2c465261ae9805a1e256c41647a9520a14572424f4f4b01581cc0ee29a85b13209423b10447d3c2e6a50641a15c57770e27cb9d5073a14a57696e675269646572731a00cdbc90581cce5b9e0f8a88255b65f2e4d065c6e716e9fa9a8a86dfb86423dd1ac0a14444494e471a08faf037581ce3ff4ab89245ede61b3e2beab0443dbcc7ea8ca2c017478e4e8990e2a549746170707930373734014974617070793135343601497461707079323633370149746170707933363233014974617070793438363101581ce4214b7cce62ac6fbba385d164df48e157eae5863521b4b67ca71d86a158206aa2153e1ae896a95539c9d62f76cedcdabdcdf144e564b8955f609d660cf6a21a0211e121581ce74862a09d17a9cb03174a6bd5fa305b8684475c4c36021591c606e0a1474450303237383501581cececc92aeaaac1f5b665f567b01baec8bc2771804b4c21716a87a4e3a14653504c4153481a1e5596b2",
          "82825820ad98ec1770a5f6594f7d4dfed929e34fbc6e008058a31c2bad1673cef367c1830282583901ed49d9adbd06592290b9a16032375d6b79d4df760cad0d9bca9555fc4199f66b16ce9eb5849ed96473face025b2e9bcbdf1e352ad43629811a06289195",
          "828258203d0fcabc511e4d70a8ac3efbf3582cff33bbb07b9093cd47ff026b968a4617c80282583901ed49d9adbd06592290b9a16032375d6b79d4df760cad0d9bca9555fc4199f66b16ce9eb5849ed96473face025b2e9bcbdf1e352ad4362981821a083a9d50b1581c062b1da3d344c1e6208ef908b2d308201e7ff6bcfddf0f606249817fa14a4f52454d4f423430363301581c0a4352475d66381d5bc7257224725ea7a83a115ff81c257db07a683ca14749446a6565666f01581c0e14267a8020229adc0184dd25fa3174c3f7d6caadcb4425c70e7c04a24a756e7369673031353839014a756e736967303633383501581c1131301ad4b3cb7deaddbc8f03f77189082a5738c0167e1772233097a14f43617264616e6f426974733332333101581c15509d4cb60f066ca4c7e982d764d6ceb4324cb33776d1711da1beeea34e42616279416c69656e3035333635014e42616279416c69656e3037333338014e42616279416c69656e303930343601581c1f362a4df39f451401e44fee30f27eb39712d66aae375f539be94ed6a14c546865496c6961643238303401581c279c909f348e533da5808898f87f9a14bb2c3dfbbacccd631d927a3fa144534e454b1a0005ee9d581c373d98c16a7dd0945072cecc79c8c16da5f4625ac1530005f5861a1da145564553505201581c38ad9dc3aec6a2f38e220142b9aa6ade63ebe71f65e7cc2b7d8a8535a144434c41591a0015931b581c51a5e236c4de3af2b8020442e2a26f454fda3b04cb621c1294a0ef34a144424f4f4b181c581c530a197fe7c275f204c3396b3782fc738f4968f0c81dd2291cf07b8aa1581a434330303031303030303030303030303030303131343030333201581c5dac8536653edc12f6f5e1045d8164b9f59998d3bdc300fc92843489a1444e4d4b521a15752a00581c6ae8d99e095a01522591a76fd42ac6ed406bd2d58cd8e504e72daf18a14a537469676d613431343501581c8164b47180e8c2542403903a12d6a34f1db9e05108b9b93cd091d5bba15074696e792064696e6f7320233930343001581c821b636862f9160d68f875ac7d460b9642e462d499c00cae9b88ec25a14a5754503030373354303701581c851ab97a83e9d630cc007bf4a084b553a01aede72ef3f31a646478e0a14934467265356832383501581c92776616f1f32c65a173392e4410a3d8c39dcf6ef768c73af164779ca1454d795553441a0004a190",
          "82825820130daaeea53a7461f8bbe970d7302a9497032652172ecdca0b69c777c271daa20182583901ed49d9adbd06592290b9a16032375d6b79d4df760cad0d9bca9555fc4199f66b16ce9eb5849ed96473face025b2e9bcbdf1e352ad4362981821a00115cb0a1581c420000029ad9527271b1b1e3c27ee065c18df70a4a4cfc3093a41a44a14341584f18d8",
          "82825820130daaeea53a7461f8bbe970d7302a9497032652172ecdca0b69c777c271daa20282583901ed49d9adbd06592290b9a16032375d6b79d4df760cad0d9bca9555fc4199f66b16ce9eb5849ed96473face025b2e9bcbdf1e352ad43629811a057872f6",
        ];

        final signingBundle = await SigningUtils.prepareTxsForSigning(
          txs: [CardanoTransaction.deserializeFromHex(txCbor)],
          walletUtxos: cborUtxos.map(Utxo.deserializeHex).toList(),
          walletReceiveAddressBech32:
              "addr1q8k5nkddh5r9jg5shxskqv3ht44hn4xlwcx26rvme224tlzpn8mxk9kwn66cf8kev3el4nsztvhfhj7lrc6j44pk9xqsafxu96",
          drepCredential: "3ef4ec008dffd3ef3a516a2609be258861086c493020bf5bd26f7a69",
          constitutionalCommitteeColdCredential: "3ef4ec008dffd3ef3a516a2609be258861086c493020bf5bd26f7a69",
          constitutionalCommitteeHotCredential: "3ef4ec008dffd3ef3a516a2609be258861086c493020bf5bd26f7a69",
          networkId: NetworkId.mainnet,
        );

        expect(signingBundle.txsData.length, 1);
        expect(signingBundle.totalDiff, equals(signingBundle.txsData[0].txDiff.diff));

        expect(
          signingBundle.totalDiff,
          equals(
            Value.v1(
              lovelace: BigInt.parse("-4217512"),
              mA: [
                MultiAsset(
                  policyId: "3ef4ec008dffd3ef3a516a2609be258861086c493020bf5bd26f7a69",
                  assets: [Asset(hexName: "474f4e4144", value: BigInt.parse("-2656159029"))],
                ),
              ],
            ),
          ),
        );
      },
    );

    group(
      "Only wallet utxos",
      () {
        /// walletUtxos[0] = 1700000 lovelace +
        ///     247 8a1cfae21368b8bebbbed9800fec304e95cce39a2a57dc35e2e3ebaa.4d494c4b
        ///     @ addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx
        ///
        /// tx1 input = walletUtxos[0] + 1 lovelace (rewards)
        /// tx1 return = 142 lovelace
        ///
        /// diff: - 1699859 lovelace - 247 8a1cfae21368b8bebbbed9800fec304e95cce39a2a57dc35e2e3ebaa.4d494c4b
        final (tx1, calculatedExpectedTx1Diff, signAddrs1) = gentx(
          thisWalletUtxoInputs: [walletUtxos[0]],
          otherWalletUtxoInputs: [],
          thisWalletOutputs: genThisWalletOutputs([
            Value.v0(lovelace: BigInt.from(142)),
          ]),
          otherWalletOutputs: genOtherWalletOutputs([
            Value.v0(lovelace: BigInt.from(1922)),
          ]),
          thisWalletRewards: BigInt.one,
          otherWalletRewards: BigInt.from(100000000),
          certs: Certificates(
            certificates: [
              Certificate.stakeRegistration(
                coin: CborBigInt(BigInt.from(2)),
                stakeCredential: walletStakeCredential,
              ),
              Certificate.stakeDelegation(
                stakeCredential: walletStakeCredential,
                stakePoolId: stakePoolId,
              ),
              Certificate.registerDRep(
                dRepCredential: randomCredential,
                coin: CborInt(BigInt.one),
                anchor: null,
              ),
            ],
            cborTags: [],
            lengthType: CborLengthType.definite,
          ),
          proposalProcedures: [],
          votingProcedures: null,
        );

        final tx1Diff = Value.v1(
          lovelace: BigInt.from(-1699859),
          mA: [
            MultiAsset(
              policyId: "8a1cfae21368b8bebbbed9800fec304e95cce39a2a57dc35e2e3ebaa",
              assets: [Asset(hexName: "4d494c4b", value: BigInt.from(-247))],
            ),
          ],
        );

        test("single tx diff check", () async {
          final signingBundle = await SigningUtils.prepareTxsForSigning(
            txs: [tx1],
            walletUtxos: walletUtxos,
            walletReceiveAddressBech32: wallet.firstAddress.bech32Encoded,
            drepCredential: wallet.drepId.value.credentialsHex,
            constitutionalCommitteeColdCredential: wallet.constitutionalCommiteeCold.value.hexCredential,
            constitutionalCommitteeHotCredential: wallet.constitutionalCommiteeHot.value.hexCredential,
            networkId: wallet.networkId,
          );
          expect(signingBundle.txsData.length, equals(1));
          expect(
            signingBundle.txsData[0].signingAddressesRequired,
            {"addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx"},
          );
          expect(signingBundle.totalDiff, equals(tx1Diff));
          expect(signingBundle.totalDiff, equals(calculatedExpectedTx1Diff));
          expect(
            signingBundle.txsData[0].signingAddressesRequired,
            equals(signAddrs1),
          );
          expect(signingBundle.stakeDelegationPoolId, equals(stakePoolId.bech32PoolId));
          expect(signingBundle.txsData[0].txDiff.stakeDelegationPoolId, equals(stakePoolId.bech32PoolId));
          // required Drep? dRepDelegation,
          expect(signingBundle.dRepDelegation, isNull);
          expect(signingBundle.txsData[0].txDiff.dRepDelegation, isNull);
          // required DRepDiffInfo? dRepRegistration,
          expect(signingBundle.dRepRegistration, isNull);
          expect(signingBundle.txsData[0].txDiff.dRepRegistration, isNull);
          // required DRepDiffInfo? dRepUpdate,
          expect(signingBundle.dRepUpdate, isNull);
          expect(signingBundle.txsData[0].txDiff.dRepUpdate, isNull);
          // required Credential? authorizeConstitutionalCommitteeHot,
          expect(signingBundle.authorizeConstitutionalCommitteeHot, isNull);
          expect(signingBundle.txsData[0].txDiff.authorizeConstitutionalCommitteeHot, isNull);
          // required Credential? resignConstitutionalCommitteeCold,
          expect(signingBundle.resignConstitutionalCommitteeCold, isNull);
          expect(signingBundle.txsData[0].txDiff.resignConstitutionalCommitteeCold, isNull);
          // required List<VoteInfo> votes,
          expect(signingBundle.votes, isEmpty);
          expect(signingBundle.txsData[0].txDiff.votes, isEmpty);
          // required List<GovAction> proposals,
          expect(signingBundle.proposals, isEmpty);
          expect(signingBundle.txsData[0].txDiff.proposals, isEmpty);
          // required bool stakeDeregistration, // no more rewards + no more governance
          expect(signingBundle.stakeDeregistration, isFalse);
          expect(signingBundle.txsData[0].txDiff.stakeDeregistration, isFalse);
        });

        test(
          "multiple txs with chaining",
          () async {
            /// walletUtxos[2] = 2068800 lovelace +
            ///     834 e98165a25cd0320b25f22d686268e58e66f855b6d85974947ccd708d.414441464f58
            ///     333334 ea2d23f1fa631b414252824c153f2d6ba833506477a929770a4dd9c2.4d414442554c
            ///     1 f3bfa228ccaffa52bbe3f27ef3646516481cd15a80d1435083fe6b6b.4144415969656c64204e46542047656d73202d2032333031
            ///     1 f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e.4144415969656c642047656d202d2032393536
            ///     1 f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e.4144415969656c642047656d202d2034373736
            ///     111 ff97c85de383ebf0b047667ef23c697967719def58d380caf7f04b64.534f554c
            ///     @ addr1qyfs44hfdvrwxk30x0u28t8mezf4620jkecfkeqh4j2gusf8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qxz45yy
            /// walletUtxos[12] = 2000000 lovelace +
            ///     933711559515095 a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52.464c45534820544f4b454e
            ///     @ addr1qyfs44hfdvrwxk30x0u28t8mezf4620jkecfkeqh4j2gusf8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qxz45yy
            /// walletUtxos[33] = 1172320 lovelace +
            ///     1 44f8fabe04dc11bcf039128131b131b427db582f0e0be041a6b03691.534e454b5049435336333037
            ///     @ addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx
            ///
            /// tx2 input = walletUtxos[2] + walletUtxos[12] + walletUtxos[33] + 500 lovelace (rewards)
            ///    = 5241620 lovelace +
            ///     834 e98165a25cd0320b25f22d686268e58e66f855b6d85974947ccd708d.414441464f58
            ///     333334 ea2d23f1fa631b414252824c153f2d6ba833506477a929770a4dd9c2.4d414442554c
            ///     1 f3bfa228ccaffa52bbe3f27ef3646516481cd15a80d1435083fe6b6b.4144415969656c64204e46542047656d73202d2032333031
            ///     1 f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e.4144415969656c642047656d202d2032393536
            ///     1 f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e.4144415969656c642047656d202d2034373736
            ///     111 ff97c85de383ebf0b047667ef23c697967719def58d380caf7f04b64.534f554c
            ///     933711559515095 a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52.464c45534820544f4b454e
            ///     1 44f8fabe04dc11bcf039128131b131b427db582f0e0be041a6b03691.534e454b5049435336333037
            /// tx2 return = 118 lovelace
            ///     1 b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef.5350435b416c69656e5d202331313538
            ///     31718971375682855 a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52.464c45534820544f4b454e
            ///     200 9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77.53554e444145
            ///
            /// diff: - 5241502 lovelace
            ///     -834 e98165a25cd0320b25f22d686268e58e66f855b6d85974947ccd708d.414441464f58
            ///     -333334 ea2d23f1fa631b414252824c153f2d6ba833506477a929770a4dd9c2.4d414442554c
            ///     -1 f3bfa228ccaffa52bbe3f27ef3646516481cd15a80d1435083fe6b6b.4144415969656c64204e46542047656d73202d2032333031
            ///     -1 f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e.4144415969656c642047656d202d2032393536
            ///     -1 f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e.4144415969656c642047656d202d2034373736
            ///     -111 ff97c85de383ebf0b047667ef23c697967719def58d380caf7f04b64.534f554c
            ///     -1 44f8fabe04dc11bcf039128131b131b427db582f0e0be041a6b03691.534e454b5049435336333037
            ///     30785259816167760 a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52.464c45534820544f4b454e
            ///     1 b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef.5350435b416c69656e5d202331313538
            ///     200 9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77.53554e444145
            ///
            final tx2Diff = Value.v1(
              lovelace: BigInt.from(-5241502),
              mA: [
                MultiAsset(
                  policyId: "e98165a25cd0320b25f22d686268e58e66f855b6d85974947ccd708d",
                  assets: [Asset(hexName: "414441464f58", value: BigInt.from(-834))],
                ),
                MultiAsset(
                  policyId: "ea2d23f1fa631b414252824c153f2d6ba833506477a929770a4dd9c2",
                  assets: [Asset(hexName: "4d414442554c", value: BigInt.from(-333334))],
                ),
                MultiAsset(
                  policyId: "f3bfa228ccaffa52bbe3f27ef3646516481cd15a80d1435083fe6b6b",
                  assets: [
                    Asset(hexName: "4144415969656c64204e46542047656d73202d2032333031", value: BigInt.from(-1)),
                  ],
                ),
                MultiAsset(
                  policyId: "f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e",
                  assets: [
                    Asset(hexName: "4144415969656c642047656d202d2032393536", value: BigInt.from(-1)),
                    Asset(hexName: "4144415969656c642047656d202d2034373736", value: BigInt.from(-1)),
                  ],
                ),
                MultiAsset(
                  policyId: "ff97c85de383ebf0b047667ef23c697967719def58d380caf7f04b64",
                  assets: [Asset(hexName: "534f554c", value: BigInt.from(-111))],
                ),
                MultiAsset(
                  policyId: "44f8fabe04dc11bcf039128131b131b427db582f0e0be041a6b03691",
                  assets: [Asset(hexName: "534e454b5049435336333037", value: BigInt.from(-1))],
                ),
                MultiAsset(
                  policyId: "a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52",
                  assets: [Asset(hexName: "464c45534820544f4b454e", value: BigInt.parse("30785259816167760"))],
                ),
                MultiAsset(
                  policyId: "b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef",
                  assets: [Asset(hexName: "5350435b416c69656e5d202331313538", value: BigInt.from(1))],
                ),
                MultiAsset(
                  policyId: "9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77",
                  assets: [Asset(hexName: "53554e444145", value: BigInt.from(200))],
                ),
              ],
            );
            final (tx2, _, _) = gentx(
              thisWalletRewards: BigInt.from(500),
              otherWalletRewards: BigInt.zero,
              thisWalletUtxoInputs: [
                walletUtxos[2],
                walletUtxos[12],
                walletUtxos[33],
              ],
              otherWalletUtxoInputs: [],
              thisWalletOutputs: genThisWalletOutputs([
                Value.v0(lovelace: BigInt.from(112)),
                Value.v1(
                  lovelace: BigInt.from(1),
                  mA: [
                    MultiAsset(
                      policyId: "b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef",
                      assets: [
                        Asset(hexName: "5350435b416c69656e5d202331313538", value: BigInt.from(1)),
                      ],
                    ),
                    MultiAsset(
                      policyId: "a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52",
                      assets: [
                        Asset(hexName: "464c45534820544f4b454e", value: BigInt.parse("31718971375682855")),
                      ],
                    ),
                    MultiAsset(
                      policyId: "9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77",
                      assets: [
                        Asset(hexName: "53554e444145", value: BigInt.parse("200")),
                      ],
                    ),
                  ],
                ),
                Value.v0(lovelace: BigInt.from(5)),
              ]),
              otherWalletOutputs: genOtherWalletOutputs([
                Value.v0(lovelace: BigInt.from(192)),
                Value.v0(lovelace: BigInt.from(192)),
              ]),
              certs: Certificates(
                certificates: [
                  Certificate.stakeVoteRegistrationDelegation(
                    stakeCredential: walletStakeCredential,
                    stakePoolId: stakePoolId2,
                    dRep: Drep.abstain(lengthType: CborLengthType.definite),
                    coin: CborInt(BigInt.from(1)),
                  ),
                  Certificate.registerDRep(
                    dRepCredential: walletDRepCredential,
                    coin: CborInt(BigInt.from(1)),
                    anchor: null,
                  ),
                  Certificate.updateDRep(
                    dRepCredential: walletDRepCredential,
                    anchor: null,
                  ),
                  Certificate.authorizeCommitteeHot(
                    committeeColdCredential: walletConstitutionalCommitteeColdCredential,
                    committeeHotCredential: randomCredential,
                  ),
                  Certificate.resignCommitteeCold(
                    committeeColdCredential: walletConstitutionalCommitteeColdCredential,
                    anchor: null,
                  ),
                  Certificate.stakeDeRegistrationLegacy(
                    stakeCredential: walletStakeCredential,
                  ),
                ],
                cborTags: [],
                lengthType: CborLengthType.definite,
              ),
              proposalProcedures: [
                ProposalProcedure(
                  deposit: CborInt(BigInt.one),
                  anchor: Anchor(
                    anchorUrl: "",
                    anchorDataHash: Uint8List(0),
                  ),
                  rewardAccount: [1, 1].toUint8List(),
                  govAction: const GovAction.infoAction(),
                ),
                ProposalProcedure(
                  deposit: CborInt(BigInt.one),
                  anchor: Anchor(
                    anchorUrl: "",
                    anchorDataHash: Uint8List(0),
                  ),
                  rewardAccount: [1, 3, 2, 1].toUint8List(),
                  govAction: GovAction.noConfidence(
                    prevGovActionId: GovActionId(
                      transactionId: "940293a1a623a4e70f52575b9a7826faf90e12692eb5432cc859f0de632d4f4a",
                      govActionIndex: 0,
                    ),
                  ),
                ),
              ],
              votingProcedures: VotingProcedures(
                voting: {
                  Voter(
                    vKeyHash: walletConstitutionalCommitteeHotCredential.vKeyHash,
                    voterType: VoterType.CONSTITUTIONAL_COMMITTEE_HOT_KEY_HASH,
                  ): {
                    GovActionId(
                      transactionId: "940293a1a623a4e70f52575b9a7826faf90e12692eb5432cc859f0de632d4f4a",
                      govActionIndex: 0,
                    ): const VotingProcedure(
                      anchor: null,
                      vote: Vote.yes,
                    ),
                    GovActionId(
                      transactionId: "940293a1a623a4e70f52575b9a7826faf90e12692eb5432cc859f0de632d4f4b",
                      govActionIndex: 1,
                    ): const VotingProcedure(
                      anchor: null,
                      vote: Vote.abstain,
                    ),
                  },
                  Voter(
                    vKeyHash: walletDRepCredential.vKeyHash,
                    voterType: VoterType.DREP_KEY_HASH,
                  ): {
                    GovActionId(
                      transactionId: "940293a1a623a4e70f52575b9a7826faf90e12692eb5432cc859f0de632d4f4c",
                      govActionIndex: 0,
                    ): const VotingProcedure(
                      anchor: null,
                      vote: Vote.no,
                    ),
                  },
                },
              ),
            );

            final tx1Utxo = Utxo(
              identifier: CardanoTransactionInput(transactionHash: tx1.body.blake2bHash256Hex(), index: 0),
              content: tx1.body.outputs[0], // 142 lovelace
            );

            final tx2Utxo1 = Utxo(
              identifier: CardanoTransactionInput(transactionHash: tx2.body.blake2bHash256Hex(), index: 0),
              content: tx2.body.outputs[0], // 112 lovelace
            );
            final tx2Utxo2 = Utxo(
              identifier: CardanoTransactionInput(transactionHash: tx2.body.blake2bHash256Hex(), index: 1),
              content: tx2.body.outputs[1], // 1 lovelace and some assets
            );

            /// tx1Utxo = 142 lovelace
            ///     @ addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx
            /// tx2Utxo1 = 112 lovelace
            ///     @ addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx
            /// tx2Utxo2 = 1 lovelace +
            ///     1 b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef.5350435b416c69656e5d202331313538
            ///     31718971375682855 a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52.464c45534820544f4b454e
            ///     200 9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77.53554e444145
            ///     @ addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx
            /// walletUtxos[5] = 1236970 lovelace +
            ///     1 d5ad382393561e45b7e580415b99562eea6cd120ce6a542a4b8e1e95.426c657373696e67206f66207468652042756c6c202334303632
            ///     @ addr1qxstkcvzlnwlj4pgq4zuqpjyx8pwce780utg7r25gmtammf8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qc4ejug
            ///
            /// tx3 input = tx1Utxo + tx2Utxo1 + tx2Utxo2 + walletUtxos[5] + 0 lovelace (rewards)
            ///    = 1237225 lovelace +
            ///     1 b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef.5350435b416c69656e5d202331313538
            ///     31718971375682855 a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52.464c45534820544f4b454e
            ///     200 9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77.53554e444145
            ///     1 d5ad382393561e45b7e580415b99562eea6cd120ce6a542a4b8e1e95.426c657373696e67206f66207468652042756c6c202334303632
            /// tx3 return = 19 lovelace
            ///     200 9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77.53554e444145
            ///     2 d5ad382393561e45b7e580415b99562eea6cd120ce6a542a4b8e1e95.426c657373696e67206f66207468652042756c6c202334303632
            ///
            /// diff: - 1237206 lovelace
            ///     -1 b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef.5350435b416c69656e5d202331313538
            ///     -31718971375682855 a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52.464c45534820544f4b454e
            ///     1 d5ad382393561e45b7e580415b99562eea6cd120ce6a542a4b8e1e95.426c657373696e67206f66207468652042756c6c202334303632
            ///
            final tx3Diff = Value.v1(
              lovelace: BigInt.from(-1237206),
              mA: [
                MultiAsset(
                  policyId: "b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef",
                  assets: [Asset(hexName: "5350435b416c69656e5d202331313538", value: BigInt.from(-1))],
                ),
                MultiAsset(
                  policyId: "a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52",
                  assets: [Asset(hexName: "464c45534820544f4b454e", value: BigInt.parse("-31718971375682855"))],
                ),
                MultiAsset(
                  policyId: "d5ad382393561e45b7e580415b99562eea6cd120ce6a542a4b8e1e95",
                  assets: [
                    Asset(hexName: "426c657373696e67206f66207468652042756c6c202334303632", value: BigInt.from(1)),
                  ],
                ),
              ],
            );
            final (tx3, _, _) = gentx(
              thisWalletRewards: BigInt.zero,
              otherWalletRewards: BigInt.zero,
              thisWalletUtxoInputs: [
                tx1Utxo,
                tx2Utxo1,
                tx2Utxo2,
                walletUtxos[5],
              ],
              otherWalletUtxoInputs: [],
              thisWalletOutputs: genThisWalletOutputs([
                Value.v1(
                  lovelace: BigInt.from(14),
                  mA: [
                    MultiAsset(
                      policyId: "9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77",
                      assets: [Asset(hexName: "53554e444145", value: BigInt.from(200))],
                    ),
                    MultiAsset(
                      policyId: "d5ad382393561e45b7e580415b99562eea6cd120ce6a542a4b8e1e95",
                      assets: [
                        Asset(hexName: "426c657373696e67206f66207468652042756c6c202334303632", value: BigInt.from(2)),
                      ],
                    ),
                  ],
                ),
                Value.v0(lovelace: BigInt.from(5)),
              ]),
              otherWalletOutputs: genOtherWalletOutputs([
                Value.v0(lovelace: BigInt.from(1922)),
                Value.v0(lovelace: BigInt.from(2)),
              ]),
              certs: const Certificates(certificates: [], cborTags: [], lengthType: CborLengthType.definite),
              proposalProcedures: [],
              votingProcedures: null,
            );

            /// Total DIFF
            /// tx1 diff: - 1699859 lovelace
            ///      -247 8a1cfae21368b8bebbbed9800fec304e95cce39a2a57dc35e2e3ebaa.4d494c4b
            /// tx2 diff: - 5241502 lovelace
            ///     -834 e98165a25cd0320b25f22d686268e58e66f855b6d85974947ccd708d.414441464f58
            ///     -333334 ea2d23f1fa631b414252824c153f2d6ba833506477a929770a4dd9c2.4d414442554c
            ///     -1 f3bfa228ccaffa52bbe3f27ef3646516481cd15a80d1435083fe6b6b.4144415969656c64204e46542047656d73202d2032333031
            ///     -1 f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e.4144415969656c642047656d202d2032393536
            ///     -1 f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e.4144415969656c642047656d202d2034373736
            ///     -111 ff97c85de383ebf0b047667ef23c697967719def58d380caf7f04b64.534f554c
            ///     -1 44f8fabe04dc11bcf039128131b131b427db582f0e0be041a6b03691.534e454b5049435336333037
            ///      30785259816167760 a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52.464c45534820544f4b454e
            ///     1 b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef.5350435b416c69656e5d202331313538
            ///     200 9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77.53554e444145
            /// tx3 diff: - 1237206 lovelace
            ///     -1 b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef.5350435b416c69656e5d202331313538
            ///     -31718971375682855 a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52.464c45534820544f4b454e
            ///     1 d5ad382393561e45b7e580415b99562eea6cd120ce6a542a4b8e1e95.426c657373696e67206f66207468652042756c6c202334303632
            /// total diff: - 8178567 lovelace
            ///     -247 8a1cfae21368b8bebbbed9800fec304e95cce39a2a57dc35e2e3ebaa.4d494c4b
            ///     -834 e98165a25cd0320b25f22d686268e58e66f855b6d85974947ccd708d.414441464f58
            ///     -333334 ea2d23f1fa631b414252824c153f2d6ba833506477a929770a4dd9c2.4d414442554c
            ///     -1 f3bfa228ccaffa52bbe3f27ef3646516481cd15a80d1435083fe6b6b.4144415969656c64204e46542047656d73202d2032333031
            ///     -1 f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e.4144415969656c642047656d202d2032393536
            ///     -1 f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e.4144415969656c642047656d202d2034373736
            ///     -111 ff97c85de383ebf0b047667ef23c697967719def58d380caf7f04b64.534f554c
            ///     -1 44f8fabe04dc11bcf039128131b131b427db582f0e0be041a6b03691.534e454b5049435336333037
            ///     -933711559515095 a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52.464c45534820544f4b454e
            ///     200 9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77.53554e444145
            ///     1 d5ad382393561e45b7e580415b99562eea6cd120ce6a542a4b8e1e95.426c657373696e67206f66207468652042756c6c202334303632
            final totalDiff = Value.v1(
              lovelace: BigInt.from(-8178567),
              mA: [
                MultiAsset(
                  policyId: "8a1cfae21368b8bebbbed9800fec304e95cce39a2a57dc35e2e3ebaa",
                  assets: [Asset(hexName: "4d494c4b", value: BigInt.from(-247))],
                ),
                MultiAsset(
                  policyId: "a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52",
                  assets: [Asset(hexName: "464c45534820544f4b454e", value: BigInt.parse("-933711559515095"))],
                ),
                MultiAsset(
                  policyId: "9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77",
                  assets: [Asset(hexName: "53554e444145", value: BigInt.parse("200"))],
                ),
                MultiAsset(
                  policyId: "e98165a25cd0320b25f22d686268e58e66f855b6d85974947ccd708d",
                  assets: [Asset(hexName: "414441464f58", value: BigInt.parse("-834"))],
                ),
                MultiAsset(
                  policyId: "ea2d23f1fa631b414252824c153f2d6ba833506477a929770a4dd9c2",
                  assets: [Asset(hexName: "4d414442554c", value: BigInt.parse("-333334"))],
                ),
                MultiAsset(
                  policyId: "f3bfa228ccaffa52bbe3f27ef3646516481cd15a80d1435083fe6b6b",
                  assets: [
                    Asset(hexName: "4144415969656c64204e46542047656d73202d2032333031", value: BigInt.parse("-1")),
                  ],
                ),
                MultiAsset(
                  policyId: "f7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509e",
                  assets: [
                    Asset(hexName: "4144415969656c642047656d202d2032393536", value: BigInt.from(-1)),
                    Asset(hexName: "4144415969656c642047656d202d2034373736", value: BigInt.from(-1)),
                  ],
                ),
                MultiAsset(
                  policyId: "ff97c85de383ebf0b047667ef23c697967719def58d380caf7f04b64",
                  assets: [Asset(hexName: "534f554c", value: BigInt.parse("-111"))],
                ),
                MultiAsset(
                  policyId: "44f8fabe04dc11bcf039128131b131b427db582f0e0be041a6b03691",
                  assets: [Asset(hexName: "534e454b5049435336333037", value: BigInt.parse("-1"))],
                ),
                MultiAsset(
                  policyId: "d5ad382393561e45b7e580415b99562eea6cd120ce6a542a4b8e1e95",
                  assets: [
                    Asset(hexName: "426c657373696e67206f66207468652042756c6c202334303632", value: BigInt.parse("1")),
                  ],
                ),
              ],
            );

            final signingBundle = await SigningUtils.prepareTxsForSigning(
              txs: [tx1, tx2, tx3],
              walletUtxos: walletUtxos,
              walletReceiveAddressBech32: wallet.firstAddress.bech32Encoded,
              drepCredential: wallet.drepId.value.credentialsHex,
              constitutionalCommitteeColdCredential: wallet.constitutionalCommiteeCold.value.hexCredential,
              constitutionalCommitteeHotCredential: wallet.constitutionalCommiteeHot.value.hexCredential,
              networkId: wallet.networkId,
            );

            // expect(
            //     signingBundle.totalDiff,
            //     equals(
            //       Value.v1(
            //         lovelace: BigInt.from(-1699859),
            //         mA: [
            //           MultiAsset(
            //             policyId: "8a1cfae21368b8bebbbed9800fec304e95cce39a2a57dc35e2e3ebaa",
            //             assets: [Asset(hexName: "4d494c4b", value: BigInt.from(-247))],
            //           ),
            //         ],
            //       ),
            //     ));
            expect(signingBundle.txsData.length, equals(3));
            expect(signingBundle.txsData[0].txDiff.diff, equals(tx1Diff));
            expect(
              signingBundle.txsData[0].signingAddressesRequired,
              equals(
                {
                  "addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx",
                },
              ),
            );
            expect(
              signingBundle.txsData[1].signingAddressesRequired,
              {
                "addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx",
                "addr1qyfs44hfdvrwxk30x0u28t8mezf4620jkecfkeqh4j2gusf8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qxz45yy",
              },
            );
            expect(signingBundle.txsData[1].txDiff.diff, equals(tx2Diff));
            expect(
              signingBundle.txsData[2].signingAddressesRequired,
              {
                "addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx",
                "addr1qxstkcvzlnwlj4pgq4zuqpjyx8pwce780utg7r25gmtammf8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qc4ejug",
              },
            );
            expect(signingBundle.txsData[2].txDiff.diff, equals(tx3Diff));

            expect(signingBundle.totalDiff, equals(totalDiff));
            expect(signingBundle.totalDiff, equals(tx1Diff + tx2Diff + tx3Diff));
            // expect(
            //   signingBundle.txsData[0].signingAddressesRequired,
            //   equals(signAddrs1),
            // );
            // expect(
            //   signingBundle.txsData[1].signingAddressesRequired,
            //   equals(signAddrs2),
            // );
            // expect(
            //   signingBundle.txsData[2].signingAddressesRequired,
            //   equals(signAddrs3),
            // );

            expect(signingBundle.stakeDelegationPoolId, equals(stakePoolId2.bech32PoolId));
            expect(signingBundle.txsData[0].txDiff.stakeDelegationPoolId, equals(stakePoolId.bech32PoolId));
            expect(signingBundle.txsData[1].txDiff.stakeDelegationPoolId, equals(stakePoolId2.bech32PoolId));
            // required Drep? dRepDelegation,
            expect(
              signingBundle.dRepDelegation,
              equals(Drep.abstain(lengthType: CborLengthType.definite)),
            );
            expect(
              signingBundle.txsData[0].txDiff.dRepDelegation,
              isNull,
            );
            expect(
              signingBundle.txsData[1].txDiff.dRepDelegation,
              equals(Drep.abstain(lengthType: CborLengthType.definite)),
            );
            // required DRepDiffInfo? dRepRegistration,
            expect(
              signingBundle.dRepRegistration,
              equals(DRepDiffInfo(dRepId: wallet.drepId.value.dRepIdLegacyBech32, metadataUrl: null)),
            );
            expect(
              signingBundle.txsData[0].txDiff.dRepRegistration,
              isNull,
            );
            expect(
              signingBundle.txsData[1].txDiff.dRepRegistration,
              equals(DRepDiffInfo(dRepId: wallet.drepId.value.dRepIdLegacyBech32, metadataUrl: null)),
            );
            // required DRepDiffInfo? dRepUpdate,
            expect(
              signingBundle.dRepUpdate,
              equals(DRepDiffInfo(dRepId: wallet.drepId.value.dRepIdLegacyBech32, metadataUrl: null)),
            );
            expect(signingBundle.txsData[0].txDiff.dRepUpdate, isNull);
            expect(
              signingBundle.txsData[1].txDiff.dRepUpdate,
              equals(DRepDiffInfo(dRepId: wallet.drepId.value.dRepIdLegacyBech32, metadataUrl: null)),
            );
            // required Credential? authorizeConstitutionalCommitteeHot,
            expect(
              signingBundle.authorizeConstitutionalCommitteeHot,
              randomCredential,
            );
            expect(
              signingBundle.txsData[0].txDiff.authorizeConstitutionalCommitteeHot,
              isNull,
            );
            expect(
              signingBundle.txsData[1].txDiff.authorizeConstitutionalCommitteeHot,
              randomCredential,
            );
            // required Credential? resignConstitutionalCommitteeCold,
            expect(
              signingBundle.resignConstitutionalCommitteeCold,
              walletConstitutionalCommitteeColdCredential,
            );
            expect(
              signingBundle.txsData[0].txDiff.resignConstitutionalCommitteeCold,
              isNull,
            );
            expect(
              signingBundle.txsData[1].txDiff.resignConstitutionalCommitteeCold,
              walletConstitutionalCommitteeColdCredential,
            );
            // required List<VoteInfo> votes,
            final expectedVotes = [
              VoteInfo(
                action: GovActionId(
                  transactionId: "940293a1a623a4e70f52575b9a7826faf90e12692eb5432cc859f0de632d4f4a",
                  govActionIndex: 0,
                ),
                vote: Vote.yes,
              ),
              VoteInfo(
                action: GovActionId(
                  transactionId: "940293a1a623a4e70f52575b9a7826faf90e12692eb5432cc859f0de632d4f4b",
                  govActionIndex: 1,
                ),
                vote: Vote.abstain,
              ),
              VoteInfo(
                action: GovActionId(
                  transactionId: "940293a1a623a4e70f52575b9a7826faf90e12692eb5432cc859f0de632d4f4c",
                  govActionIndex: 0,
                ),
                vote: Vote.no,
              ),
            ];
            expect(
              signingBundle.votes,
              equals(expectedVotes),
            );
            expect(
              signingBundle.txsData[0].txDiff.votes,
              isEmpty,
            );
            expect(
              signingBundle.txsData[1].txDiff.votes,
              equals(expectedVotes),
            );
            // required List<GovAction> proposals,
            final expectedProposals = [
              ProposalDiffInfo(
                proposal: const GovAction.infoAction(),
                proposalId: GovActionId(
                  // transactionId is tx hash of the tx that contains the proposal
                  transactionId: "9c46a156f44cfef92de51d6eec89fcb21162207d54c9bc92d5ef94eaa45ce4df",
                  govActionIndex: 0,
                ),
              ),
              ProposalDiffInfo(
                proposal: GovAction.noConfidence(
                  prevGovActionId: GovActionId(
                    transactionId: "940293a1a623a4e70f52575b9a7826faf90e12692eb5432cc859f0de632d4f4a",
                    govActionIndex: 0,
                  ),
                ),
                proposalId: GovActionId(
                  // transactionId is tx hash of the tx that contains the proposal
                  transactionId: "9c46a156f44cfef92de51d6eec89fcb21162207d54c9bc92d5ef94eaa45ce4df",
                  govActionIndex: 1,
                ),
              ),
            ];
            expect(
              signingBundle.proposals,
              equals(expectedProposals),
            );
            expect(
              signingBundle.txsData[0].txDiff.proposals,
              isEmpty,
            );
            expect(
              signingBundle.txsData[1].txDiff.proposals,
              equals(expectedProposals),
            );
            // required bool stakeDeregistration, // no more rewards + no more governance
            expect(signingBundle.stakeDeregistration, isTrue);
            expect(signingBundle.txsData[0].txDiff.stakeDeregistration, isFalse);
            expect(signingBundle.txsData[1].txDiff.stakeDeregistration, isTrue);
          },
          timeout: const Timeout(Duration(minutes: 10)),
        );

        test("multiple txs with no chaining", () async {
          final (tx2, expectedTx2Diff, signAddrs2) = gentx(
            thisWalletRewards: BigInt.from(500),
            otherWalletRewards: BigInt.zero,
            thisWalletUtxoInputs: [
              walletUtxos[1],
              walletUtxos[12],
              walletUtxos[33],
              walletUtxos[34],
            ],
            otherWalletUtxoInputs: [],
            thisWalletOutputs: genThisWalletOutputs([
              Value.v0(lovelace: BigInt.from(112)),
              Value.v1(
                lovelace: BigInt.from(1),
                mA: [
                  MultiAsset(
                    policyId: "b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef",
                    assets: [
                      Asset(hexName: "5350435b416c69656e5d202331313538", value: BigInt.from(1)),
                    ],
                  ),
                  MultiAsset(
                    policyId: "a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52",
                    assets: [
                      Asset(hexName: "464c45534820544f4b454e", value: BigInt.parse("31718971375682855")),
                    ],
                  ),
                  MultiAsset(
                    policyId: "9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77",
                    assets: [
                      Asset(hexName: "53554e444145", value: BigInt.parse("200")),
                    ],
                  ),
                ],
              ),
              Value.v0(lovelace: BigInt.from(5)),
            ]),
            otherWalletOutputs: genOtherWalletOutputs([
              Value.v0(lovelace: BigInt.from(192)),
              Value.v0(lovelace: BigInt.from(192)),
            ]),
            certs: const Certificates(certificates: [], cborTags: [], lengthType: CborLengthType.definite),
            proposalProcedures: [],
            votingProcedures: null,
          );

          final (tx3, expectedTx3Diff, signAddrs3) = gentx(
            thisWalletRewards: BigInt.zero,
            otherWalletRewards: BigInt.zero,
            thisWalletUtxoInputs: [
              walletUtxos[4],
              walletUtxos[5],
            ],
            otherWalletUtxoInputs: [],
            thisWalletOutputs: genThisWalletOutputs([
              Value.v0(lovelace: BigInt.from(14)),
              Value.v0(lovelace: BigInt.from(5)),
            ]),
            otherWalletOutputs: genOtherWalletOutputs([
              Value.v0(lovelace: BigInt.from(1922)),
              Value.v0(lovelace: BigInt.from(2)),
            ]),
            certs: const Certificates(certificates: [], cborTags: [], lengthType: CborLengthType.definite),
            proposalProcedures: [],
            votingProcedures: null,
          );

          final expectedTotalDiff = calculatedExpectedTx1Diff + expectedTx2Diff + expectedTx3Diff;
          final signingBundle = await SigningUtils.prepareTxsForSigning(
            txs: [tx1, tx2, tx3],
            walletUtxos: walletUtxos,
            walletReceiveAddressBech32: wallet.firstAddress.bech32Encoded,
            drepCredential: wallet.drepId.value.credentialsHex,
            constitutionalCommitteeColdCredential: wallet.constitutionalCommiteeCold.value.hexCredential,
            constitutionalCommitteeHotCredential: wallet.constitutionalCommiteeHot.value.hexCredential,
            networkId: wallet.networkId,
          );

          expect(signingBundle.totalDiff, equals(expectedTotalDiff));
          expect(signingBundle.txsData.length, equals(3));
          expect(
            signingBundle.txsData[0].signingAddressesRequired,
            equals(signAddrs1),
          );
          expect(
            signingBundle.txsData[1].signingAddressesRequired,
            equals(signAddrs2),
          );
          expect(
            signingBundle.txsData[2].signingAddressesRequired,
            equals(signAddrs3),
          );
        });
      },
    );
    group(
      "Only external utxos",
      () {
        final (tx1, expectedTx1Diff, _) = gentx(
          thisWalletRewards: BigInt.zero,
          otherWalletRewards: BigInt.zero,
          thisWalletUtxoInputs: [],
          otherWalletUtxoInputs: [otherWalletsUtxos[0]],
          thisWalletOutputs: genThisWalletOutputs([
            Value.v0(lovelace: BigInt.from(142)),
          ]),
          otherWalletOutputs: genOtherWalletOutputs([
            Value.v0(lovelace: BigInt.from(1922)),
          ]),
          certs: const Certificates(certificates: [], cborTags: [], lengthType: CborLengthType.definite),
          proposalProcedures: [],
          votingProcedures: null,
        );

        test("single tx diff check", () async {
          final signingBundle = await SigningUtils.prepareTxsForSigning(
            txs: [tx1],
            walletUtxos: walletUtxos,
            walletReceiveAddressBech32: wallet.firstAddress.bech32Encoded,
            drepCredential: wallet.drepId.value.credentialsHex,
            constitutionalCommitteeColdCredential: wallet.constitutionalCommiteeCold.value.hexCredential,
            constitutionalCommitteeHotCredential: wallet.constitutionalCommiteeHot.value.hexCredential,
            networkId: wallet.networkId,
          );
          expect(signingBundle.totalDiff, equals(expectedTx1Diff));
          expect(signingBundle.txsData.length, equals(1));
          expect(
            signingBundle.txsData[0].signingAddressesRequired,
            equals([]),
          );
        });

        test("multiple txs with no chaining", () async {
          final (tx2, expectedTx2Diff, _) = gentx(
            thisWalletRewards: BigInt.zero,
            otherWalletRewards: BigInt.zero,
            thisWalletUtxoInputs: [],
            otherWalletUtxoInputs: [
              otherWalletsUtxos[0],
              otherWalletsUtxos[1],
            ],
            thisWalletOutputs: genThisWalletOutputs([
              Value.v0(lovelace: BigInt.from(112)),
              Value.v1(
                lovelace: BigInt.from(1),
                mA: [
                  MultiAsset(
                    policyId: "b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef",
                    assets: [
                      Asset(hexName: "5350435b416c69656e5d202331313538", value: BigInt.from(1)),
                    ],
                  ),
                  MultiAsset(
                    policyId: "a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52",
                    assets: [
                      Asset(hexName: "464c45534820544f4b454e", value: BigInt.parse("31718971375682855")),
                    ],
                  ),
                  MultiAsset(
                    policyId: "9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77",
                    assets: [
                      Asset(hexName: "53554e444145", value: BigInt.parse("200")),
                    ],
                  ),
                ],
              ),
              Value.v0(lovelace: BigInt.from(5)),
            ]),
            otherWalletOutputs: genOtherWalletOutputs([
              Value.v0(lovelace: BigInt.from(192)),
              Value.v0(lovelace: BigInt.from(192)),
            ]),
            certs: const Certificates(certificates: [], cborTags: [], lengthType: CborLengthType.definite),
            proposalProcedures: [],
            votingProcedures: null,
          );

          final (tx3, expectedTx3Diff, _) = gentx(
            thisWalletRewards: BigInt.zero,
            otherWalletRewards: BigInt.from(100),
            thisWalletUtxoInputs: [],
            otherWalletUtxoInputs: [otherWalletsUtxos[2]],
            thisWalletOutputs: genThisWalletOutputs([
              Value.v0(lovelace: BigInt.from(14)),
              Value.v0(lovelace: BigInt.from(5)),
            ]),
            otherWalletOutputs: genOtherWalletOutputs([
              Value.v0(lovelace: BigInt.from(1922)),
              Value.v0(lovelace: BigInt.from(2)),
            ]),
            certs: const Certificates(certificates: [], cborTags: [], lengthType: CborLengthType.definite),
            proposalProcedures: [],
            votingProcedures: null,
          );

          final expectedTotalDiff = expectedTx1Diff + expectedTx2Diff + expectedTx3Diff;
          final signingBundle = await SigningUtils.prepareTxsForSigning(
            txs: [tx1, tx2, tx3],
            walletUtxos: walletUtxos,
            walletReceiveAddressBech32: wallet.firstAddress.bech32Encoded,
            drepCredential: wallet.drepId.value.credentialsHex,
            constitutionalCommitteeColdCredential: wallet.constitutionalCommiteeCold.value.hexCredential,
            constitutionalCommitteeHotCredential: wallet.constitutionalCommiteeHot.value.hexCredential,
            networkId: wallet.networkId,
          );

          expect(signingBundle.totalDiff, equals(expectedTotalDiff));
          expect(signingBundle.txsData.length, equals(3));
          expect(
            signingBundle.txsData[0].signingAddressesRequired,
            equals([]),
          );
          expect(
            signingBundle.txsData[1].signingAddressesRequired,
            equals([]),
          );
          expect(
            signingBundle.txsData[2].signingAddressesRequired,
            equals([]),
          );
        });
      },
    );
    group(
      "Mixed incoming and outgoing",
      () {
        final (tx1, expectedTx1Diff, signAddrs1) = gentx(
          thisWalletRewards: BigInt.from(120),
          otherWalletRewards: BigInt.from(120),
          thisWalletUtxoInputs: [walletUtxos[0]],
          otherWalletUtxoInputs: [otherWalletsUtxos[0]],
          thisWalletOutputs: genThisWalletOutputs([
            Value.v0(lovelace: BigInt.parse("1000000000000")),
          ]),
          otherWalletOutputs: genOtherWalletOutputs([
            Value.v0(lovelace: BigInt.from(1922)),
          ]),
          certs: const Certificates(certificates: [], cborTags: [], lengthType: CborLengthType.definite),
          proposalProcedures: [],
          votingProcedures: null,
        );

        test("single tx diff check", () async {
          final signingBundle = await SigningUtils.prepareTxsForSigning(
            txs: [tx1],
            walletUtxos: walletUtxos,
            walletReceiveAddressBech32: wallet.firstAddress.bech32Encoded,
            drepCredential: wallet.drepId.value.credentialsHex,
            constitutionalCommitteeColdCredential: wallet.constitutionalCommiteeCold.value.hexCredential,
            constitutionalCommitteeHotCredential: wallet.constitutionalCommiteeHot.value.hexCredential,
            networkId: wallet.networkId,
          );
          expect(signingBundle.totalDiff, equals(expectedTx1Diff));
          expect(signingBundle.txsData.length, equals(1));
          expect(
            signingBundle.txsData[0].signingAddressesRequired,
            equals(signAddrs1),
          );
        });

        test("multiple txs with no chaining", () async {
          final (tx2, expectedTx2Diff, signAddrs2) = gentx(
            thisWalletRewards: BigInt.from(0),
            otherWalletRewards: BigInt.from(1220),
            thisWalletUtxoInputs: [
              walletUtxos[1],
              walletUtxos[12],
              walletUtxos[33],
              walletUtxos[34],
            ],
            otherWalletUtxoInputs: [
              otherWalletsUtxos[0],
              otherWalletsUtxos[1],
            ],
            thisWalletOutputs: genThisWalletOutputs([
              Value.v0(lovelace: BigInt.from(112)),
              Value.v1(
                lovelace: BigInt.from(1),
                mA: [
                  MultiAsset(
                    policyId: "b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef",
                    assets: [
                      Asset(hexName: "5350435b416c69656e5d202331313538", value: BigInt.from(1)),
                    ],
                  ),
                  MultiAsset(
                    policyId: "a1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52",
                    assets: [
                      Asset(hexName: "464c45534820544f4b454e", value: BigInt.parse("31718971375682855")),
                    ],
                  ),
                  MultiAsset(
                    policyId: "9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77",
                    assets: [
                      Asset(hexName: "53554e444145", value: BigInt.parse("200")),
                    ],
                  ),
                ],
              ),
              Value.v0(lovelace: BigInt.from(5)),
            ]),
            otherWalletOutputs: genOtherWalletOutputs([
              Value.v0(lovelace: BigInt.from(192)),
              Value.v0(lovelace: BigInt.from(192)),
            ]),
            certs: const Certificates(certificates: [], cborTags: [], lengthType: CborLengthType.definite),
            proposalProcedures: [],
            votingProcedures: null,
          );

          final (tx3, expectedTx3Diff, signAddrs3) = gentx(
            thisWalletRewards: BigInt.zero,
            otherWalletRewards: BigInt.zero,
            thisWalletUtxoInputs: [
              walletUtxos[4],
              walletUtxos[5],
            ],
            otherWalletUtxoInputs: [otherWalletsUtxos[2]],
            thisWalletOutputs: genThisWalletOutputs([
              Value.v0(lovelace: BigInt.from(14)),
              Value.v1(
                lovelace: BigInt.from(2482546),
                mA: [
                  MultiAsset(
                    policyId: "f15b1a746b16524305b39b9bb12bb27eafc4121af24f1e443feaec04",
                    assets: [
                      Asset(
                        hexName: "4d442023353520536f6369616c204d6564696120446566656e6465",
                        value: BigInt.parse("12"),
                      ),
                    ],
                  ),
                  MultiAsset(
                    policyId: "b37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592ef",
                    assets: [
                      Asset(
                        hexName: "5350435b416c69656e5d2023373530",
                        value: BigInt.parse("1"),
                      ),
                    ],
                  ),
                ],
              ),
            ]),
            otherWalletOutputs: genOtherWalletOutputs([
              Value.v0(lovelace: BigInt.from(1922)),
              Value.v0(lovelace: BigInt.from(2)),
            ]),
            certs: const Certificates(certificates: [], cborTags: [], lengthType: CborLengthType.definite),
            proposalProcedures: [],
            votingProcedures: null,
          );

          final expectedTotalDiff = expectedTx1Diff + expectedTx2Diff + expectedTx3Diff;
          final signingBundle = await SigningUtils.prepareTxsForSigning(
            txs: [tx1, tx2, tx3],
            walletUtxos: walletUtxos,
            walletReceiveAddressBech32: wallet.firstAddress.bech32Encoded,
            drepCredential: wallet.drepId.value.credentialsHex,
            constitutionalCommitteeColdCredential: wallet.constitutionalCommiteeCold.value.hexCredential,
            constitutionalCommitteeHotCredential: wallet.constitutionalCommiteeHot.value.hexCredential,
            networkId: wallet.networkId,
          );

          expect(signingBundle.totalDiff, equals(expectedTotalDiff));
          expect(signingBundle.txsData.length, equals(3));
          expect(
            signingBundle.txsData[0].signingAddressesRequired,
            equals(signAddrs1),
          );
          expect(
            signingBundle.txsData[1].signingAddressesRequired,
            equals(signAddrs2),
          );
          expect(
            signingBundle.txsData[2].signingAddressesRequired,
            equals(signAddrs3),
          );
        });
      },
    );
  });
}

final _otherWalletsUtxos = [
  "82825820840e2a99a354a6124a96c094d58a69a3323b2075c8503acdb5105e3d8a48e9b70382583901417c2ee0a344b0817236364cd4f659572832282e857c81890062dfe502ec24cc47b8415899e64e947c1a49bdc36fbb08d5db93e42546889f821a001e8480a1581c815418a1b078a259e678ecccc9d7eac7648d10b88f6f75ce2db8a25aa1554672616374696f6e2045737461746520546f6b656e1b000001ebb53d45f9",
  "8282582010df9593c75de962025a46c45d889d4e1ede2208d1b0467bfa70a1db91ccd4b80182583901417c2ee0a344b0817236364cd4f659572832282e857c81890062dfe502ec24cc47b8415899e64e947c1a49bdc36fbb08d5db93e42546889f821b000000010a6785fea5581c7261a890df6a65e267f3f60571b534c47603c5c7288189f102c24adca14f567946695f4144412f4645545f4c501b00000004e10729ed581c7cdf4b8d9a5a4fad4d609e54c82ed5c699c674681313488b4bc747a1a14a5554494c49545930333001581c815418a1b078a259e678ecccc9d7eac7648d10b88f6f75ce2db8a25aa1554672616374696f6e2045737461746520546f6b656e1b01ee2662e9760692581cf0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9aa14f6672616374696f6e2e65737461746501581cfa0009db1a71d3618ce6336f8bc623cdf81c99a3572f6755ef77e9aea14001",
  "82825820405805b464d698abbc07cc6c3e125b3d9c8cdcc83177b3716fd5e01d1d5ebe820182583901417c2ee0a344b0817236364cd4f659572832282e857c81890062dfe502ec24cc47b8415899e64e947c1a49bdc36fbb08d5db93e42546889f1a00f79d6c",
];

final _utxos =
    """
8282582073952449efe72265d2e6ff654e46ffd025006437a4bcb672f3f6e9919adda0120683583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0019f0a0a1581c8a1cfae21368b8bebbbed9800fec304e95cce39a2a57dc35e2e3ebaaa1444d494c4b18f7582020a0255f62f30b76a99fedad498353f5629c3c6aa75f4d07a9020100c697d1a7
828258206a66efa55b24f0816456f0106248b28b55c19b9de39d5e4744b6d55505d4b8c70782583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a003a98d2aa581cb1eb73a732247342724b85ca10f626b9494c69b6f5d21a2bd4052bf7a150544150316368696c6c696e673230323201581cb37b1d05794b9c046a584b7a02caea2a4840cb971e63e4ca613592efa94f5350435b416c69656e5d202337353001505350435b416c69656e5d20233131353801505350435b416c69656e5d20233133363401545350435b4865726f2046656d616c655d2023333301555350435b4865726f2046656d616c655d202337333501565350435b4865726f2046656d616c655d20233131383201565350435b4865726f2046656d616c655d20233139303201575350435b56696c6c61696e204d616c655d2023313534370158195350435b56696c6c61696e2046656d616c655d20233134373901581cb788fbee71a32d2efc5ee7d151f3917d99160f78fb1e41a1bbf80d8fa1494c454146544f4b454e1a1dd46455581cc88bbd1848db5ea665b1fffbefba86e8dcd723b5085348e8a8d2260fa14444414e411a000f4240581cd0f41ec7e976348635073611069457837401ba599896ef0ecde882a5a14001581cd5ad382393561e45b7e580415b99562eea6cd120ce6a542a4b8e1e95a35819426c657373696e67206f66207468652042756c6c202334363101581a426c657373696e67206f66207468652042756c6c20233236383201581a426c657373696e67206f66207468652042756c6c20233835323101581cda8c30857834c6ae7203935b89278c532b3995245295456f993e1d24a1424c511995db581cdd2bebba256099ddbc70d691935215d6dfd73cef054a087207947e89a1424d4d01581cdf91391a520cf3fc617c62144a2418be67d2e40d96a67c2cf66fdbb6a14001581ce14fe3ab348f9a6198359481472601f4557b9f86984f40a186a3b1e8a1464348455252591a0032dcd6
828258206a66efa55b24f0816456f0106248b28b55c19b9de39d5e4744b6d55505d4b8c70882583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001f9140a5581ce98165a25cd0320b25f22d686268e58e66f855b6d85974947ccd708da146414441464f58190342581cea2d23f1fa631b414252824c153f2d6ba833506477a929770a4dd9c2a1464d414442554c1a00051616581cf3bfa228ccaffa52bbe3f27ef3646516481cd15a80d1435083fe6b6ba158184144415969656c64204e46542047656d73202d203233303101581cf7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509ea2534144415969656c642047656d202d203239353601534144415969656c642047656d202d203437373601581cff97c85de383ebf0b047667ef23c697967719def58d380caf7f04b64a144534f554c186f
8282582003b605a6ea2d6a660c5e0c5225d29ce57970ae96ec40f2084c08cf55aef00ff30282583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0012593aa1581c772e4d6da1e199ace469b0d3cc39187fe7f7683684fb4ca23fa84b55a153535043526172697469657343726561746f723401
82825820ba9b432555370874c889aa0b9cdd86be37cd39dc67fe485cdc1760e480075ffe0082583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a00130196a1581cf15b1a746b16524305b39b9bb12bb27eafc4121af24f1e443feaec04a1581c4d442023353520536f6369616c204d6564696120446566656e64657201
8282582072bbaaa10d660596d888f4a0274b0c36641a406d7c0d3fe14299f1982eb46a8d0082583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0012dfeaa1581cd5ad382393561e45b7e580415b99562eea6cd120ce6a542a4b8e1e95a1581a426c657373696e67206f66207468652042756c6c20233430363201
82825820b4bd01ae8d1ba75b51977239e5ae9e7afaaa053ece537aba5ca8ae8f975366ba0082583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a00128bbca1581c919bfd1d5e53b4ceca544fc51cec935a2f603e7fbdc76c42884352e9a1564361646176657220506f7420436c756220233237363901
82825820bec757130228dbcae21dd38c7fd78d41d14985b8a229dfb205c56df8f9ddefbf0182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581c4632693c8a8ab3e325391bf319d69c24c54b823d70a85d870197fd38a14453414d551a1235b1ec
82825820353d48f6ec81fba28289f33e203dc6f12d709e86ce4f712511ddfe8652c24cad0182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b000d80d1a0fd7dfa
8282582019850accdf03bf42246a6c95bab7b2f09b949fefec6738adca9caad4ec549b7e0182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b001150855765f6d4
828258206716dbce499a1ee41b0fae9b9b21bba82c16fcd74e1880d02c273c5d2ab7e4e70182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b000680d890a7fe98
8282582084aef726b573c176b8354c14ee06bbe601af0db7cf7ef1cd5895024629bab4430182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b00035a508566a42d
82825820109472eecacada7c19edf9bf81af7992fdacf8779728eb511b389165fc788bae0182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b00035134a9d3dbd7
82825820c63a1d86b05249223bad8e5ec8fc84a61c74b8b7b45d549e3a456b49e77343ea0182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0012593aa1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b00001fa8da2ef5f5
82825820131a1f423a68f7b2ea25181426995c94418ee572fafb2501cd25eeef5728376b0282583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001215e2a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1a000f15fb
82825820eafc9e1a813bb08ef11d69243d25fa3760fd70ae40ab4a13e337c26d879fe1980182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b0007e22e4d9bfa87
82825820d62dd41e8d581ff2fe18ddd8bdcf0e2603e5a526cb2faa38ca23d537fd3d0a090182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b000794bb63492a4d
82825820a60046a7747b38636714637dc816ee7bfdf5bd4f189bf1844723bac44e85e6000182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b0007c964e5763f96
82825820eadbe0687fd3e3230033e86e3459e902db0f2da42e15d1fb6e2dc404ac821ffc0182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b0007af8f067efe31
82825820ffe1972ab7997534a97b389ee80e7ec96db1efbb74e27b4dd97cf15c1de69d040182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b00079638f7d85e01
8282582062931ca88dfafa7fbd86ee4583298ae99ce73b9246894794f0deef9e19ec350a0082583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0014e9d4a1581c681b5d0383ac3b457e1bcc453223c90ccef26b234328f45fa10fd276a1434a50471a01cbf39e
82825820f09f1585dcc33de944e75ccdd6d0ac853dec5976a50e5f5181d2e5caee6f35790182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a0249d420
82825820608d18a098ba5f801ec014522dd9ad14308d8b75c28d9e7265895b6cb8d696550282583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581c4edf29c64170c5b43c102d6056338152f1a6078efc10ad58be096fada1444d535a4e193162
82825820651a057d378a6528003b7d3bd5e2fb4d223618cd9804ce782de0506db29a28bf0282583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a002a1edca1581c263eb3e3c980c15305f393dc7a2f6289ba12732b6636efe46d6e2c16a14d545453547572746c653231343601
828258202cc5cf3548b22a126e4038854ad420a1f80c8fc2f8d0cf9b81143e7e84a684910282583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0225c7cba1581c263eb3e3c980c15305f393dc7a2f6289ba12732b6636efe46d6e2c16a14d545453547572746c653433383801
828258209b6bddf6a936d426ea92151978ded40e2282814fe26445337f937811654a485c0582583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a00155faea2581c263eb3e3c980c15305f393dc7a2f6289ba12732b6636efe46d6e2c16a14d545453547572746c653336333401581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b002f918031981060
82825820dcbe414e50d0cbcb548ae1c762175ce50783fe0f9d408d0041cafbe81b1f40f10082583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0419f973a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b000011614be0bd1c
828258200ff0a6501ae5f40dedb2dcb81cecc1403ed7b7a4e6c8b3a1f7b0590c2be646400182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a0031f3db
82825820705ff499b1a11657f3462d4800412252e0a583c5d5b3ae13b377284f8cfa4d8e0282583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0016080aa2581c101012a79c41d2008dc9eb7444b1a38e4a36e9466bf0467a9c708b11a15243617264616e6f2053756e7320233033363701581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b00002833ff764f4d
8282582072d8493b2231b5866a025b2de2e4147e286cf48500a9dd6ed34a0bb04784929c0282583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a002ed330aa581c10a49b996e2402269af553a8a96fb8eb90d79e9eca79e2b4223057b6a1444745524f1a001e8480581c2adf188218a66847024664f4f63939577627a56c090f679fe366c5eea146535441424c45191388581c2b28c81dbba6d67e4b5a997c6be1212cba9d60d33f82444ab8b1f218a14442414e4b192710581c3744d5e39333c384505214958c4ed66591a052778512e56caf420f62a1464e4542554c411a3b9aca00581c501dd5d2fbab6af0a26b1421076ff3afc4d5a34d6b3f9694571116eaa1454b4f4e44411903e8581ca0028f350aaabe0545fdcb56b039bfb08e4bb4d8c4d7c3c7d481c235a145484f534b591a000f4240581caf2e27f580f7f08e93190a81f72462f153026d06450924726645891ba144445249501a3bc49965581ce98165a25cd0320b25f22d686268e58e66f855b6d85974947ccd708da146414441464f581909c4581cf01ec1cb021922a491ea300fb4791dbaca720372b2a3142579c52e7da1444b616e691864581cf6ac48c64aa7af16434d9f84e014d11fba38525b436acc338ff20b0da1434d746301
82825820efed8b9064b60b08a38372b88bbba6bf996f58dd6ef08c5fbd9f78f3ad8ab231183b82583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0011b0dea1581cb3bd74dd43f83815519e387bdffd1cb9be411df8f2774f48e0fd3669a145534e4550451a00401685
828258204b4d065a121551da62a41b89a0134178480a339da3f51944fe344bb1252ee7ff0282583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001f5314a1581ce4214b7cce62ac6fbba385d164df48e157eae5863521b4b67ca71d86a1582078b7e0b7c5ea061b49104b587cf177564d1839a16cfb42f66a4999f96e79fbe71b000000018666588e
82825820b2a7a3f56dc0793327e082095bbe79a6a1ff4ed71af82e4210c187f493bbbe620182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a1fde5e0aa1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b0025ae59a225ccea
82825820377ef6c57f595403eb52c8b43e4a41121def3331e309600e71324bc3e6e882db0482583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0011e360a1581c44f8fabe04dc11bcf039128131b131b427db582f0e0be041a6b03691a14c534e454b504943533633303701
828258201f403c9e651163938a7f03b47254ebcfe508ad6d6d912d99f32b8ca1402aef160282583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a003d8e70aa581c919bfd1d5e53b4ceca544fc51cec935a2f603e7fbdc76c42884352e9aa564361646176657220506f7420436c756220233839323801564361646176657220506f7420436c756220233933373201564361646176657220506f7420436c756220233934393701564361646176657220506f7420436c756220233935303001564361646176657220506f7420436c756220233935353501564361646176657220506f7420436c756220233935383401564361646176657220506f7420436c756220233936313101564361646176657220506f7420436c756220233936373001564361646176657220506f7420436c756220233936373901564361646176657220506f7420436c756220233937363001581c927bce7a2c0b894c9b78b0a7793387e21d152c00a656e0b570609e7aa14b544845484552443132353401581c9a9693a9a37912a5097918f97918d15240c92ab729a0b7c4aa144d77a14653554e4441451a002549c6581c9f45dc075712bae139383b01dd6790b0c261aa95734ae10293a68919a257534b45544348206279204f646462616c6c2023313032330157534b45544348206279204f646462616c6c20233130323501581ca0028f350aaabe0545fdcb56b039bfb08e4bb4d8c4d7c3c7d481c235a145484f534b591a005282da581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b006d5f07dba92950581ca4da8764a57e66a0085b5bfcde96c89b798d92ee83a75f59237e375ba144464952451864581ca5bb0e5bb275a573d744a021f9b3bff73595468e002755b447e01559a156484f534b59436173684772616230303030363538343101581caf286714de22197a5358f54eaa7670bbc32696ba9492cf13c2359358a145544f5243481a0571825d581caf2e27f580f7f08e93190a81f72462f153026d06450924726645891ba144445249501a77359400
828258202d74730140ef81aec2e36770652d8cdad9517dc4b3a846a3e95738e1c5836699182182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a0019f32a
8282582091e2a7014957b4b86d4bcdc5f701968251a95bb06cc51f95f95efdd0d30bff170182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0292d0e2a1581c52162581184a457fad70470161179c5766f00237d4b67e0f1df1b4e6a1445452544c1a009f6955
828258203167f6d3a8d252d8a86a9e9941da699aa7a8d31a71f3d8c2c5476e0b0170bf1a0182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a043b5fc0a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b000006d4aa4429b0
82825820936243d69cf20651409ad0ac8295d340743a22d9cc5d58a417db3c15829b22150182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a023f3b3a
82825820cf6171b8cf298b8d7c2d4dc165c8bb2dceda8aa568108d398a48b589b50111790182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b000531eb4e290848
8282582002914894f8910bb677b12ea8778c6843a7ccd4f12336924c642d5ed58588ad1a0182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a002b63e5
828258205b8ccc2fdc9daeebc1f258a0ce3f9f6a5407aff27e1c9a0d9809990db9ba34280182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581c8db269c3ec630e06ae29f74bc39edd1f87c819f1056206e879a1cd61a14c446a65644d6963726f5553441a0185863b
8282582060da5a48239ae0589520d6e65363c61dbd93d9a9291123a852dc5ab7fe401aee0182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a03953ac2
8282582080ba06cbbb639cf837f11ea6609766de7c367196ec31b9236dc61fb25239f9810182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a000f4240
8282582080ba06cbbb639cf837f11ea6609766de7c367196ec31b9236dc61fb25239f9810282583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a032730a0
828258204f2a5394ee95a9354f6e047155dd84664d091a40bb886655429731fc5ef028070182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a008157d7
8282582025c0ea2355903c24d8e24a2605055774e903e90017229208866deaaf6ea653b40182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a0029f630
8282582025c0ea2355903c24d8e24a2605055774e903e90017229208866deaaf6ea653b40282583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a030c7cb0
82825820622eae31f4100210aea1be862eb7ef48af0c0a5981cfcfe44add2522f6cfdc260182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a0029f630
82825820622eae31f4100210aea1be862eb7ef48af0c0a5981cfcfe44add2522f6cfdc260282583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a030c7cb0
828258209749fb5019ba2a4788ef68ec26456ccc7809720fa72d8ded9d91ad3f6a3fc0ad0182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a0029f630
828258209749fb5019ba2a4788ef68ec26456ccc7809720fa72d8ded9d91ad3f6a3fc0ad0282583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a030c7cb0
828258208f98d2a3d93958f339c71c6ddd41fa885c75c76bcfadd2d9fa41efdbc83845c30382583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a02b6026b
82825820d5387d6a7c6c329bb04510316c31b9eb82c99aff06d4b6c0c991c010b0704d4d0482583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0012593aa1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b0012c7b748c2a0ba
82825820d5387d6a7c6c329bb04510316c31b9eb82c99aff06d4b6c0c991c010b0704d4d0582583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a00625e3b
82825820e49245b4d472b82ebac4d2496df7521185c5b45891bb5f537e48f1087449df9c0182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a00319750
8282582035df94557f3912d1dccf97d75eef1974305ad86759d9563e345aed4f94f4b5790182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a00319750
82825820e9cb2a69e2c2be50afb2822f7510487ab1871da7d584e496a5ffd8677669a54e0182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a009e3191
82825820802bfdf57218c9dd3581d18a3c6df0ec4396b6b931d4759c8322e1b9a8e3a2f80182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b0004ff8f0cec5461
82825820a592168d34cd29243400e2b166e55a751d0a37a740bf2dbf4340f6800d05ccab0182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a037c828c
828258201f08e2f34075f65797e1642f131914f21f0bdf1f612f31fc560581ac0fddb0640182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581cf66d78b4a3cb3d37afa0ec36461e51ecbde00f26c8f0a68f94b69880a144695553441a065487eb
82825820b921b8470526e1b1463b7f9472461dd9d3f604ef69ea86c63f0fa0b5f9ee64c00082583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a05b04fa5a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b00000a8e1661da97
82825820b921b8470526e1b1463b7f9472461dd9d3f604ef69ea86c63f0fa0b5f9ee64c00182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0014851ea1581c52162581184a457fad70470161179c5766f00237d4b67e0f1df1b4e6a1445452544c1a000575ce
82825820314c74e315a1660d6239e1690af9b72416b880ef13ed454858288c027dfb76720182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a02fed423
82825820b2e2f8164e5920dcaca040766bfd5e009c603f31f0171c29c413433cb659934e0082583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a001e70e7
8282582098d20dcb6dc16d6adec0b55745e96a6d74559ee95b0219d195514c260e9d7bcf0282583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a002be0b5
82825820f6e95511389c4c511e3e3a151cc926d8176b68aeb2160b8832b739c8087fad910282583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a003ebd7cb0581c0171c997b8853fde686763d93b36ab8e04ce947bb6aa09a9ee5c4401a145544f4b454e190682581c02556bc675933f15fe65a1a9350a0a2d23befbfb098ed8b3850bfaf8a14001581c153be682cc6068445eac2e36a71e364617aa34db90f820685340fe75a1434c524e03581c279c909f348e533da5808898f87f9a14bb2c3dfbbacccd631d927a3fa144534e454b190dac581c418686ba2ff6d8a15c36167bbcb6e7a89a9ca7f2c739c7b16a691b00a1554144415969656c6420506f7765722047656d20323501581c443726318f7a3995686a79f65ed48fdb79aaf576aecaee354d8ba018a1444e49444f1832581c544571c086d0e5c5022aca9717dd0f438e21190abb48f37b3ae129f0a14447524f5701581c54da2b84d529d55ee7c9a31b9772becf078eac6806e120ed464b5a1ba34352797501464e696e6a6133014d4e696e6a61617373617373696e01581c641f0571d02b45b868ac1c479fc8118c5be6744ec3d2c5e13bd888b6a1465a4f4d4249451903e8581c6954264b15bc92d6d592febeac84f14645e1ed46ca5ebb9acdb5c15fa1455354524950193a98581c74946c67d2a6afbdfd9450eb9818f202ba26143f821990d7a45b515ca151447269707079323330353034303435373701581c772e4d6da1e199ace469b0d3cc39187fe7f7683684fb4ca23fa84b55a249535043444556494c37014a535043414c49454e313401581c7f376e3d1cf52e6c4350a1a91c8f8d0f0b63baedd443999ebe8fe57aa145424f52475a194e20581c86ec26a91051e4d42df00b023202e177a0027dca4294a20a0326a116a14e617175616661726d65723334353801581c8f9c32977d2bacb87836b64f7811e99734c6368373958da20172afbaa1464d5949454c441a008f2087581c919bfd1d5e53b4ceca544fc51cec935a2f603e7fbdc76c42884352e9a2544361646176657220506f7420436c75622023373101554361646176657220506f7420436c7562202331323101
82825820f6e95511389c4c511e3e3a151cc926d8176b68aeb2160b8832b739c8087fad910382583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a003023e8a1581c919bfd1d5e53b4ceca544fc51cec935a2f603e7fbdc76c42884352e9b4554361646176657220506f7420436c7562202333353601554361646176657220506f7420436c7562202333393401554361646176657220506f7420436c7562202333393801554361646176657220506f7420436c7562202334313001554361646176657220506f7420436c7562202334393901554361646176657220506f7420436c7562202339373701564361646176657220506f7420436c756220233133383301564361646176657220506f7420436c756220233135393101564361646176657220506f7420436c756220233136303301564361646176657220506f7420436c756220233137333101564361646176657220506f7420436c756220233139383401564361646176657220506f7420436c756220233230313501564361646176657220506f7420436c756220233231333101564361646176657220506f7420436c756220233231373301564361646176657220506f7420436c756220233234303201564361646176657220506f7420436c756220233234393501564361646176657220506f7420436c756220233237373801564361646176657220506f7420436c756220233238323201564361646176657220506f7420436c756220233239353501564361646176657220506f7420436c756220233330393101
82825820f6e95511389c4c511e3e3a151cc926d8176b68aeb2160b8832b739c8087fad910482583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a003088eca1581c919bfd1d5e53b4ceca544fc51cec935a2f603e7fbdc76c42884352e9b4564361646176657220506f7420436c756220233637373601564361646176657220506f7420436c756220233638333901564361646176657220506f7420436c756220233730373401564361646176657220506f7420436c756220233731303201564361646176657220506f7420436c756220233731363701564361646176657220506f7420436c756220233732313401564361646176657220506f7420436c756220233732343201564361646176657220506f7420436c756220233736363201564361646176657220506f7420436c756220233737303401564361646176657220506f7420436c756220233737313901564361646176657220506f7420436c756220233737383601564361646176657220506f7420436c756220233739343401564361646176657220506f7420436c756220233830383101564361646176657220506f7420436c756220233833353101564361646176657220506f7420436c756220233834363301564361646176657220506f7420436c756220233835343001564361646176657220506f7420436c756220233837363601564361646176657220506f7420436c756220233837373601564361646176657220506f7420436c756220233839323301564361646176657220506f7420436c756220233839323701
82825820f6e95511389c4c511e3e3a151cc926d8176b68aeb2160b8832b739c8087fad910582583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a003f00d4ab581c282bce67f2a5336c4fdff43acc52c764bd464a669c098edec7a86d65a144545944451a0004220e581c3695a0fb45b370a9106871af6858ca3b85c4a8813e80ba9d02dd0e96a2581950737963686f4e61757420466c6970e280994420233330363601581950737963686f4e61757420466c6970e280994420233738363001581c46fabda64ea88c886a58f4a8dd07554df6f61f33b1ed8b2bf075a4a8a1581a53656e73616920526f67756520477561726469616e202333313001581c8202ff963ba5815acf0cb8867d1bac1027a1c6c423f30a6236e4e99ba1581e4d44202333313820436f64652053656e74696e656c20477561726469616e01581c919bfd1d5e53b4ceca544fc51cec935a2f603e7fbdc76c42884352e9a1564361646176657220506f7420436c756220233637353701581cc88bbd1848db5ea665b1fffbefba86e8dcd723b5085348e8a8d2260fa14444414e411a001e8480581ce14fe3ab348f9a6198359481472601f4557b9f86984f40a186a3b1e8a1464348455252591a0065b9aa581ce98165a25cd0320b25f22d686268e58e66f855b6d85974947ccd708da146414441464f58190682581cea2d23f1fa631b414252824c153f2d6ba833506477a929770a4dd9c2a1464d414442554c1a000a2c2a581cf7206fd0d0df2e14ad6b10d36b0b29231bb3f295880e9c01f43f509ea9524144415969656c642047656d202d2037343601524144415969656c642047656d202d2038333201534144415969656c642047656d202d203133343601534144415969656c642047656d202d203135343201534144415969656c642047656d202d203137323101534144415969656c642047656d202d203235353801534144415969656c642047656d202d203432313001534144415969656c642047656d202d203434313201534144415969656c642047656d202d203530343801581cff97c85de383ebf0b047667ef23c697967719def58d380caf7f04b64a144534f554c18de
82825820f6e95511389c4c511e3e3a151cc926d8176b68aeb2160b8832b739c8087fad910782583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a00190e7ea3581c6ded36273214629f9ff35e9f9c7b8945d937a80a3796ddc4a646a50ea1434859431b00000007ed661724581c919bfd1d5e53b4ceca544fc51cec935a2f603e7fbdc76c42884352e9a1564361646176657220506f7420436c756220233637313801581cc74e5ac704ead929b389935a5643a87b8e1d98b79b98c903d5557245a15646616c736549646f6c73416e696d617465643335373401
82825820d69b3e739116bbcb798b1222a5397fb6ade4d66b9fcc0aab93b3e4fa5604252f0182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b00060f9315777d6c
8282582013511c47dc38b24780b7e1406ec56b3477bd651ecc68ba341477d955656a01150182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b0005fe60ea740d32
8282582037503bd9d59b980328accc7d63153b0423ee81822dfe7df915c4deb79f93f03f0082583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a004c4b40
8282582037503bd9d59b980328accc7d63153b0423ee81822dfe7df915c4deb79f93f03f0182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a0032f7daa3581c919bfd1d5e53b4ceca544fc51cec935a2f603e7fbdc76c42884352e9b2564361646176657220506f7420436c756220233331303201564361646176657220506f7420436c756220233331383701564361646176657220506f7420436c756220233332323701564361646176657220506f7420436c756220233335373401564361646176657220506f7420436c756220233338393601564361646176657220506f7420436c756220233339323301564361646176657220506f7420436c756220233432343601564361646176657220506f7420436c756220233435363101564361646176657220506f7420436c756220233437353901564361646176657220506f7420436c756220233439383001564361646176657220506f7420436c756220233534303801564361646176657220506f7420436c756220233535363201564361646176657220506f7420436c756220233538313001564361646176657220506f7420436c756220233538373801564361646176657220506f7420436c756220233632343501564361646176657220506f7420436c756220233634343501564361646176657220506f7420436c756220233635303501564361646176657220506f7420436c756220233636323501581c9f3506e262a1c2fbb9b0259e010fadb336f4089970f380b1af75ccd5a14001581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b00bfb36164f69aa0
8282582037503bd9d59b980328accc7d63153b0423ee81822dfe7df915c4deb79f93f03f0282583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a0016ad39
82825820a4885d8838e20997169aafecc91cdb5b0be36a8817deea0d7a555e82df1f31810182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b0005ed779049ea61
82825820944d72a7c99081ea547417db9d7810bd113a4df7a895e17b2eb271e8af17031d0182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b0005dcd56e0313bc
828258203722e79b92a9534f4386eb96dbfe1f9261bc979084cc3e6a29177ac60f3d385f0482583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a013c4021
8282582035b58ad4245337e03b84c9c42707dbd14dde49039f201c4843faf430f67de6df0182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a0034a490
8282582035b58ad4245337e03b84c9c42707dbd14dde49039f201c4843faf430f67de6df0282583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a03d32810
8282582021bea58205659c2701d907f1fd49c8e0caa86d47b5ffb399e27bd5d1071668ff0182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a2581c9b426921a21f54600711da0be1a12b026703a9bd8eb9848d08c9d921a146434154534b591a002e7274581ce4214b7cce62ac6fbba385d164df48e157eae5863521b4b67ca71d86a1582076ab3fb1e92b7a58ee94b712d1c1bff0e24146e8e508aa0008443e1db1f2244e1a0214d165
828258207af34a1ca740fab43e823a09bd6f5431d1a59d3ce183091b3302e4580986e4fe0182583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581c438514ae1beb020d35e5389993447cea29637d6272c918017988ef36a1484164615969656c641b00001255c49a2d5e
82825820b60cfac761d672f7fe927d052783f3a5a4b7be544f233c5fe70e59595ba492fb0182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a0d6a4537
8282582074df71cb6345c9d2b952412d09f6bda20c9fd94520d6f923bc4a6fa676d774dd0182583901130ad6e96b06e35a2f33f8a3acfbc8935d29f2b6709b6417ac948e41272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a001e8480a1581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b0003aeb3912372cc
828258204e8e9808f7daa002e9736186a76c2a3fbdf598b04893d4208ca6160fb6a5ac990282583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934821a285b0e6ca2581c772e4d6da1e199ace469b0d3cc39187fe7f7683684fb4ca23fa84b55a15253504352617269746965734379626f72673901581ca1ce0414d79b040f986f3bcd187a7563fd26662390dece6b12262b52a14b464c45534820544f4b454e1b00263d655aea1d08
8282582049578ecb61ec37c2fa02093e0afe0d868d4e6e2a6e52f21c7ea6bcc1a67451960182583901a0bb6182fcddf954280545c0064431c2ec67c77f168f0d5446d7dded272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341a019bfcc0
"""
        .split("\n")
        .where((e) => e.trim().isNotEmpty);
