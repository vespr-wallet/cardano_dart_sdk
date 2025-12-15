import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:cardano_flutter_sdk/workers/wallet_tasks_sign.dart";
import "package:pinenacl/api.dart";
import "package:test/test.dart";

void main() {
  group("WalletTasksSign.findCardanoSigner", () {
    // Using the xpub from example/verify_signature_example.dart for consistent test data
    const xpubHex =
        "ba6dc7a16ebcffd7a029a8f534fe826f229deaa09e28cf548e56dcf803a7189acf49ed29a83927bd23ff965c6904733f015cacf231835c32f760e0274dff0052";

    late CardanoPubAccount pubAccount;

    setUpAll(() async {
      pubAccount = await CardanoPubAccountWorkerFactory.instance.fromHexXPub(xpubHex);
    });

    group("DRep credentials (network agnostic)", () {
      const drepCredsHex = "23bc63ced4e40b22dd4e6051c258ba38d5679d81e33f34fe5e5cdb4d";
      const drepRawKeyHex = "320b0744172502cec5a5984a4431d62ea8a3896a8d570ac517afeecac66f3b85";
      final Map<String, String> testCases = {
        "drep id old hex (= drep creds hex)": drepCredsHex,
        "drep id new hex": "2223bc63ced4e40b22dd4e6051c258ba38d5679d81e33f34fe5e5cdb4d",
        "drep id old bech32": "drep1yw7x8nk5us9j9h2wvpguyk968r2k08vpuvlnflj7tnd56s5d4h0",
        "drep id new bech32": "drep1yg3mcc7w6njqkgkafes9rsjchgud2euas83n7d87tewdkngpgk07n",
      };

      for (final entry in testCases.entries) {
        final testName = entry.key;
        final drepValue = entry.value;

        test(testName, () async {
          final result = await WalletTasksSign.findCardanoSigner(
            pubAccount: pubAccount,
            requestedSignerRaw: drepValue,
            deriveMaxAddressCount: 10,
          );

          expect(result.path.role, equals(Bip32KeyRole.drepCredential));
          expect(result.path.address, equals(0));
          expect(result.requestedSignerBytes.hexEncode(), equals(drepCredsHex));
          expect(result.publicKeyBytes.hexEncode(), equals(drepRawKeyHex));
        });
      }

      test("throws for invalid DRep credentials", () async {
        // Invalid DRep credentials that don't match the wallet
        const invalidDrepCredsHex = "23bc63ced4e40b12dd4e6051c258ba38d5679d81e33f34fe5e5cdb4d";

        await expectLater(
          WalletTasksSign.findCardanoSigner(
            pubAccount: pubAccount,
            requestedSignerRaw: invalidDrepCredsHex,
            deriveMaxAddressCount: 10,
          ),
          throwsA(isA<SigningAddressNotFoundException>()),
        );
      });
    });

    group("58 byte addresses", () {
      test("finds DRep address with header > 1", () async {
        // DRep address with header indicating DRep (header & 0x0f > 1)
        // Type 2 DRep key hash (0x22)
        const drepAddressHex = "2223bc63ced4e40b22dd4e6051c258ba38d5679d81e33f34fe5e5cdb4d"; // 29 bytes = 58 hex

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: drepAddressHex,
          deriveMaxAddressCount: 10,
        );

        expect(result.path.role, equals(Bip32KeyRole.drepCredential));
      });

      test("finds stake address (reward address) - testnet", () async {
        // Testnet stake address
        const stakeBech32 = "stake_test1uqnj6zu8ldae2cw5600wg6udgg4g4rk92hz3fc43turjjdqg8a07k";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: stakeBech32,
          deriveMaxAddressCount: 10,
        );

        expect(result.path.role, equals(Bip32KeyRole.staking));
        expect(result.path.address, equals(0));
      });

      test("finds stake address (reward address) - mainnet", () async {
        // Mainnet stake address
        const stakeBech32 = "stake1uynj6zu8ldae2cw5600wg6udgg4g4rk92hz3fc43turjjdq0dhd6t";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: stakeBech32,
          deriveMaxAddressCount: 10,
        );

        expect(result.path.role, equals(Bip32KeyRole.staking));
        expect(result.path.address, equals(0));
      });

      test("finds stake address - hex format", () async {
        // Testnet stake address in hex
        const stakeHex = "e0272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: stakeHex,
          deriveMaxAddressCount: 10,
        );

        expect(result.path.role, equals(Bip32KeyRole.staking));
        expect(
          result.publicKeyBytes.hexEncode(),
          equals("a637d4e865c8a12c4797f4b0a9c79a33a33c3b9b58afb20cc486591fd34e150a"),
        );
      });

      test("throws for invalid stake address", () async {
        const invalidStakeHex = "e0000000000000000000000000000000000000000000000000000000";

        await expectLater(
          WalletTasksSign.findCardanoSigner(
            pubAccount: pubAccount,
            requestedSignerRaw: invalidStakeHex,
            deriveMaxAddressCount: 10,
          ),
          throwsA(isA<SigningAddressNotFoundException>()),
        );
      });
    });

    group("114 byte base addresses", () {
      test("finds payment address at index 0 - bech32", () async {
        const paymentAddr =
            "addr_test1qrjn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qhkdw7e";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: paymentAddr,
          deriveMaxAddressCount: 10,
        );

        expect(result.path.role, equals(Bip32KeyRole.payment));
        expect(result.path.address, equals(0));
        expect(
          result.publicKeyBytes.hexEncode(),
          equals("acb1c00cbfdcb5d79915d27cca0b8566646d1e0b86e61c67a1bcd289e6e2a938"),
        );
      });

      test("finds payment address at index 1 - hex", () async {
        // Testnet payment address at index 1 in hex
        const paymentAddrHex =
            "00295950743dbc2af0b7f980ca56c0d7a90780a71ce3589433e334ffdd272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: paymentAddrHex,
          deriveMaxAddressCount: 10,
        );

        expect(result.path.role, equals(Bip32KeyRole.payment));
        expect(result.path.address, equals(1));
        expect(
          result.publicKeyBytes.hexEncode(),
          equals("c3a0ca51564270d067e7deee40c460033ed42171c73af61b0b20ea346c1c1f92"),
        );
      });

      test("finds change address at index 0 - bech32", () async {
        const changeAddr =
            "addr_test1qqcyp2gry5xe8wlhqjlwr7gydz6x5n9px387np4n8g4axte8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qf9p9tq";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: changeAddr,
          deriveMaxAddressCount: 10,
        );

        expect(result.path.role, equals(Bip32KeyRole.change));
        expect(result.path.address, equals(0));
        expect(
          result.publicKeyBytes.hexEncode(),
          equals("4c1433229057a92a6044a3f67ef8a14b18d259310d37b9686c7b100810d7fb7d"),
        );
      });

      test("finds change address at index 2 - hex", () async {
        const changeAddrHex =
            "0047700c261347a8bd3d4bc68d374aeee2c05228d0d5fa013cabddb156272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: changeAddrHex,
          deriveMaxAddressCount: 10,
        );

        expect(result.path.role, equals(Bip32KeyRole.change));
        expect(result.path.address, equals(2));
        expect(
          result.publicKeyBytes.hexEncode(),
          equals("0b0db6a08ce0a00cc0a1aab567f4c268bad14d134de919596a77d027b9dc4c31"),
        );
      });

      test("throws when address index exceeds deriveMaxAddressCount", () async {
        // Use payment address at index 2, but only allow derivation up to index 2
        const paymentAddr =
            "addr_test1qpd374uyj78w0yagc5h2he40dftnc2supf3n57m6csrl35e8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qpy7wrk";

        await expectLater(
          WalletTasksSign.findCardanoSigner(
            pubAccount: pubAccount,
            requestedSignerRaw: paymentAddr,
            deriveMaxAddressCount: 2, // Only derive up to index 1
          ),
          throwsA(isA<SigningAddressNotFoundException>()),
        );
      });

      test("finds address within deriveMaxAddressCount limit", () async {
        // Same address but with sufficient derivation count
        const paymentAddr =
            "addr_test1qpd374uyj78w0yagc5h2he40dftnc2supf3n57m6csrl35e8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qpy7wrk";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: paymentAddr,
          deriveMaxAddressCount: 10, // Sufficient to find index 2
        );

        expect(result.path.role, equals(Bip32KeyRole.payment));
        expect(result.path.address, equals(2));
      });

      test("throws for non-existent base address", () async {
        // Invalid base address that doesn't belong to this wallet
        const invalidAddr =
            "addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3n0d3vllmyqwsx5wktcd8cc3sq835lu7drv2xwl2wywfgs68faae";

        await expectLater(
          WalletTasksSign.findCardanoSigner(
            pubAccount: pubAccount,
            requestedSignerRaw: invalidAddr,
            deriveMaxAddressCount: 10,
          ),
          throwsA(isA<SigningAddressNotFoundException>()),
        );
      });
    });

    group("mainnet addresses", () {
      test("finds mainnet payment address", () async {
        const mainnetPaymentAddr =
            "addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: mainnetPaymentAddr,
          deriveMaxAddressCount: 10,
        );

        expect(result.path.role, equals(Bip32KeyRole.payment));
        expect(result.path.address, equals(0));
        expect(
          result.publicKeyBytes.hexEncode(),
          equals("acb1c00cbfdcb5d79915d27cca0b8566646d1e0b86e61c67a1bcd289e6e2a938"),
        );
        expect(
          result.requestedSignerBytes.hexEncode(),
          equals(
            "01E53A24B2FBEEEF3BC3ADC55622092CC8C172FAD61C231D1358E5F023272D0B87FB7B9561D4D3DEE46B8D422A8A8EC555C514E2B15F072934"
                .toLowerCase(),
          ),
        );
      });

      // NOTE: Currently failing tests
      // TESTS ARE CORRECT BUT LOGIC IS NOT IMPLEMENTED
      group("finds mainnet enterprise address", () {
        final testCases = {
          "bech32": "addr1v8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqgcvfr3f7",
          "hex": "addr1v8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqgcvfr3f7".bech32ToHex(),
        };

        for (final entry in testCases.entries) {
          final testName = entry.key;

          test(testName, () async {
            final mainnetEnterpriseAddr = entry.value;
            final result = await WalletTasksSign.findCardanoSigner(
              pubAccount: pubAccount,
              requestedSignerRaw: mainnetEnterpriseAddr,
              deriveMaxAddressCount: 10,
            );

            expect(result.path.role, equals(Bip32KeyRole.payment));
            expect(result.path.address, equals(0));
            expect(
              result.publicKeyBytes.hexEncode(),
              equals("acb1c00cbfdcb5d79915d27cca0b8566646d1e0b86e61c67a1bcd289e6e2a938"),
            );
            expect(
              result.requestedSignerBytes.hexEncode(),
              equals(
                "61E53A24B2FBEEEF3BC3ADC55622092CC8C172FAD61C231D1358E5F023".toLowerCase(),
              ),
            );
          });
        }
      });

      test("finds mainnet stake address", () async {
        const mainnetStakeAddr = "stake1uynj6zu8ldae2cw5600wg6udgg4g4rk92hz3fc43turjjdq0dhd6t";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: mainnetStakeAddr,
          deriveMaxAddressCount: 10,
        );

        expect(result.path.role, equals(Bip32KeyRole.staking));
        expect(result.path.address, equals(0));
        expect(
          result.publicKeyBytes.hexEncode(),
          equals("a637d4e865c8a12c4797f4b0a9c79a33a33c3b9b58afb20cc486591fd34e150a"),
        );
      });
    });

    group("unsupported address types", () {
      test("throws for Byron address", () async {
        // Byron addresses have different structure and aren't supported
        // Using a 130-byte Byron address (260 hex chars)
        final byronHex = "82d818582183581c${'0' * 244}"; // Simplified Byron address pattern

        await expectLater(
          WalletTasksSign.findCardanoSigner(
            pubAccount: pubAccount,
            requestedSignerRaw: byronHex,
            deriveMaxAddressCount: 10,
          ),
          throwsA(isA<SigningAddressNotValidException>()),
        );
      });

      test("throws for Enterprise address not belonging to wallet", () async {
        // Enterprise address (type 6 or 7) - 29 bytes = 58 hex chars (not 114)
        // Using type 6 (key hash) enterprise address for testnet that doesn't belong to wallet
        const enterpriseHex = "60dd5fba0222e5a11fd1979c4cc7a1ee88ff7a6c0ead5cb62d008a72dd";

        await expectLater(
          WalletTasksSign.findCardanoSigner(
            pubAccount: pubAccount,
            requestedSignerRaw: enterpriseHex,
            deriveMaxAddressCount: 10,
          ),
          throwsA(isA<SigningAddressNotFoundException>()),
        );
      });

      test("throws for Pointer address", () async {
        // Pointer address (type 4 or 5) - variable length, using 58 hex chars
        // Using type 4 (key hash) pointer address for testnet
        const pointerHex = "40dd5fba0222e5a11fd1979c4cc7a1ee88ff7a6c0ead5cb62d008a72dd";

        await expectLater(
          WalletTasksSign.findCardanoSigner(
            pubAccount: pubAccount,
            requestedSignerRaw: pointerHex,
            deriveMaxAddressCount: 10,
          ),
          throwsA(isA<UnexpectedSigningAddressTypeException>()),
        );
      });
    });

    group("invalid input validation", () {
      test("throws for invalid hex length", () async {
        // Invalid hex lengths that aren't 56, 58, or 114
        final invalidLengths = [
          "abcd", // 4 chars
          "0" * 10, // 10 chars
          "0" * 55, // 55 chars
          "0" * 57, // 57 chars
          "0" * 60, // 60 chars
          "0" * 113, // 113 chars
          "0" * 115, // 115 chars
          "0" * 200, // 200 chars
        ];

        for (final invalidHex in invalidLengths) {
          await expectLater(
            WalletTasksSign.findCardanoSigner(
              pubAccount: pubAccount,
              requestedSignerRaw: invalidHex,
              deriveMaxAddressCount: 10,
            ),
            throwsA(isA<SigningAddressNotValidException>()),
            reason: "Should throw for hex length ${invalidHex.length}",
          );
        }
      });

      test("handles mixed case hex input", () async {
        // Some systems might provide hex in mixed case
        const stakeHexLower = "e1272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934";
        final stakeHexUpper = "e1272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934".toUpperCase();
        const stakeHexMixed = "E1272d0b87fb7b9561d4d3DEE46b8d422a8a8ec555c514e2b15F072934";

        for (final hexVariant in [stakeHexLower, stakeHexUpper, stakeHexMixed]) {
          final result = await WalletTasksSign.findCardanoSigner(
            pubAccount: pubAccount,
            requestedSignerRaw: hexVariant,
            deriveMaxAddressCount: 10,
          );

          expect(result.path.role, equals(Bip32KeyRole.staking));
        }
      });
    });

    group("CardanoSigner properties", () {
      test("correctly sets publicKeyBytes", () async {
        const paymentAddr =
            "addr_test1qpd374uyj78w0yagc5h2he40dftnc2supf3n57m6csrl35e8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qpy7wrk";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: paymentAddr,
          deriveMaxAddressCount: 10,
        );

        expect(result.publicKeyBytes, isA<ByteList>());
        expect(result.publicKeyBytes.length, equals(32));
        expect(
          result.publicKeyBytes.hexEncode(),
          equals("a308059c42e60b79353546fa4e93bc860e744cb27cbb1f35a3527bf3908b4282"),
        );
      });

      test("correctly sets requestedSignerBytes", () async {
        const stakeHex = "e1272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: stakeHex,
          deriveMaxAddressCount: 10,
        );

        expect(result.requestedSignerBytes.hexEncode(), equals(stakeHex));
      });

      test("preserves original input in requestedSignerBytes for bech32", () async {
        const stakeBech32 = "stake_test1uqnj6zu8ldae2cw5600wg6udgg4g4rk92hz3fc43turjjdqg8a07k";

        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: stakeBech32,
          deriveMaxAddressCount: 10,
        );

        // The requestedSignerBytes should be the decoded version of the original input
        expect(result.requestedSignerBytes.hexEncode(), equals(stakeBech32.bech32ToHex()));
      });
    });

    group("edge cases", () {
      test("handles deriveMaxAddressCount of 1", () async {
        const paymentAddr =
            "addr_test1qrjn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qhkdw7e";

        // Should still find index 0 when deriveMaxAddressCount is 1 (derives 0)
        final result = await WalletTasksSign.findCardanoSigner(
          pubAccount: pubAccount,
          requestedSignerRaw: paymentAddr,
          deriveMaxAddressCount: 1, // Will check index 0
        );

        expect(result.path.address, equals(0));
      });

      test("handles large deriveMaxAddressCount", () async {
        // This should not find the address and should not hang
        const nonExistentAddr =
            "addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3n0d3vllmyqwsx5wktcd8cc3sq835lu7drv2xwl2wywfgs68faae";

        final stopwatch = Stopwatch()..start();

        await expectLater(
          WalletTasksSign.findCardanoSigner(
            pubAccount: pubAccount,
            requestedSignerRaw: nonExistentAddr,
            deriveMaxAddressCount: 100, // Large number
          ),
          throwsA(isA<SigningAddressNotFoundException>()),
        );

        stopwatch.stop();
        // Should complete in reasonable time (< 5 seconds even for 1000 addresses)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });
    });
  });
}
