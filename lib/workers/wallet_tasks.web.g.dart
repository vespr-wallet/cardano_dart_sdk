// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: WorkerGenerator 7.1.4 (Squadron 7.1.1)
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'wallet_tasks.dart';

void main() {
  /// Web entry point for WalletTasks
  run($WalletTasksInitializer);
}

EntryPoint $getWalletTasksActivator(SquadronPlatformType platform) {
  if (platform.isJs) {
    return Squadron.uri(
        '/assets/packages/cardano_flutter_sdk/workers/wallet_tasks.web.g.dart.js');
  } else if (platform.isWasm) {
    return Squadron.uri(
        '/assets/packages/cardano_flutter_sdk/workers/wallet_tasks.web.g.dart.wasm');
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
