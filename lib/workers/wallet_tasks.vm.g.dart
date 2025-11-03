// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// Generator: WorkerGenerator 8.0.0+1 (Squadron 7.2.0)
// Generated: 2025-11-03 18:57:20.424819Z
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
