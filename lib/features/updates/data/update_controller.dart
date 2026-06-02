import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_repository.dart';

class UpdateControllerState {
  const UpdateControllerState({
    required this.isChecking,
    this.result,
    this.lastError,
  });

  const UpdateControllerState.idle()
      : isChecking = false,
        result = null,
        lastError = null;

  final bool isChecking;
  final UpdateCheckResult? result;
  final String? lastError;

  UpdateControllerState copyWith({
    bool? isChecking,
    UpdateCheckResult? result,
    String? lastError,
    bool clearError = false,
  }) {
    return UpdateControllerState(
      isChecking: isChecking ?? this.isChecking,
      result: result ?? this.result,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

class UpdateController extends StateNotifier<UpdateControllerState> {
  UpdateController(this._repository)
      : super(const UpdateControllerState.idle());

  final UpdateRepository _repository;
  Future<void>? _runningCheck;

  Future<UpdateCheckResult?> checkNow() async {
    if (_runningCheck != null) {
      await _runningCheck;
      return state.result;
    }

    final completer = Completer<void>();
    _runningCheck = completer.future;
    state = state.copyWith(isChecking: true, clearError: true);
    try {
      final result = await _repository.checkForUpdates();
      state = UpdateControllerState(isChecking: false, result: result);
      return result;
    } catch (error) {
      state = UpdateControllerState(
        isChecking: false,
        result: state.result,
        lastError: error.toString(),
      );
      return null;
    } finally {
      completer.complete();
      _runningCheck = null;
    }
  }

  Future<void> checkOnStartup() async {
    final shouldCheck = await _repository.shouldRunAutomaticCheck();
    if (!shouldCheck) {
      return;
    }
    await checkNow();
  }

  Future<void> installLatestUpdate() {
    final result = state.result;
    if (result == null) {
      throw StateError('Результат проверки обновлений недоступен.');
    }

    return _repository.installLatestUpdate(result);
  }
}

final updateControllerProvider =
    StateNotifierProvider<UpdateController, UpdateControllerState>((ref) {
  return UpdateController(ref.watch(updateRepositoryProvider));
});
