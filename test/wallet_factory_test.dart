import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:test/test.dart";

void main() async {
  const mnemonic =
      "chief fiber betray curve tissue output feature jungle adapt smile brown crane accuse gospel plate unlock pull arrow hard february tape soccer patrol fetch";

  final walletTestnet = await WalletFactory.fromMnemonic(NetworkId.testnet, mnemonic.split(" "));
  final walletMainnet = await WalletFactory.fromMnemonic(NetworkId.mainnet, mnemonic.split(" "));

  final receiveAddressTests = [
    (
      index: 0,
      mainnet:
          "addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx",
      testnet:
          "addr_test1qrjn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qhkdw7e",
    ),
    (
      index: 5,
      mainnet:
          "addr1qyhxwcdvsszr9fhqwstau36hmvzpf4gn8wqyt8zu7s50yfe8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q6pgzyj",
      testnet:
          "addr_test1qqhxwcdvsszr9fhqwstau36hmvzpf4gn8wqyt8zu7s50yfe8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qeh4zgd",
    ),
  ];

  final changeAddressTests = [
    (
      index: 0,
      mainnet:
          "addr1qycyp2gry5xe8wlhqjlwr7gydz6x5n9px387np4n8g4axte8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q2nu98l",
      testnet:
          "addr_test1qqcyp2gry5xe8wlhqjlwr7gydz6x5n9px387np4n8g4axte8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qf9p9tq",
    ),
    (
      index: 5,
      mainnet:
          "addr1qy64f2fz2ahrfvne4ddpt696jpf9etw4zz3y7u2nsvqyrt38959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qt49nx6",
      testnet:
          "addr_test1qq64f2fz2ahrfvne4ddpt696jpf9etw4zz3y7u2nsvqyrt38959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qgrcn29",
    ),
  ];

  group("receive address", () {
    for (final r in receiveAddressTests) {
      test("mainnet derive receive testnet ${r.index}", () async {
        expect(
          (await walletMainnet.getPaymentAddressKit(addressIndex: r.index)).address.bech32Encoded,
          r.mainnet,
        );
      });
      test("testnet derive receive address ${r.index}", () async {
        expect(
          (await walletTestnet.getPaymentAddressKit(addressIndex: r.index)).address.bech32Encoded,
          r.testnet,
        );
      });
    }
  });

  group("change address", () {
    for (final r in changeAddressTests) {
      test("mainnet derive change testnet ${r.index}", () async {
        expect(
          (await walletMainnet.getChangeAddressKit(addressIndex: r.index)).address.bech32Encoded,
          r.mainnet,
        );
      });
      test("testnet derive change address ${r.index}", () async {
        expect(
          (await walletTestnet.getChangeAddressKit(addressIndex: r.index)).address.bech32Encoded,
          r.testnet,
        );
      });
    }
  });

  group("precomputed", () {
    test("xpub", () async {
      expect(
        walletMainnet.xPubBech32,
        "xpub1hfku0gtwhnla0gpf4r6nfl5zdu3fm64qnc5v74yw2mw0sqa8rzdv7j0d9x5rjfaay0levhrfq3en7q2u4nerrq6uxtmkpcp8fhlsq5sl4m0w6",
      );
    });

    group("testnet", () {
      test("first address", () {
        expect(
          walletTestnet.firstAddress.bech32Encoded,
          "addr_test1qrjn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qhkdw7e",
        );
      });
      test("stake address", () {
        expect(
          walletTestnet.stakeAddress.bech32Encoded,
          "stake_test1uqnj6zu8ldae2cw5600wg6udgg4g4rk92hz3fc43turjjdqg8a07k",
        );
      });
      test("drepId", () {
        expect(
          walletTestnet.drepId.value.dRepKeyHex,
          "320b0744172502cec5a5984a4431d62ea8a3896a8d570ac517afeecac66f3b85",
        );
        expect(
          walletTestnet.drepId.value.credentialsHex,
          "23bc63ced4e40b22dd4e6051c258ba38d5679d81e33f34fe5e5cdb4d",
        );
        expect(
          walletTestnet.drepId.value.dRepIdLegacyHex,
          "23bc63ced4e40b22dd4e6051c258ba38d5679d81e33f34fe5e5cdb4d",
        );
        expect(
          walletTestnet.drepId.value.dRepIdLegacyBech32,
          "drep1yw7x8nk5us9j9h2wvpguyk968r2k08vpuvlnflj7tnd56s5d4h0",
        );
        expect(
          walletTestnet.drepId.value.dRepIdNewHex,
          "2223bc63ced4e40b22dd4e6051c258ba38d5679d81e33f34fe5e5cdb4d",
        );
        expect(
          walletTestnet.drepId.value.dRepIdNewBech32,
          "drep1yg3mcc7w6njqkgkafes9rsjchgud2euas83n7d87tewdkngpgk07n",
        );
      });
      test("constitutional committee cold", () {
        expect(
          walletTestnet.constitutionalCommiteeCold.value.hexCCKey,
          "2f5e3315fffac94a496a41767651dced59a7e8c707ea63b2dff9c908fde4f0ef",
        );
        expect(
          walletTestnet.constitutionalCommiteeCold.value.hexCredential,
          "6c75d41fcad1f491288527f61f5ce8c91b17f75718f74a59d0d68d91",
        );
        expect(
          walletTestnet.constitutionalCommiteeCold.value.ccIdHex,
          "126c75d41fcad1f491288527f61f5ce8c91b17f75718f74a59d0d68d91",
        );
        expect(
          walletTestnet.constitutionalCommiteeCold.value.ccIdBech32,
          "cc_cold1zfk8t4qletglfyfgs5nlv86uary3k9lh2uv0wjje6rtgmygjy5cwg",
        );
      });
      test("constitutional committee hot", () {
        expect(
          walletTestnet.constitutionalCommiteeHot.value.hexCCKey,
          "2e121a022a0bd77d78b0c5c7b2dbbcd93b8c1a610db685357892990bafe6705b",
        );
        expect(
          walletTestnet.constitutionalCommiteeHot.value.hexCredential,
          "f961d3ba10b1a37eace7a9bda453974af8615e2d9932676a4b68d940",
        );
        expect(
          walletTestnet.constitutionalCommiteeHot.value.ccIdHex,
          "02f961d3ba10b1a37eace7a9bda453974af8615e2d9932676a4b68d940",
        );
        expect(
          walletTestnet.constitutionalCommiteeHot.value.ccIdBech32,
          "cc_hot1qtukr5a6zzc6xl4vu75mmfznja90sc279kvnyem2fd5djsqp59yfn",
        );
      });
    });
    group("mainnet", () {
      test("first address", () {
        expect(
          walletMainnet.firstAddress.bech32Encoded,
          "addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx",
        );
      });
      test("stake address", () {
        expect(
          walletMainnet.stakeAddress.bech32Encoded,
          "stake1uynj6zu8ldae2cw5600wg6udgg4g4rk92hz3fc43turjjdq0dhd6t",
        );
      });
      test("drepId", () {
        expect(
          walletMainnet.drepId.value.dRepKeyHex,
          "320b0744172502cec5a5984a4431d62ea8a3896a8d570ac517afeecac66f3b85",
        );
        expect(
          walletMainnet.drepId.value.dRepIdLegacyHex,
          "23bc63ced4e40b22dd4e6051c258ba38d5679d81e33f34fe5e5cdb4d",
        );
        expect(
          walletMainnet.drepId.value.dRepIdLegacyBech32,
          "drep1yw7x8nk5us9j9h2wvpguyk968r2k08vpuvlnflj7tnd56s5d4h0",
        );
        expect(
          walletMainnet.drepId.value.dRepIdNewHex,
          "2223bc63ced4e40b22dd4e6051c258ba38d5679d81e33f34fe5e5cdb4d",
        );
        expect(
          walletMainnet.drepId.value.dRepIdNewBech32,
          "drep1yg3mcc7w6njqkgkafes9rsjchgud2euas83n7d87tewdkngpgk07n",
        );
      });
      test("constitutional committee cold", () {
        expect(
          walletMainnet.constitutionalCommiteeCold.value.hexCCKey,
          "2f5e3315fffac94a496a41767651dced59a7e8c707ea63b2dff9c908fde4f0ef",
        );
        expect(
          walletMainnet.constitutionalCommiteeCold.value.hexCredential,
          "6c75d41fcad1f491288527f61f5ce8c91b17f75718f74a59d0d68d91",
        );
        expect(
          walletMainnet.constitutionalCommiteeCold.value.ccIdBech32,
          "cc_cold1zfk8t4qletglfyfgs5nlv86uary3k9lh2uv0wjje6rtgmygjy5cwg",
        );
      });
      test("constitutional committee hot", () {
        expect(
          walletMainnet.constitutionalCommiteeHot.value.hexCCKey,
          "2e121a022a0bd77d78b0c5c7b2dbbcd93b8c1a610db685357892990bafe6705b",
        );
        expect(
          walletMainnet.constitutionalCommiteeHot.value.hexCredential,
          "f961d3ba10b1a37eace7a9bda453974af8615e2d9932676a4b68d940",
        );
        expect(
          walletMainnet.constitutionalCommiteeHot.value.ccIdBech32,
          "cc_hot1qtukr5a6zzc6xl4vu75mmfznja90sc279kvnyem2fd5djsqp59yfn",
        );
      });
    });
  });
}
