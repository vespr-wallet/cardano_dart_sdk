// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// Generator: WorkerGenerator 9.0.0+2 (Squadron 7.4.0)
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'wallet_tasks.dart';

void _start$WalletTasks(WorkerRequest command) {
  /// VM entry point for WalletTasks
  run($WalletTasksInitializer, command);
}

EntryPoint $getWalletTasksActivator(SquadronPlatformType platform) {
  if (platform.isVm) {
    return _start$WalletTasks;
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
