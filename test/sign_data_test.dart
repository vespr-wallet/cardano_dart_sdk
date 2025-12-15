import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:test/test.dart";

void main() async {
  const inputMessageHex =
      "4920616d206c6f6767696e6720696e20746f206a70672e73746f72652e204d7920766572696669636174696f6e20636f64652069733a20393233353630353238";

  const mnemonic =
      "chief fiber betray curve tissue output feature jungle adapt smile brown crane accuse gospel plate unlock pull arrow hard february tape soccer patrol fetch";

  final walletMainnet = await WalletFactory.fromMnemonic(NetworkId.mainnet, mnemonic.split(" "));
  final walletTestnet = await WalletFactory.fromMnemonic(NetworkId.testnet, mnemonic.split(" "));

  group("testnet", () {
    final wallet = walletTestnet;

    group("rewards address", () {
      const expectedResult = DataSignature(
        coseKeyHex: "a4010103272006215820a637d4e865c8a12c4797f4b0a9c79a33a33c3b9b58afb20cc486591fd34e150a",
        coseSignHex:
            "84582aa201276761646472657373581de0272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934a166686173686564f458404920616d206c6f6767696e6720696e20746f206a70672e73746f72652e204d7920766572696669636174696f6e20636f64652069733a203932333536303532385840c4cefe579112b5a77caebc900b5764a4c1af23f579721565fc706836f88e8fa684885a92df266637f38b39318268b87df137cf16d119f95228c09ead45789509",
      );
      final items = {
        "bech32": "stake_test1uqnj6zu8ldae2cw5600wg6udgg4g4rk92hz3fc43turjjdqg8a07k",
        "hex": "e0272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934",
      };

      for (final item in items.entries) {
        test(item.key, () async {
          final actualResult = await wallet.signData(payloadHex: inputMessageHex, requestedSignerRaw: item.value);

          expect(actualResult, expectedResult);
        });
      }
    });
  });

  group("mainnet", () {
    final wallet = walletMainnet;

    group("rewards address", () {
      const expectedResult = DataSignature(
        coseKeyHex: "a4010103272006215820a637d4e865c8a12c4797f4b0a9c79a33a33c3b9b58afb20cc486591fd34e150a",
        coseSignHex:
            "84582aa201276761646472657373581de1272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934a166686173686564f458404920616d206c6f6767696e6720696e20746f206a70672e73746f72652e204d7920766572696669636174696f6e20636f64652069733a203932333536303532385840babe12ff606706ada994bf21902bb65c2ced20ffbdd5f72dffd76d91eee1bd4dd6f0c0e89fd718ac623ded57c882aba5e094e3124689b8f446e46bddd6680b07",
      );
      final items = {
        "bech32": "stake1uynj6zu8ldae2cw5600wg6udgg4g4rk92hz3fc43turjjdq0dhd6t",
        "hex": "e1272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934",
      };

      for (final item in items.entries) {
        test(item.key, () async {
          final actualResult = await wallet.signData(payloadHex: inputMessageHex, requestedSignerRaw: item.value);

          expect(actualResult, expectedResult);
        });
      }
    });

    group("payment address", () {
      const expectedResult = DataSignature(
        coseKeyHex: "a4010103272006215820acb1c00cbfdcb5d79915d27cca0b8566646d1e0b86e61c67a1bcd289e6e2a938",
        coseSignHex:
            "845846a201276761646472657373583901e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934a166686173686564f458404920616d206c6f6767696e6720696e20746f206a70672e73746f72652e204d7920766572696669636174696f6e20636f64652069733a2039323335363035323858409b471c352b65f2d520012225215f50dec0d6d9b5bdf217edf1f7bdf35c2b56171d73d8b0bd5c2baae300c1a794245652459b78be654d1eaebc21b9af82b00d09",
      );
      final items = {
        "bech32":
            "addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx",
        "hex":
            "01e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934",
      };

      for (final item in items.entries) {
        test(item.key, () async {
          final actualResult = await wallet.signData(payloadHex: inputMessageHex, requestedSignerRaw: item.value);

          expect(actualResult, expectedResult);
        });
      }
    });

    group("enterprise address", () {
      // Enterprise address uses only payment credential (no stake part)
      // Same payment key as base address, so coseKeyHex should be identical
      const expectedResult = DataSignature(
        coseKeyHex: "a4010103272006215820acb1c00cbfdcb5d79915d27cca0b8566646d1e0b86e61c67a1bcd289e6e2a938",
        coseSignHex:
            "84582aa201276761646472657373581d61e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023a166686173686564f458404920616d206c6f6767696e6720696e20746f206a70672e73746f72652e204d7920766572696669636174696f6e20636f64652069733a203932333536303532385840166be3c79287b630f29266425cdd5b0b606c004f8f21620959c91af27cdeaae333c1f038e15cd9c83ae8a6241cc3d225c5f6813a48ef1a91c8d84c6380d57504",
      );
      final items = {
        "bech32": "addr1v8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqgcvfr3f7",
        "hex": "61e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023",
      };

      for (final item in items.entries) {
        test(item.key, () async {
          final actualResult = await wallet.signData(payloadHex: inputMessageHex, requestedSignerRaw: item.value);

          expect(actualResult, expectedResult);
        });
      }
    });

    group("drep id", () {
      final items = {
        "bech": "drep1yg3mcc7w6njqkgkafes9rsjchgud2euas83n7d87tewdkngpgk07n", // bech32
        "hex": "2223bc63ced4e40b22dd4e6051c258ba38d5679d81e33f34fe5e5cdb4d", // hex
      };

      const expectedResult = DataSignature(
        coseKeyHex: "a4010103272006215820320b0744172502cec5a5984a4431d62ea8a3896a8d570ac517afeecac66f3b85",
        coseSignHex:
            "845829a201276761646472657373581c23bc63ced4e40b22dd4e6051c258ba38d5679d81e33f34fe5e5cdb4da166686173686564f458404920616d206c6f6767696e6720696e20746f206a70672e73746f72652e204d7920766572696669636174696f6e20636f64652069733a203932333536303532385840ed7e6a419e0765f4f50aa2e30f4b5486e11e27beb02b532d66cef80c00af24b5e7fe31f28fafa0aec2b9d1d3ddbfca0019d9b89fa45275024cd18ca437dc5f0f",
      );

      for (final item in items.entries) {
        test(item.key, () async {
          final actualResult = await wallet.signData(payloadHex: inputMessageHex, requestedSignerRaw: item.value);

          expect(actualResult, expectedResult);
        });
      }
    });
  });
}
