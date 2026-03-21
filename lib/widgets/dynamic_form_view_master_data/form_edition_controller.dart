import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/form_mode.dart';
import '../../models/lock_status.dart';
import '../../models/lock_result.dart';
import '../../models/save_result.dart';

class FormEditingController extends ChangeNotifier {
  FormMode mode = FormMode.view;
  FormMode originalmode= FormMode.view;
  Timer? _lockRefreshTimer;
  bool hasLock = false;

  String? lockedBy;
  DateTime? lockedAt;
  String? rowVersion;

  bool get isLockedByAnotherUser =>
      lockedBy != null && !hasLock;

  late String entityName;
  late int? recordId;
  late String sessionId;

  late Future<LockResult> Function() acquireLock;
  late Future<void> Function() releaseLock;
  late Future<void> Function() refreshLock;
  late Future<LockStatus> Function() fetchLockStatus;

  // -----------------------------
  // START EDITING
  // -----------------------------
  Future<void> startEditing() async {
    //print("entro a star editing en mixing del form controller");
    final result = await acquireLock();

    if (!result.success) {
      hasLock = false;
      lockedBy = result.lockedBy;
      lockedAt = result.lockedAt;
      notifyListeners();
      return;
    }

    hasLock = true;
    lockedBy = null;
    lockedAt = null;

    mode = FormMode.edit;
    _startRefreshTimer();
    notifyListeners();
  }

  // -----------------------------
  // CANCEL EDITING
  // -----------------------------
  Future<void> cancelEditing() async {
    if (hasLock) {
      await releaseLock();
      hasLock = false;
    }

    _lockRefreshTimer?.cancel();
    mode = FormMode.view;
    notifyListeners();
  }

  // -----------------------------
  // SAVE (UNIFICADO)
  // -----------------------------
  Future<SaveResult> save(Future<SaveResult> Function() saveChanges) async {
    final result = await saveChanges();

    // EDIT MODE
    if (mode == FormMode.edit) {
      if (hasLock) {
        await releaseLock();
        hasLock = false;
      }

      _lockRefreshTimer?.cancel();

      if (!result.conflict) {
        mode = FormMode.view;
      }

      notifyListeners();
      return result;
    }

    // CREATE MODE
    if (mode == FormMode.create) {
      _lockRefreshTimer?.cancel();
      mode = FormMode.view;
      notifyListeners();
      return result;
    }

    return result;
  }

  // -----------------------------
  // REFRESH TIMER
  // -----------------------------
  void _startRefreshTimer() {
    _lockRefreshTimer?.cancel();
    _lockRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => refreshLock(),
    );
  }

  // -----------------------------
  // CHECK EXISTING LOCK
  // -----------------------------
  Future<void> checkExistingLock() async {
    try {
      final status = await fetchLockStatus();

      if (status.locked && status.sessionId != sessionId) {
        lockedBy = status.lockedBy;
        lockedAt = status.lockedAt;
        hasLock = false;
        notifyListeners();
      }
    } catch (_) {}
  }

  void disposeController() {
    _lockRefreshTimer?.cancel();
  }
}