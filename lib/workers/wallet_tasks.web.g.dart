// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// Generator: WorkerGenerator 8.0.0 (Squadron 7.1.2+1)
// Generated: 2025-09-22 09:26:01.127831Z
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
    return Squadron.uri('/assets/packages/cardano_flutter_sdk/workers/wallet_tasks.web.g.loader.js'); // Modified for Manifest V3;
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
