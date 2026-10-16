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
3. transactions flagged `isValidDi == false`: refused before signing, because the flag is not part of
   the signed body and can be switched after signing, so no pre-sign summary of such a transaction can
   be trusted. `diff()` still offers the on-chain summaries behind explicitly dangerous options for
   transactions already in a block.

No API breaks. New in `cardano_dart_types`: an optional `diff()` parameter, the `TxDiManagement` enum
and `TransactionMarkedInvalidException`. No new worker parameters.

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
addresses, so the key fix goes there; it passes the safe `diff()` option explicitly.

### `diff()` deregistration flags (step 3)

Keep the last-certificate idea but make it apply only to certificates that change the wallet
credential's registration: registrations of the wallet credential map to `false`, deregistrations to
`true`, everything else to `null` (skipped by `nonNulls`). The last non-null value is the flag, so
order follows the ledger: deregistration then re-registration in one transaction reads `false`,
registration then deregistration reads `true`, and a trailing certificate of another credential no
longer resets the flag. A plain `.any(...)` was considered and rejected because it over-reports the
re-registration case (user feedback on the step 3 PR).

### `diff()` for `isValidDi == false` (step 4)

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

Shipped as 3.1.1 and then retracted: this describes the on-chain effect of a transaction that carries
the flag, but before signing the flag cannot be trusted (see step 6). The computation survives as the
`dangerouslyAssumeOnlyCollateralBurnOnInvalidDi` option.

### Worker UTxO keys (step 5)

Use `"${e.transactionHash.hexValue}#${e.index}"` in the three places that build keys. Same key shape
as `diff()`.

### `diff()` refuses transactions marked invalid by default (step 6)

