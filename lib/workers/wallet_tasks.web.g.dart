// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// Generator: WorkerGenerator 8.0.0+1 (Squadron 7.2.0)
// Generated: 2025-11-03 16:48:31.542157Z
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
      '/assets/packages/cardano_flutter_sdk/workers/wallet_tasks.web.g.dart.js',
    );
  } else if (platform.isWasm) {
    return Squadron.uri(
      '/assets/packages/cardano_flutter_sdk/workers/wallet_tasks.web.g.loader.js',
    );
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
