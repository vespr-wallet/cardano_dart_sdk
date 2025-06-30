import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:test/test.dart";

void main() async {
  const mnemonic =
      "chief fiber betray curve tissue output feature jungle adapt smile brown crane accuse gospel plate unlock pull arrow hard february tape soccer patrol fetch";

  final wallet = await WalletFactory.fromMnemonic(NetworkId.testnet, mnemonic.split(" "));

  final pubAccount = await wallet.cardanoPubAccount();

  test("xpub bech32 and hex are the same for sync and async factories", () async {
    // xpub in bech and hex for same wallet
    const xPubBech32 =
        "xpub1hfku0gtwhnla0gpf4r6nfl5zdu3fm64qnc5v74yw2mw0sqa8rzdv7j0d9x5rjfaay0levhrfq3en7q2u4nerrq6uxtmkpcp8fhlsq5sl4m0w6";
    const xPubHex =
        "ba6dc7a16ebcffd7a029a8f534fe826f229deaa09e28cf548e56dcf803a7189acf49ed29a83927bd23ff965c6904733f015cacf231835c32f760e0274dff0052";

    final walletAccountFromHex = await CardanoPubAccountFactory.instanceSync.fromHexXPub(xPubHex);
    final walletAccountFromBech = await CardanoPubAccountFactory.instanceSync.fromBech32XPub(xPubBech32);

    final walletAccountFromHexAsync = await CardanoPubAccountWorkerFactory.instance.fromHexXPub(xPubHex);
    final walletAccountFromBechAsync = await CardanoPubAccountWorkerFactory.instance.fromBech32XPub(xPubBech32);

    // sync = async
    expect(walletAccountFromHex, equals(walletAccountFromHexAsync));
    expect(walletAccountFromBech, equals(walletAccountFromBechAsync));

    // hex sync = bech sync
    expect(walletAccountFromHex, equals(walletAccountFromBech));

    // hex async = bech async
    expect(walletAccountFromHexAsync, equals(walletAccountFromBechAsync));
  });

  group("spend addresses", () {
    test("0 index - testnet receive address", () async {
      expect(
        await pubAccount.paymentBech32Address(0, NetworkId.testnet),
        "addr_test1qrjn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qhkdw7e",
      );
    });
    test("0 index - mainnet receive address", () async {
      expect(
        await pubAccount.paymentBech32Address(0, NetworkId.mainnet),
        "addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx",
      );
    });
    test("1 index - testnet receive address", () async {
      expect(
        await pubAccount.paymentBech32Address(1, NetworkId.testnet),
        "addr_test1qq54j5r58k7z4u9hlxqv54kq675s0q98rn3439pnuv60lhf8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q6traa6",
      );
    });
    test("5 index - testnet receive address", () async {
      expect(
        await pubAccount.paymentBech32Address(5, NetworkId.testnet),
        "addr_test1qqhxwcdvsszr9fhqwstau36hmvzpf4gn8wqyt8zu7s50yfe8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qeh4zgd",
      );
    });
  });

  group("change addresses", () {
    test("0 index - testnet change address", () async {
      expect(
        await pubAccount.changeBech32Address(0, NetworkId.testnet),
        "addr_test1qqcyp2gry5xe8wlhqjlwr7gydz6x5n9px387np4n8g4axte8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qf9p9tq",
      );
    });
    test("0 index - mainnet change address", () async {
      expect(
        await pubAccount.changeBech32Address(0, NetworkId.mainnet),
        "addr1qycyp2gry5xe8wlhqjlwr7gydz6x5n9px387np4n8g4axte8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q2nu98l",
      );
    });
    test("1 index - testnet change address", () async {
      expect(
        await pubAccount.changeBech32Address(1, NetworkId.testnet),
        "addr_test1qzezquuv400k6jp86u2f7w9l9reukh6lh820szaeq9c4wn38959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qf2pvax",
      );
    });
    test("5 index - testnet change address", () async {
      expect(
        await pubAccount.changeBech32Address(5, NetworkId.testnet),
        "addr_test1qq64f2fz2ahrfvne4ddpt696jpf9etw4zz3y7u2nsvqyrt38959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qgrcn29",
      );
    });
  });

  group("stake address", () {
    test("testnet stake address", () async {
      expect(
        await pubAccount.stakeAddress(NetworkId.testnet),
        "stake_test1uqnj6zu8ldae2cw5600wg6udgg4g4rk92hz3fc43turjjdqg8a07k",
      );
    });
    test("mainnet stake address", () async {
      expect(
        await pubAccount.stakeAddress(NetworkId.mainnet),
        "stake1uynj6zu8ldae2cw5600wg6udgg4g4rk92hz3fc43turjjdq0dhd6t",
      );
    });
  });

  test("stake key hex", () async {
    expect(
      pubAccount.stakeDerivation.value.keyHex,
      "a637d4e865c8a12c4797f4b0a9c79a33a33c3b9b58afb20cc486591fd34e150a",
    );
  });

  test("drep key hex", () async {
    expect(
      pubAccount.dRepDerivation.value.dRepKeyHex,
      "320b0744172502cec5a5984a4431d62ea8a3896a8d570ac517afeecac66f3b85",
    );
  });

  test("constitutional committee cold key hex", () async {
    expect(
      pubAccount.constitutionalCommitteeColdDerivation.value.hexCCKey,
      "2f5e3315fffac94a496a41767651dced59a7e8c707ea63b2dff9c908fde4f0ef",
    );
  });

  test("constitutional committee hot key hex", () async {
    expect(
      pubAccount.constitutionalCommitteeHotDerivation.value.hexCCKey,
      "2e121a022a0bd77d78b0c5c7b2dbbcd93b8c1a610db685357892990bafe6705b",
    );
  });
}
