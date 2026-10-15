# prepareTxsForSigning: fix the real bugs from closed PR #3 in small, reviewable steps

Replaces [cardano_dart_sdk PR #3](https://github.com/vespr-wallet/cardano_dart_sdk/pull/3)
(`deep-review-prepare-txs-for-signing`, closed 2026-10-15). That PR mixed four small bug fixes with a
new ownership API, a batch validator, CBOR snapshotting and a deprecation. This plan keeps the bug
fixes, lands two of them at their source in `cardano_dart_types`, and drops the rest.

Both repositories are owned by the same team, so steps span both:

- `cardano_dart_types` at `~/FlutterProjects/cardano_dart_types` (published 3.1.0)
- `cardano_dart_sdk` (this repo, package `cardano_flutter_sdk`, published 5.0.0)

## Goal

A wallet calling `SigningUtils.prepareTxsForSigning` gets a correct per-transaction and total diff,
correct deregistration flags, and correct required signing addresses for:

1. inputs whose CBOR hash encoding carries tags or a different length type than the wallet's UTxO;
2. transactions where a stake or DRep deregistration certificate is followed by another certificate;
3. transactions flagged `isValidDi == false` (phase-2 failure: collateral is consumed, nothing else
   happens), including batches that chain through such a transaction.

No public API changes. No new worker parameters.

## Current behavior

**SDK worker loop** (`lib/workers/wallet_tasks.dart`, `prepareTxsForSigningImpl`):

- Builds UTxO keys as `"${e.transactionHash}#${e.index}"`. `TransactionHash` is a freezed class with
  `value`, `lengthType` and `cborTags`, so the key is its `toString()` and includes CBOR metadata. A
  wallet UTxO built with `TransactionHash.fromHex` (definite, no tags) never matches a parsed input
  that carries a tag or an indefinite length. Result: the signing address is missed (missing witness)
  and the UTxO is not removed for the next transaction in the batch. `cardano_dart_types` already
  fixed this class of bug inside `diff()` (test "correctly matches UTXOs by transaction hash"); the
  worker loop was not updated.
- Treats every transaction as valid: consumes `body.inputs`, adds outputs to the receive address as new
  wallet UTxOs. For `isValidDi == false` the ledger instead consumes the collateral inputs and creates
  only the collateral return output at index `outputs.length`.
- `signingAddressesRequired` already includes collateral inputs. That is correct and stays.

**`cardano_dart_types` `diff()`** (`lib/src/cardano/transaction.dart`):

- `dRepDeregistration` and `stakeDeregistration` are computed with
  `certificates.map(...).nonNulls.lastOrNull ?? false`. The map yields `false` for unrelated
  certificates and `nonNulls` keeps `false`, so the last certificate decides. A deregistration followed
  by any other certificate (stake deregistration then DRep unregister is an ordinary "retire" pattern)
  reads as `false`, and the wallet does not warn the user.
- `diff()` never reads `isValidDi`. For an invalid transaction it reports the regular inputs as spent
  and the regular outputs as received, which is the opposite of what happens on chain. A dApp can
  present a generous-looking body with `isValid = false` and the wallet would show it as a gain while
  the collateral is lost.

**Consumer**: VESPR (`nft-craze-wallet`) calls `prepareTxsForSigning` once per signing request with
the wallet's UTxOs and its single receive address, and catches any error generically. It is pinned to
SDK 4.0.1+1 today and will pick these fixes up when it moves to 5.x.

## Design

Fix at the narrowest owner. `diff()` owns the per-transaction value and certificate semantics, so the
deregistration and `isValidDi` fixes go there. The worker loop owns UTxO chaining and signing
addresses, so the key fix and the collateral transition go there.

### `diff()` deregistration flags (step 2)

Replace both `.map(...).nonNulls.lastOrNull ?? false` expressions with `.any(...)` over the same
`switch`. Nothing else changes. The SDK already aggregates per-transaction flags with `.any`.

### `diff()` for `isValidDi == false` (step 3)

When `isValidDi` is false:

- `outgoing` = sum of the values of `body.collateral` inputs found in `walletUtxos` (matched by hash
  hex and index, as `inputs` are today). Withdrawals are not applied.
- `incoming` = `body.collateralReturn.value` when its address bytes equal the receive address, else
  zero.
- `usedUtxos` = those wallet-owned collateral inputs.
- `stakeDelegationPoolId`, `dRepDelegation`, `dRepRegistration`, `dRepUpdate`,
  `authorizeConstitutionalCommitteeHot`, `resignConstitutionalCommitteeCold` = `null`;
  `votes`, `proposals` = empty; both deregistration flags = `false`. None of the body takes effect on
  chain except the collateral.

When `isValidDi` is true, behavior is byte-for-byte what it is today. Implement as one early branch at
the top of `diff()` that builds the invalid-transaction `TxDiff` and returns, so the valid path is not
touched.

### Worker UTxO keys (step 4)

Use `"${e.transactionHash.hexValue}#${e.index}"` in the three places that build keys. Same key shape
as `diff()`.

### Worker chaining through invalid transactions (step 6)

Inside the loop, branch on `tx.isValidDi`:

- valid: consumed = `body.inputs` (as today); generated = outputs to the receive address (as today).
- invalid: consumed = `body.collateral` inputs; generated = `collateralReturn` as a UTxO at index
  `body.outputs.length` when its address is the receive address, else nothing.

`signingAddressesRequired` keeps using inputs plus collateral for both cases (witnesses are checked in
phase 1 for the whole body). `utxosBeforeTx` keeps its meaning.

## Steps (fixed order and total: 7)

PR titles use `<emoji> [signing-prep-fixes] <description> [step x/7]`. Steps 2 and 3 are in
`cardano_dart_types`; the rest are in this repo. Step 4 is independent of steps 2, 3 and 5 and may be
opened and merged in parallel with them.

| Step | Repo | Title | Depends on | Status |
| --- | --- | --- | --- | --- |
| 1 | sdk | 🌱 [signing-prep-fixes] Add plan for prepareTxsForSigning fixes [step 1/7] | - | open |
| 2 | types | 🌿 [signing-prep-fixes] diff(): deregistration flags survive later certificates [step 2/7] | - | todo |
| 3 | types | ⚙️ [signing-prep-fixes] diff(): honor isValidDi == false, release 3.1.1 [step 3/7] | 2 | todo |
| 4 | sdk | 🌿 [signing-prep-fixes] Worker: match UTxOs by hash hex and index [step 4/7] | 1 | todo |
| 5 | sdk | 🌿 [signing-prep-fixes] Bump cardano_dart_types to 3.1.1 [step 5/7] | 3 published | todo |
| 6 | sdk | ⚙️ [signing-prep-fixes] Worker: invalid transactions consume collateral when chaining [step 6/7] | 4, 5 | todo |
| 7 | sdk | 🌱 [signing-prep-fixes] Regenerate web workers and release 5.0.1 [step 7/7] | 6 | todo |

Publishing to pub.dev (after step 3 and after step 7) is done by a human, not by the plan worker.

### Step 1: this plan (sdk, 🌱)

- **What:** adds `.plan/active/signing-prep-fixes/PLAN.md`. No code.
- **Why:** gives reviewers the full roadmap before any logic changes.
- **Risk and test focus:** none.
- **Expected result:** no user-visible or database change; plan file present on `main`.

### Step 2: `diff()` deregistration flags (types, 🌿)

- **Files:** `lib/src/cardano/transaction.dart` (two expressions), `test/transaction_test.dart`
  (`diff` group), `CHANGELOG.md` under an unreleased 3.1.1 heading.
- **Tests:** wallet stake deregistration followed by an unrelated certificate reads `true`; DRep
  unregister followed by an unrelated certificate reads `true`; only unrelated certificates reads
  `false`; another credential's deregistration reads `false`. Use `txBody(certs: ...)` from
  `test/test_utils/fixtures.dart` with the existing wallet address constants in the `diff` group.
- **Why:** the flags drive the wallet's deregistration warning.
- **Risk and test focus:** low; only the two boolean fields change, from last-wins to any-match.
- **Expected result:** no user-visible change for single-certificate transactions; multi-certificate
  transactions with a wallet deregistration now flag it. No database change.

### Step 3: `diff()` honors `isValidDi == false`, release 3.1.1 (types, ⚙️)

- **Files:** `lib/src/cardano/transaction.dart` (early branch), `test/transaction_test.dart`,
  `pubspec.yaml` version `3.1.1`, `CHANGELOG.md`.
- **Tests:** invalid transaction with wallet collateral and a collateral return to the wallet gives
  `diff = return - collateral`, `usedUtxos` = the collateral inputs, all governance fields empty, even
  when the body also carries regular wallet inputs, outputs, withdrawals and certificates; invalid
  transaction whose collateral is not the wallet's gives a zero diff; a valid transaction with
  collateral is unchanged (existing tests cover it).
- **Why:** the wallet must show collateral loss, not the decoy body.
- **Risk and test focus:** moderate; new branch in the function every signing flow passes through.
  Focus on the valid path staying identical (run the whole `diff` group) and on collateral matching
  by hash hex.
- **Expected result:** transactions with `isValid = false` show the collateral delta; everything else
  identical. No database change.
- **Publish:** after merge, a human runs `dart pub publish` for 3.1.1.

### Step 4: worker UTxO keys (sdk, 🌿)

- **Files:** `lib/workers/wallet_tasks.dart` (three string keys), `test/prepare_sign_tx_test.dart`.
- **Tests:** a batch whose first transaction input carries `TransactionHash(value: ..., cborTags:
  [64])` for a wallet UTxO built with `TransactionHash.fromHex`: the signing address set contains the
  UTxO's address, and a second transaction can no longer see that UTxO in `utxosBeforeTx`. Mirror the
  existing "correctly matches UTXOs by transaction hash" test in `cardano_dart_types`.
- **Why:** missed match means a missing witness and a stale UTxO set for the next transaction.
- **Risk and test focus:** low; key format only. Run the full `prepare_sign_tx_test.dart`.
- **Expected result:** no change for inputs encoded without tags; tagged or indefinite inputs now
  match. No database change. No regenerated worker files (no signature change).

### Step 5: bump `cardano_dart_types` to 3.1.1 (sdk, 🌿)

- **Files:** `pubspec.yaml` pin `3.1.1`, `pubspec.lock`, `test/prepare_sign_tx_test.dart`.
- **Tests:** one batch where a transaction has a wallet stake deregistration followed by an unrelated
  certificate; `bundle.stakeDeregistration` is `true`. Proves the step 2 fix through the SDK boundary.
- **Why:** picks up steps 2 and 3; step 6 tests assert values that depend on the new `diff()`.
- **Risk and test focus:** low; the whole existing suite runs against the new version in CI.
- **Expected result:** no user-visible change beyond step 2 and 3 behavior. Web worker artifacts on
  `main` are stale from this step until step 7; `main` is not published in between.

### Step 6: worker chaining through invalid transactions (sdk, ⚙️)

- **Files:** `lib/workers/wallet_tasks.dart` (branch on `tx.isValidDi` for consumed and generated
  UTxOs), `test/prepare_sign_tx_test.dart` (extend `gentx` or add a sibling helper that accepts
  `collateral`, `collateralReturn` and `isValidDi`).
- **Tests:** batch `[invalid tx with wallet collateral and a return to the wallet, valid tx spending
  that return]`: the second transaction's signing address is found, `utxosBeforeTx` of the second
  transaction contains the return and not the collateral, and `totalDiff` equals the sum of the two
  per-transaction diffs; batch `[invalid tx with a regular wallet input, valid tx spending that same
  input]`: the input is still available to the second transaction.
- **Why:** without it a batch that chains through an invalid transaction mis-reports signing
  addresses and the running UTxO set.
- **Risk and test focus:** moderate; the loop every batch goes through. Focus on the valid path being
  unchanged (full `prepare_sign_tx_test.dart`) and on index `outputs.length` for the return.
- **Expected result:** batches with only valid transactions unchanged; invalid transactions chain
  through collateral. No database change. No regenerated worker files.

### Step 7: regenerate web workers, release 5.0.1 (sdk, 🌱)

- **Commands:** `dart run build_runner build --delete-conflicting-outputs` (expected no-op diff),
  `sh ./scripts/gen_js_workers.sh`.
- **Files:** regenerated `lib/workers/wallet_tasks.web.g.dart.js`, `.mjs`, `.wasm`, loader;
  `pubspec.yaml` version `5.0.1`; `CHANGELOG.md` 5.0.1 section (fixes from steps 4 and 6, bump to
  types 3.1.1 with its two fixes); move this directory to `.plan/completed/signing-prep-fixes/`.
- **Reviewer check:** rerun the two commands on the branch and confirm a clean tree.
- **Why:** web builds embed the worker and `cardano_dart_types` code; nothing above reaches the web
  extension until this step.
- **Risk and test focus:** low in logic, mechanical in size. Run the verification matrix below.
- **Expected result:** web extension behavior matches VM behavior for all three fixes.
- **Publish:** after merge, a human runs `dart pub publish` for 5.0.1.

## Verification

Neither repository has `docs/regression/`; this section is the recorded coverage.

- **Level.** Unit tests through the public boundary: `diff()` in `cardano_dart_types`, and
  `SigningUtils.prepareTxsForSigning` in the SDK, which dispatches to the squadron worker (VM
  isolate under `dart test`). Every delivered behavior is asserted at that boundary.
- **Every step:** `flutter analyze --no-fatal-infos` and `dart test` (what CI runs on pull requests).
- **Matrix (step 7 only, local, CI has these commented out):** `dart test -P js` and
  `dart test -P wasm` in the SDK, so the regenerated dart2js and dart2wasm workers execute the same
  suites. If either preset cannot run locally, record why in this file before retiring the plan.

## Risks, decisions, evidence

**Evidence level.**

- Keys with CBOR metadata: deterministic, same bug class already fixed and tested in
  `cardano_dart_types`; the worker loop was missed. Needs a tagged or indefinite-length input, which
  valid CBOR allows and the SDK parses.
- Deregistration flags: deterministic, ordinary reachable flow (any wallet deregistration followed by
  another certificate in one transaction).
- Invalid transactions: reachable from any dApp signing request with `isValid = false`. No observed
  incident; the impact is a wrong balance preview on a security-sensitive screen.

**Decisions.**

- **Dropped: chained outputs at other wallet addresses** (PR #3 "tracks chained outputs sent to every
  known wallet address"). VESPR exposes exactly one address (`getUsedAddresses` returns the receive
  address; nothing derives change addresses) and `diff()` credits incoming value to the receive
  address only. Fixing chaining alone would double count for a multi-address UTxO set (the first
  transaction reports the output as lost, the second reports it as spent). Multi-address support is a
  feature: define wallet-owned addresses once (receive address plus the addresses of the supplied
  UTxOs) and apply it to both `diff()` incoming and worker chaining. Not planned here.
- **Dropped: ownership API, batch validator, CBOR snapshotting, deprecation.** No consumer can supply
  resolved addresses, the validator rejected previously accepted batches inside the existing method,
  and the snapshot doubled parsing to guard against a caller mutating its own lists. The ledger
  rejects double spends and forward references regardless. Not planned.
- **Fix at the source.** Deregistration and `isValidDi` semantics live in `diff()`, not as SDK
  workarounds reconstructing `TxDiff`.
- **No new worker parameters**, so `wallet_tasks.*.g.dart` are untouched and web artifacts are
  regenerated once, in step 7.
- **Versions.** 3.1.0 and 5.0.0 are both already on pub.dev, so the fixes ship as 3.1.1 and 5.0.1.
- **Open CodeRabbit note from PR #3** (eager `drepCredential.hexDecode()`): not applicable, that
  code is not being ported.

**Accepted risks.**

- Between steps 5 and 7, `main` of the SDK has web worker artifacts older than its Dart source. No
  release happens in that window.
- `diff()` for invalid transactions ignores `totalCollateral`; the actual collateral inputs are the
  authoritative amount and the wallet owns those UTxOs, so the field adds nothing.

## Complexity budget

- **New persistent state:** none.
- **New in-memory state:** none. The worker loop keeps its two local lists; `diff()` gains one early
  branch.
- **New config, flags, parameters, public types:** none.
- **Deliberately not added:** a `UtxoId` value type (string keys with hash hex are enough and match
  `diff()`), the ownership model, the batch validator, caller-input snapshots.

## Cleanup

No code on `main` is made obsolete by this plan. The closed PR's remote branch
`deep-review-prepare-txs-for-signing` can be deleted at any time; its content is in Git history.