`isValid` is the third element of the transaction envelope, not part of the body, and vkey witnesses
sign the blake2b-256 hash of the body only. Whoever holds a signed transaction can switch the flag
without breaking any signature, so a requester can present a transaction as failing phase-2 validation
(collateral-only summary), obtain the signatures, flip the flag and submit the full body (Codex
security finding on SDK PR #10). The guard goes where the summary is computed, with a safe default, so
no consumer can obtain an unsafe summary by accident:

- `diff()` gains `txDiManagement` (`TxDiManagement`, default `safeAlwaysReject`): a transaction with
  `isValidDi == false` throws `TransactionMarkedInvalidException` (body hash in the message).
- `dangerouslyAssumeTrue` summarises the body as if the flag were true (behaviour up to 3.1.0);
  `dangerouslyAssumeOnlyCollateralBurnOnInvalidDi` is the collateral-only summary of 3.1.1. Both are
  documented as appropriate only for transactions already on chain, where the flag is authoritative.
- Valid transactions are summarised identically under every option.

### Worker passes the safe option explicitly (step 7)

The worker calls `diff()` with `txDiManagement: TxDiManagement.safeAlwaysReject` and a comment stating
why, so the SDK's policy is visible at the call site rather than inherited from a default. The
exception thrown inside the squadron worker reaches callers as a `WorkerException` carrying its
message, like the other signing exceptions. The former step 7 design (chain invalid transactions
through their collateral inside the loop) is dropped: no transaction marked invalid completes the
loop.

### Versions and changelog

- `cardano_dart_types` ships as 3.1.2, `cardano_flutter_sdk` as 5.1.0. 5.0.0 is already published
  and nothing here breaks an API, so it stays published. 3.1.1 was published and then retracted (its
  collateral-only summary is unsafe before signing); its changelog heading is marked `(retracted)`.
- Version bumps land first, not in a release PR at the end: step 2 bumps the SDK to 5.1.0 and opens
  the `## 5.1.0` changelog heading; step 3 opens the `## 3.1.1` heading in `cardano_dart_types`, step 4
  bumps its version and step 6 opens `## 3.1.2` and bumps again.
- Every later PR adds its own line to the open heading (`### Fix` or `### Change`, created on first
  use). The final step only refreshes the "Web workers built with" line. No PR writes someone else's
  changelog entry.

## Steps (fixed order and total: 8)

PR titles use `<emoji> [signing-prep-fixes] <description> [step x/8]`. Steps 3, 4 and 6 are in
`cardano_dart_types`; the rest are in this repo. Steps 2 and 5 are independent of the
`cardano_dart_types` steps and may be opened and merged in parallel with them.

| Step | Repo | Title | Depends on | Status |
| --- | --- | --- | --- | --- |
| 1 | sdk | 🌱 [signing-prep-fixes] Add plan for prepareTxsForSigning fixes [step 1/8] | - | merged (#7, titled `[step 1/7]` before the series grew) |
| 2 | sdk | 🌱 [signing-prep-fixes] Bump to 5.1.0 and open the changelog [step 2/8] | 1 | merged (#8) |
| 3 | types | 🌿 [signing-prep-fixes] diff(): deregistration flags survive later certificates [step 3/8] | - | merged (cardano_dart_types #4) |
| 4 | types | ⚙️ [signing-prep-fixes] diff(): honor isValidDi == false, release 3.1.1 [step 4/8] | 3 | merged (cardano_dart_types #5); 3.1.1 published, then retracted |
| 5 | sdk | 🌿 [signing-prep-fixes] Worker: match UTxOs by hash hex and index [step 5/8] | 2 | open (#9) |
| 6 | types | 🌿 [signing-prep-fixes] diff(): refuse transactions marked invalid by default, release 3.1.2 [step 6/8] | 4 | merged (cardano_dart_types #6); 3.1.2 published |
| 7 | sdk | 🌿 [signing-prep-fixes] Bump cardano_dart_types to 3.1.2; signing prep refuses transactions marked invalid [step 7/8] | 2, 6 published | open (#10, opened as "Bump cardano_dart_types to 3.1.1 [step 6/8]" before the rework) |
| 8 | sdk | 🌱 [signing-prep-fixes] Regenerate web workers and finish 5.1.0 [step 8/8] | 5, 7 | todo |

Publishing to pub.dev (after steps 4, 6 and 8) is done by a human, not by the plan worker.

### Step 1: this plan (sdk, 🌱)

- **What:** adds `.plan/active/signing-prep-fixes/PLAN.md`. No code.
- **Why:** gives reviewers the full roadmap before any logic changes.
- **Risk and test focus:** none.
- **Expected result:** no user-visible or database change; plan file present on `main`.

### Step 2: bump to 5.1.0 and open the changelog (sdk, 🌱)

- **Files:** `pubspec.yaml` version `5.1.0`; `CHANGELOG.md` gains a `## 5.1.0` heading with the
  current "Web workers built with" line; this plan updated for the 8-step series.
- **Why:** 5.0.0 is released. Bumping first lets each fix PR append its own changelog line.
- **Risk and test focus:** none; `main` is not published between steps.
- **Expected result:** no user-visible or database change. `pubspec.yaml` reads 5.1.0 and the
  changelog has an empty 5.1.0 section for later steps to fill.

### Step 3: `diff()` deregistration flags (types, 🌿)

- **Files:** `lib/src/cardano/transaction.dart` (two expressions), `test/transaction_test.dart`
  (`diff` group), `CHANGELOG.md` with a new `## 3.1.1` heading and this fix under `Bug Fix`.
- **Tests:** wallet stake deregistration (Conway and legacy) followed by an unrelated certificate
  reads `true`; DRep unregister followed by an unrelated certificate reads `true`; only unrelated
  certificates reads `false`; another credential's deregistration reads `false`; deregistration then
  re-registration reads `false` and registration then deregistration reads `true` (stake and DRep).
  Use `txBody(certs: ...)` from `test/test_utils/fixtures.dart` with the existing wallet address
  constants in the `diff` group.
- **Why:** the flags drive the wallet's deregistration warning.
- **Risk and test focus:** low; only the two boolean fields change, from last-certificate-wins to
  last-registration-change-wins.
- **Expected result:** no user-visible change for single-certificate transactions; multi-certificate
  transactions with a wallet deregistration now flag it. No database change.

### Step 4: `diff()` honors `isValidDi == false`, release 3.1.1 (types, ⚙️)

- **Files:** `lib/src/cardano/transaction.dart` (early branch), `test/transaction_test.dart`,
  `pubspec.yaml` version `3.1.1`, `CHANGELOG.md` line under `## 3.1.1`.
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

### Step 5: worker UTxO keys (sdk, 🌿)

- **Files:** `lib/workers/wallet_tasks.dart` (three string keys), `test/prepare_sign_tx_test.dart`,
  `CHANGELOG.md` line under `## 5.1.0` / `### Fix`.
- **Tests:** a batch whose first transaction input carries `TransactionHash(value: ..., cborTags:
  [64])` for a wallet UTxO built with `TransactionHash.fromHex`: the signing address set contains the
  UTxO's address, and a second transaction can no longer see that UTxO in `utxosBeforeTx`. Mirror the
  existing "correctly matches UTXOs by transaction hash" test in `cardano_dart_types`.
- **Why:** missed match means a missing witness and a stale UTxO set for the next transaction.
- **Risk and test focus:** low; key format only. Run the full `prepare_sign_tx_test.dart`.
- **Expected result:** no change for inputs encoded without tags; tagged or indefinite inputs now
  match. No database change. No regenerated worker files (no signature change).

### Step 6: `diff()` refuses transactions marked invalid by default, release 3.1.2 (types, 🌿)

- **Files:** `lib/src/hd/signing/signing_types.dart` (`TxDiManagement` enum with the trust-boundary
  documentation), `lib/src/exceptions/signing_exceptions.dart` (`TransactionMarkedInvalidException`),
  `lib/src/cardano/transaction.dart` (`txDiManagement` parameter and a switch at the top of `diff()`),
  `test/transaction_test.dart`, `pubspec.yaml` version `3.1.2`, `CHANGELOG.md` `## 3.1.2` heading
  recording the retraction of 3.1.1.
- **Tests:** a transaction marked invalid is refused by default and under `safeAlwaysReject`, with
  the body hash in the exception; `dangerouslyAssumeTrue` equals the summary of the same body with the
  flag true; the step 4 collateral-only tests opt into `dangerouslyAssumeOnlyCollateralBurnOnInvalidDi`;
  a valid transaction gives the same summary under every option.
- **Why:** the flag is unsigned; a summary that honours it can be defeated after signing.
- **Risk and test focus:** low; valid path unchanged, three switch branches covered.
- **Expected result:** `diff()` throws for transactions marked invalid unless a dangerous option is
  passed. No database change.
- **Publish:** after merge, a human runs `dart pub publish` for 3.1.2.

### Step 7: bump `cardano_dart_types` to 3.1.2, signing prep refuses transactions marked invalid (sdk, 🌿)

- **Files:** `pubspec.yaml` pin `3.1.2`, `lib/workers/wallet_tasks.dart` (`txDiManagement:
  TxDiManagement.safeAlwaysReject` passed explicitly with a comment), `test/prepare_sign_tx_test.dart`,
  `CHANGELOG.md` lines under `## 5.1.0` (`### Fix` for the refusal, `### Change` for the bump), this
  plan (reworked series).
- **Tests:** batch `[valid tx, tx with isValidDi == false]` is refused through
  `SigningUtils.prepareTxsForSigning` with an error naming the body hash of the flagged transaction;
  the rest of `prepare_sign_tx_test.dart` is unchanged.
- **Why:** picks up steps 3 and 6 and makes the SDK's policy explicit at the call site.
- **Risk and test focus:** low; the whole suite runs against 3.1.2 in CI. Focus on the message
  surviving the worker boundary.
- **Expected result:** batches with only valid transactions unchanged; a batch with a transaction marked
  invalid fails before any summary is produced. Web worker artifacts on `main` are stale from this step
  until step 8; `main` is not published in between. No regenerated worker files.

### Step 8: regenerate web workers, finish 5.1.0 (sdk, 🌱)

- **Commands:** `dart run build_runner build --delete-conflicting-outputs` (expected no-op diff),
  `sh ./scripts/gen_js_workers.sh`.
- **Files:** regenerated `lib/workers/wallet_tasks.web.g.dart.js`, `.mjs`, `.wasm`, loader;
  `CHANGELOG.md` "Web workers built with" line under `## 5.1.0` updated to the toolchain used
  (cardano_dart_types 3.1.2); move this directory to `.plan/completed/signing-prep-fixes/`.
- **Reviewer check:** rerun the two commands on the branch and confirm a clean tree.
- **Why:** web builds embed the worker and `cardano_dart_types` code; nothing above reaches the web
  extension until this step.
- **Risk and test focus:** low in logic, mechanical in size. Run the verification matrix below.
- **Expected result:** web extension behavior matches VM behavior for all three fixes.
- **Publish:** after merge, a human runs `dart pub publish` for 5.1.0.

## Verification

Neither repository has `docs/regression/`; this section is the recorded coverage.

- **Level.** Unit tests through the public boundary: `diff()` in `cardano_dart_types`, and
  `SigningUtils.prepareTxsForSigning` in the SDK, which dispatches to the squadron worker (VM
  isolate under `dart test`). Every delivered behavior is asserted at that boundary.
- **Every step:** `flutter analyze --no-fatal-infos` and `dart test` (what CI runs on pull requests).
- **Matrix (step 8 only, local, CI has these commented out):** `dart test -P js` and
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
  incident; the impact is a wrong balance preview on a security-sensitive screen. Honouring the flag in
  that preview is itself unsafe because the flag is unsigned (Codex security review on SDK PR #10), so
  `diff()` refuses such transactions by default (step 6).

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
- **Refuse, do not summarise, transactions marked invalid; guard in `diff()`, not in the client.**
  Replaces the collateral-chaining design of the former step 7 after the Codex security review on SDK
  PR #10. A client-side check would leave every other consumer exposed, so `diff()` refuses by default
  and the unsafe summaries are explicit `dangerously*` options. 3.1.1 retracted; 3.1.2 ships the guard
  together with the deregistration fix.
- **Collateral exposure in `TxDiff`: deferred.** Codex's second finding on cardano_dart_types #6 is
  real but outside the flag handling: a transaction presented as valid whose scripts fail still exposes
  its collateral, and no flag value can tell it from an honest one without evaluating the scripts.
  Surfacing a collateral figure for every transaction was considered and set aside for now, since
  collateral inputs are UTxO references and `diff()` can value only the wallet-owned ones. The residual
  risk is documented on `TxDiManagement`.
- **Series reworked at step 6.** Steps 1 to 5 kept their numbers and titles; the former SDK step 7 was
  dropped, the `cardano_dart_types` guard became step 6, and the open SDK PR #10 (opened as step 6
  "Bump cardano_dart_types to 3.1.1") was retitled and extended into step 7.
- **No new worker parameters**, so `wallet_tasks.*.g.dart` are untouched and web artifacts are
  regenerated once, in step 8.
- **Versions.** 3.1.0 and 5.0.0 are both already on pub.dev, so the fixes ship as 3.1.2 and 5.1.0
  (3.1.1 published and retracted, see above). No API breaks, so 5.0.0 is not retracted. Bumps land
  first and changelog lines are added per PR (see "Versions and changelog" above).
- **Series grew from 7 to 8 steps** when the version bump moved from the last step to its own early
  PR. Only step 1 had been opened at that point; its merged title still reads `[step 1/7]`.
- **Open CodeRabbit note from PR #3** (eager `drepCredential.hexDecode()`): not applicable, that
  code is not being ported.

**Accepted risks.**

- Between steps 6 and 8, `main` of the SDK has web worker artifacts older than its Dart source. No
  release happens in that window.
- `diff()` under `dangerouslyAssumeOnlyCollateralBurnOnInvalidDi` ignores `totalCollateral`; the actual
  collateral inputs are the authoritative amount and the wallet owns those UTxOs, so the field adds
  nothing.

## Complexity budget

- **New persistent state:** none.
- **New in-memory state:** none. The worker loop keeps its two local lists; `diff()` gains one switch
  at the top.
- **New config, flags, parameters, public types:** in `cardano_dart_types`, the optional `diff()`
  parameter `txDiManagement`, the `TxDiManagement` enum and `TransactionMarkedInvalidException`
  (step 6).
- **Deliberately not added:** a `UtxoId` value type (string keys with hash hex are enough and match
  `diff()`), the ownership model, the batch validator, caller-input snapshots.

## Cleanup

No code on `main` is made obsolete by this plan. The closed PR's remote branch
`deep-review-prepare-txs-for-signing` can be deleted at any time; its content is in Git history.
