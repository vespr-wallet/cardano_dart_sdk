// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: WorkerGenerator 6.2.0
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
